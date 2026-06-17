import Alamofire
import Foundation
import SwiftSoup

extension EduHelper {
    /// 课程服务
    public class CourseService: BaseService {
        /// 获取课程成绩
        /// - Parameters:
        ///   - academicYearSemester: 学年学期，格式为 "2023-2024-1"，如果为 `nil` 则为全部学期
        ///   - courseNature: 课程性质，如果为 `nil` 则查询所有性质的课程
        ///   - courseName: 课程名称，默认为空字符串表示查询所有课程
        ///   - displayMode: 显示模式，默认为显示最好成绩
        ///   - studyMode: 修读方式，默认为主修
        /// - Throws: `EduHelperError`
        /// - Returns: 课程成绩信息数组
        public func getCourseGrades(academicYearSemester: String? = nil, courseNature: CourseNature? = nil, courseName: String = "", displayMode: DisplayMode = .bestGrade, studyMode: StudyMode = .major) async throws -> [CourseGrade] {
            let queryParams = [
                "kksj": academicYearSemester ?? "",
                "kcxz": courseNature?.id ?? "",
                "kcmc": courseName,
                "xsfs": displayMode.id,
                "fxkc": studyMode.id,
            ]
            let response = try await performRequest(factory.make(.education, "/jsxsd/kscj/cjcx_list"), .post, queryParams)
            let document = try SwiftSoup.parse(response)
            guard let table = try document.select("#dataList").first() else {
                throw EduHelperError.courseGradesRetrievalFailed("未找到课程成绩表格")
            }
            guard !(try table.html().contains("未查询到数据")) else {
                throw EduHelperError.courseGradesRetrievalFailed("未查询到数据")
            }
            let rows = try table.select("tr")
            var courseGrades: [CourseGrade] = []
            for (index, row) in rows.enumerated() {
                guard index > 0 else { continue }
                let cols = try row.select("td")
                guard cols.count >= 17 else {
                    throw EduHelperError.courseGradesRetrievalFailed("行列数不足: \(cols.count)")
                }
                let semester = try cols[1].text().trim()
                let courseID = try cols[2].text().trim()
                let courseName = try cols[3].text().trim()
                let groupName = try cols[4].text().trim()
                let gradeString = try cols[5].text().trim()
                guard let grade = Int(gradeString) else {
                    throw EduHelperError.courseGradesRetrievalFailed("成绩格式无效: \(gradeString)")
                }
                let gradeDetailUrl = try cols[5].select("a").first()?.attr("href").trim()
                guard var gradeDetailUrl = gradeDetailUrl else {
                    throw EduHelperError.courseGradesRetrievalFailed("未找到成绩详情URL")
                }

                if mode == .webVpn {
                    gradeDetailUrl =
                        gradeDetailUrl
                        .replacingOccurrences(of: "javascript:this.top.vpn_inject_scripts_window(this);vpn_eval((function () { openWindow(\'/", with: factory.make(.education, "/"))
                        .replacingOccurrences(of: "\',700,500) }).toString().slice(14, -2))", with: "")
                } else {
                    gradeDetailUrl =
                        gradeDetailUrl
                        .replacingOccurrences(of: "javascript:openWindow('", with: "http://xk.csust.edu.cn")
                        .replacingOccurrences(of: "',700,500)", with: "")
                }

                let studyMode = try cols[6].text().trim()
                let gradeIdentifier = try cols[7].text().trim()
                let creditString = try cols[8].text().trim()
                guard let credit = Double(creditString) else {
                    throw EduHelperError.courseGradesRetrievalFailed("学分格式无效: \(creditString)")
                }
                let totalHoursString = try cols[9].text().trim()
                guard let totalHours = Double(totalHoursString) else {
                    throw EduHelperError.courseGradesRetrievalFailed("总学时格式无效: \(totalHoursString)")
                }
                let gradePointString = try cols[10].text().trim()
                guard let gradePoint = Double(gradePointString) else {
                    throw EduHelperError.courseGradesRetrievalFailed("绩点格式无效: \(gradePointString)")
                }
                let retakeSemester = try cols[11].text().trim()
                let assessmentMethod = try cols[12].text().trim()
                let examNature = try cols[13].text().trim()
                let courseAttribute = try cols[14].text().trim()
                let courseNatureString = try cols[15].text().trim()
                guard let courseNature = CourseNature(rawValue: courseNatureString) else {
                    throw EduHelperError.courseGradesRetrievalFailed("课程性质无效: \(courseNatureString)")
                }
                let courseCategory = try cols[16].text().trim()
                let courseGrade = CourseGrade(
                    semester: semester,
                    courseID: courseID,
                    courseName: courseName,
                    groupName: groupName,
                    grade: grade,
                    gradeDetailUrl: gradeDetailUrl,
                    studyMode: studyMode,
                    gradeIdentifier: gradeIdentifier,
                    credit: credit,
                    totalHours: totalHours,
                    gradePoint: gradePoint,
                    retakeSemester: retakeSemester,
                    assessmentMethod: assessmentMethod,
                    examNature: examNature,
                    courseAttribute: courseAttribute,
                    courseNature: courseNature,
                    courseCategory: courseCategory
                )
                courseGrades.append(courseGrade)
            }
            return courseGrades
        }

        /// 获取课程成绩的所有可用学期
        /// - Throws: `EduHelperError`
        /// - Returns: 包含所有可用学期的数组
        public func getAvailableSemestersForCourseGrades() async throws -> [String] {
            let response = try await performRequest(factory.make(.education, "/jsxsd/kscj/cjcx_query"))
            let document = try SwiftSoup.parse(response)
            guard let semesterSelect = try document.select("#kksj").first() else {
                throw EduHelperError.availableSemestersForCourseGradesRetrievalFailed("未找到学期选择元素")
            }
            let options = try semesterSelect.select("option")
            var semesters: [String] = []
            for option in options {
                let name = try option.text().trim()
                if name.contains("全部学期") {
                    continue
                }
                semesters.append(name)
            }
            return semesters
        }

        /// 获取成绩详情
        /// - Parameter url: 课程详细URL
        /// - Throws: `EduHelperError`
        /// - Returns: 成绩详情
        public func getGradeDetail(url: String) async throws -> GradeDetail {
            let response = try await performRequest(url)
            let document = try SwiftSoup.parse(response)
            guard let table = try document.select("#dataList").first() else {
                throw EduHelperError.gradeDetailRetrievalFailed("未找到成绩详情表格")
            }
            let rows = try table.select("tr")
            guard rows.count >= 2 else {
                throw EduHelperError.gradeDetailRetrievalFailed("成绩详情表行数不足")
            }
            let headerRow = rows[0]
            let headerCols = try headerRow.select("th")
            let valueRow = rows[1]
            let valueCols = try valueRow.select("td")
            guard headerCols.count >= 4, valueCols.count >= 4 else {
                throw EduHelperError.gradeDetailRetrievalFailed("成绩详情表列数不足: \(headerCols.count), \(valueCols.count)")
            }
            var components: [GradeComponent] = []
            for i in stride(from: 1, to: headerCols.count - 1, by: 2) {
                let type = try headerCols[i].text().trim()
                let grade = try valueCols[i].text().trim()
                let ratioString = try valueCols[i + 1].text().trim().replacingOccurrences(of: "%", with: "")
                guard let ratio = Int(ratioString) else {
                    throw EduHelperError.gradeDetailRetrievalFailed("比例格式无效: \(ratioString)")
                }
                guard let gradeValue = Double(grade) else {
                    throw EduHelperError.gradeDetailRetrievalFailed("成绩格式无效: \(grade)")
                }
                let component = GradeComponent(type: type, grade: gradeValue, ratio: ratio)
                components.append(component)
            }
            let totalGrade = try valueCols.last()?.text().trim()
            guard let totalGradeString = totalGrade, let totalGradeValue = Int(totalGradeString) else {
                throw EduHelperError.gradeDetailRetrievalFailed("总成绩格式无效: \(String(describing: totalGrade))")
            }
            return GradeDetail(components: components, totalGrade: totalGradeValue)
        }

        private func parseDate(date: String) throws -> ([Int], [Int]) {
            enum WeekType: String, CaseIterable {
                case single = "(单周)"
                case double = "(双周)"
                case all = "(周)"
            }
            var weekType: WeekType? = nil
            for type in WeekType.allCases {
                if date.contains(type.rawValue) {
                    weekType = type
                    break
                }
            }
            guard let weekType = weekType else {
                throw EduHelperError.courseScheduleRetrievalFailed("日期中周类型无效: \(date)")
            }
            let parts = date.components(separatedBy: weekType.rawValue)
            guard parts.count == 2 else {
                throw EduHelperError.courseScheduleRetrievalFailed("日期格式无效: \(date)")
            }
            let weekPart = parts[0]
            let sectionPart = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "[]节"))
            var weeks: [Int] = []
            var sections: [Int] = []
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
                    switch weekType {
                    case .single:
                        weeks.append(contentsOf: (startWeek...endWeek).filter { $0 % 2 != 0 })
                    case .double:
                        weeks.append(contentsOf: (startWeek...endWeek).filter { $0 % 2 == 0 })
                    case .all:
                        weeks.append(contentsOf: startWeek...endWeek)
                    }
                } else {
                    if let week = Int(weekSection) {
                        weeks.append(week)
                    } else {
                        throw EduHelperError.courseScheduleRetrievalFailed("周格式无效: \(weekSection)")
                    }
                }
            }
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
        /// - Returns: 课程信息数组
        public func getCourseSchedule(academicYearSemester: String? = nil) async throws -> [Course] {
            let queryParams: [String: String] = ["xnxq01id": academicYearSemester ?? ""]
            let response = try await performRequest(factory.make(.education, "/jsxsd/xskb/xskb_list.do"), .post, queryParams)
            let document = try SwiftSoup.parse(response)
            guard let table = try document.select("#kbtable").first() else {
                throw EduHelperError.courseScheduleRetrievalFailed("未找到课程表")
            }
            var courseDictionary: [String: Course] = [:]
            let rows = try table.select("tr")
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
            return Array(courseDictionary.values)
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

        /// 获取指定校区在指定时间内空闲的教室列表
        /// - Parameters:
        ///   - campus: 校区
        ///   - week: 周数
        ///   - dayOfWeek: 星期
        ///   - section: 节次（大节，范围：1-5）
        /// - Throws: `EduHelperError`
        /// - Returns: 空闲教室列表
        public func getAvailableClassrooms(campus: CampusCardHelper.Campus, week: Int, dayOfWeek: DayOfWeek, section: Int) async throws -> [String] {
            let sectionMapper = [1: ("01", "02"), 2: ("03", "04"), 3: ("05", "06"), 4: ("07", "08"), 5: ("09", "10")]
            guard section >= 1 && section <= 5,
                let (startSection, endSection) = sectionMapper[section]
            else {
                throw EduHelperError.availableClassroomsRetrievalFailed("节次范围错误：1-5")
            }
            let dayOfWeekValue = dayOfWeek == .sunday ? 7 : dayOfWeek.rawValue
            let queryParams = [
                // 学年学期，不填写则教务系统默认
                // "xnxqh": "2025-2026-1",
                // 课表时间模式，不填写则教务系统默认
                // "kbjcmsid": "94673FF3230E4769E0533C41FF0A2703",
                // 上课院系
                "skyx": "",
                // 校区ID
                "xqid": campus == .yuntang ? "1" : "2",
                // 教学楼
                "jzwid": "",
                // 功能区
                "gnq": "",
                "skjsid": "",
                "skjs": "",
                "zc1": "\(week)",
                "zc2": "\(week)",
                "skxq1": "\(dayOfWeekValue)",
                "skxq2": "\(dayOfWeekValue)",
                "jc1": "\(startSection)",
                "jc2": "\(endSection)",
            ]
            let response = try await performRequest(factory.make(.education, "/jsxsd/kbcx/kbxx_classroom_ifr"), .post, queryParams)
            let document = try SwiftSoup.parse(response)
            guard let table = try document.select("#kbtable").first() else {
                throw EduHelperError.courseScheduleRetrievalFailed("未找到课程表")
            }
            let trList = try table.select("#kbtable > tbody > tr")
            var availableClassrooms: [String] = []

            for tr in trList {
                let tds = try tr.select("td")
                guard let firstTd = tds.first() else {
                    continue
                }
                let classroom = try firstTd.text().trim()
                var isOccupied = false
                for slotTd in tds.dropFirst() {
                    let hasCourseDiv = try !slotTd.select("div.kbcontent1").isEmpty()
                    let content = try slotTd.text().trim()
                    if hasCourseDiv || !content.isEmpty {
                        isOccupied = true
                        break
                    }
                }
                if !isOccupied {
                    availableClassrooms.append(classroom)
                }
            }
            return availableClassrooms
        }
    }
}
