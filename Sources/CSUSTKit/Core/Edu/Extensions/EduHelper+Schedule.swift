import Alamofire
import Foundation
import SwiftSoup

extension EduHelper {
    internal enum ScheduleWeekType: String, CaseIterable {
        case single = "单周"
        case double = "双周"
        case all = "周"

        func includes(_ week: Int) -> Bool {
            switch self {
            case .single: return week % 2 != 0
            case .double: return week % 2 == 0
            case .all: return true
            }
        }
    }

    internal func parseScheduleWeeks(_ weekPart: String, type: ScheduleWeekType) throws -> [Int] {
        var weeks: [Int] = []
        for weekSection in weekPart.components(separatedBy: ",") {
            if weekSection.contains("-") {
                let rangeParts = weekSection.components(separatedBy: "-")
                guard rangeParts.count == 2, let startWeek = Int(rangeParts[0].trim()),
                    let endWeek = Int(rangeParts[1].trim())
                else {
                    throw EduHelperError.courseScheduleRetrievalFailed("周范围格式无效: \(weekSection)")
                }
                if startWeek > endWeek {
                    throw EduHelperError.courseScheduleRetrievalFailed("起始周 \(startWeek) 大于结束周 \(endWeek)")
                }
                weeks.append(contentsOf: (startWeek...endWeek).filter(type.includes))
            } else {
                if let week = Int(weekSection) {
                    weeks.append(week)
                } else {
                    throw EduHelperError.courseScheduleRetrievalFailed("周格式无效: \(weekSection)")
                }
            }
        }
        return weeks
    }

    private func parseDate(date: String) throws -> ([Int], [Int]) {
        guard let weekType = ScheduleWeekType.allCases.first(where: { date.contains("(\($0.rawValue))") }) else {
            throw EduHelperError.courseScheduleRetrievalFailed("日期中周类型无效: \(date)")
        }
        let parts = date.components(separatedBy: "(\(weekType.rawValue))")
        guard parts.count == 2 else {
            throw EduHelperError.courseScheduleRetrievalFailed("日期格式无效: \(date)")
        }
        let weeks = try parseScheduleWeeks(parts[0], type: weekType)
        let sectionPart = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "[]节"))
        var sections: [Int] = []
        for section in sectionPart.components(separatedBy: "-") {
            guard let sectionNumber = Int(section) else {
                throw EduHelperError.courseScheduleRetrievalFailed("节次格式无效: \(section)")
            }
            sections.append(sectionNumber)
        }
        return (weeks, sections)
    }

    private struct ParsedItem {
        let courseName: String
        let groupName: String?
        let teacherName: String?
        let weeks: [Int]
        let startSection: Int
        let endSection: Int
        let classroom: String?
    }

    private func parseCourse(element: Element) throws -> [ParsedItem] {
        guard !(try element.text().trim().isEmpty) else {
            return []
        }
        guard let contentElement = try element.select("div.kbcontent").first() else {
            throw EduHelperError.courseScheduleRetrievalFailed("未找到课程内容元素")
        }
        var courseSchedules: [ParsedItem] = []
        let courseHTMLs = try contentElement.html().components(separatedBy: "---------------------")
        for courseHTML in courseHTMLs {
            let trimmedHTML = courseHTML.trim()
            guard !trimmedHTML.isEmpty else { continue }
            let courseFragment = try SwiftSoup.parseBodyFragment(trimmedHTML)
            guard let courseBody = try courseFragment.select("body").first() else {
                throw EduHelperError.courseScheduleRetrievalFailed("未找到课程主体")
            }
            guard let courseName = courseBody.textNodes().first?.text().trim() else {
                throw EduHelperError.courseScheduleRetrievalFailed("未找到课程名称")
            }
            var groupName: String? = nil
            if courseBody.textNodes().count > 1 && !courseBody.textNodes()[1].text().trim().isEmpty {
                groupName = courseBody.textNodes()[1].text().trim()
            }
            let teacherName = try courseBody.select("font[title='老师']").first()?.text()
            let classroom = try courseBody.select("font[title='教室']").first()?.text()
            guard let dateText = try courseBody.select("font[title='周次(节次)']").first()?.text() else {
                throw EduHelperError.courseScheduleRetrievalFailed("未找到日期文本")
            }
            let (weeks, sections) = try parseDate(date: dateText)
            guard !weeks.isEmpty, !sections.isEmpty else {
                throw EduHelperError.courseScheduleRetrievalFailed("周或节次无效")
            }
            guard let startSession = sections.first, let endSession = sections.last
            else {
                throw EduHelperError.courseScheduleRetrievalFailed("节次范围无效")
            }
            courseSchedules.append(
                ParsedItem(
                    courseName: courseName,
                    groupName: groupName,
                    teacherName: teacherName,
                    weeks: weeks,
                    startSection: startSession,
                    endSection: endSession,
                    classroom: classroom
                )
            )
        }
        return courseSchedules
    }

    /// 获取课程表
    /// - Parameter academicYearSemester: 学年学期，格式为 "2023-2024-1"，如果为 `nil` 则查询默认学期
    /// - Throws: `EduHelperError`
    /// - Returns: 课程信息数组和备注数组的元组
    public func getCourseSchedule(academicYearSemester: String? = nil) async throws -> ([Course], [String]) {
        let queryParams: [String: String] = ["xnxq01id": academicYearSemester ?? ""]
        let response = try await performRequest(factory.make(.education, "/jsxsd/xskb/xskb_list.do"), .post, queryParams)
        let document = try SwiftSoup.parse(response)
        guard let table = try document.select("#kbtable").first() else {
            throw EduHelperError.courseScheduleRetrievalFailed("未找到课程表")
        }
        var courseDictionary: [String: Course] = [:]
        var remarks: [String] = []
        let rows = try table.select("tr")

        if let lastRow = rows.last() {
            let thText = try? lastRow.select("th").first()?.text().trim()
            if thText?.contains("备注") == true {
                if let tdText = try? lastRow.select("td").first()?.text().trim() {
                    remarks = tdText.components(separatedBy: ";")
                        .map { $0.trim() }
                        .filter { !$0.isEmpty }
                }
            }
        }

        for (rowIndex, row) in rows.enumerated() {
            guard rowIndex > 0 else { continue }
            guard rowIndex < rows.count - 1 else { continue }
            let cols = try row.select("td")
            for (colIndex, col) in cols.enumerated() {
                guard let day = DayOfWeek(rawValue: colIndex) else {
                    throw EduHelperError.courseScheduleRetrievalFailed("星期索引无效: \(colIndex)")
                }
                let parsedItems = try parseCourse(element: col)
                for item in parsedItems {
                    let newSession = ScheduleSession(
                        weeks: item.weeks,
                        startSection: item.startSection,
                        endSection: item.endSection,
                        dayOfWeek: day,
                        classroom: item.classroom
                    )
                    if var existingCourse = courseDictionary[item.courseName] {
                        if !existingCourse.sessions.contains(newSession) {
                            existingCourse.sessions.append(newSession)
                        }
                        courseDictionary[item.courseName] = existingCourse
                    } else {
                        let newCourse = Course(
                            courseName: item.courseName,
                            groupName: item.groupName,
                            teacher: item.teacherName,
                            sessions: [newSession]
                        )
                        courseDictionary[item.courseName] = newCourse
                    }
                }
            }
        }
        return (Array(courseDictionary.values), remarks)
    }

    /// 获取课程表的所有可用学期
    /// - Throws: `EduHelperError`
    /// - Returns: 包含所有可用学期的数组和默认学期
    public func getAvailableSemestersForCourseSchedule() async throws -> ([String], String) {
        let response = try await performRequest(factory.make(.education, "/jsxsd/xskb/xskb_list.do"))
        let document = try SwiftSoup.parse(response)
        guard let semesterSelect = try document.select("#xnxq01id").first() else {
            throw EduHelperError.availableSemestersForCourseScheduleRetrievalFailed("未找到学期选择元素")
        }
        let options = try semesterSelect.select("option")
        var semesters: [String] = []
        var defaultSemester: String?
        for option in options {
            let name = try option.text().trim()
            if option.hasAttr("selected") {
                defaultSemester = name
            }
            semesters.append(name)
        }
        guard !semesters.isEmpty else {
            throw EduHelperError.availableSemestersForCourseScheduleRetrievalFailed("学期选择元素中未找到学期")
        }
        guard let defaultSemester = defaultSemester else {
            throw EduHelperError.availableSemestersForCourseScheduleRetrievalFailed("未找到默认学期")
        }
        return (semesters, defaultSemester)
    }
}
