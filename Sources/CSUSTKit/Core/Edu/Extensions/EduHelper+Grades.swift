import Alamofire
import Foundation
import SwiftSoup

extension EduHelper {
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
            let gradeDetailURL = try cols[5].select("a").first()?.attr("href").trim()
            guard var gradeDetailURL = gradeDetailURL else {
                throw EduHelperError.courseGradesRetrievalFailed("未找到成绩详情URL")
            }

            gradeDetailURL =
                gradeDetailURL
                .replacingOccurrences(of: "javascript:openWindow('/", with: factory.make(.education, "/"))
                .replacingOccurrences(of: "',700,500)", with: "")

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
                gradeDetailURL: gradeDetailURL,
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
}
