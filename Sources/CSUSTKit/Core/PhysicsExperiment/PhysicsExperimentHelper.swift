import Alamofire
import Foundation
import SwiftSoup

/// 物理实验教学管理助手
public class PhysicsExperimentHelper: BaseHelper {

    // MARK: - Methods

    internal override var notLoggedInError: (any Error)? { PhysicsExperimentHelperError.notLoggedIn }

    internal override func isSubsystemLoginResponse(_ body: String, finalURL: URL) -> Bool {
        body.contains("name=\"txtUserName\"")
    }

    public override func isLoggedIn() async -> Bool {
        return (try? await getCourses()) != nil
    }

    /// 登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    /// - Throws: `PhysicsExperimentHelperError`
    public func login(username: String, password: String) async throws {
        let usernameEncoded = username.base64String
        let passwordEncoded = password.base64String
        let urlString = factory.make(.physicsExperiment, "/login.aspx?UserType=0&txtUserName=\(usernameEncoded)&txtPass=\(passwordEncoded)")

        let response = try await performRequest(urlString, .post, validateLogin: false)

        guard response.contains("true") else {
            throw PhysicsExperimentHelperError.loginFailed(response)
        }
    }

    /// 获取物理实验课程表
    /// - Throws: `PhysicsExperimentHelperError`
    /// - Returns: 课程列表
    public func getCourses() async throws -> [Course] {
        let response = try await performRequest(factory.make(.physicsExperiment, "/Student/myalltasklist.aspx?generalCourseId=2&generalCourseName=%E5%A4%A7%E5%AD%A6%E7%89%A9%E7%90%86%E5%AE%9E%E9%AA%8C"))

        let document = try SwiftSoup.parse(response)
        guard let table = try document.getElementsByClass("msgtable").first() else {
            throw PhysicsExperimentHelperError.schedulesRetrievalFailed("未找到课程表")
        }

        let rows = try table.getElementsByTag("tr")
        guard rows.count >= 1 else {
            throw PhysicsExperimentHelperError.schedulesRetrievalFailed("课程表格式无效")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        var courses: [Course] = []
        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }

            let cols = try row.getElementsByTag("td")
            guard cols.count >= 8 else {
                throw PhysicsExperimentHelperError.schedulesRetrievalFailed("课表列数不足")
            }

            guard let id = Int(try cols[0].text()) else {
                throw PhysicsExperimentHelperError.schedulesRetrievalFailed("课程ID格式无效")
            }
            let name = try cols[1].text().trim()
            let batch = try cols[2].text().trim()
            let teacher = try cols[3].text().trim()
            let location = try cols[4].text().trim()
            let timeString = try cols[5].text().trim()
            guard let classHours = Int(try cols[6].text().trim()) else {
                throw PhysicsExperimentHelperError.schedulesRetrievalFailed("课时格式无效")
            }
            let weekInfoString = try cols[7].text().trim()

            let (startTime, endTime) = try parseTime(timeString, with: dateFormatter)
            let (week, dayOfWeek) = try parseWeekInfo(weekInfoString)

            let course = Course(
                id: id,
                name: name,
                batch: batch,
                teacher: teacher,
                location: location,
                startTime: startTime,
                endTime: endTime,
                classHours: classHours,
                week: week,
                dayOfWeek: dayOfWeek
            )
            courses.append(course)
        }

        return courses
    }

    /// 解析时间字符串 (例如 "2025-12-02 07:45 - 10:00")
    private func parseTime(_ timeString: String, with formatter: DateFormatter) throws -> (startTime: Date, endTime: Date) {
        let components = timeString.components(separatedBy: " - ")
        guard components.count == 2,
            let dateTimePart = components.first,
            let endTimePart = components.last
        else {
            throw PhysicsExperimentHelperError.schedulesRetrievalFailed("时间格式无效: \(timeString)")
        }

        guard let datePart = dateTimePart.components(separatedBy: " ").first else {
            throw PhysicsExperimentHelperError.schedulesRetrievalFailed("无法从时间中提取日期部分: \(timeString)")
        }

        let fullStartString = dateTimePart
        let fullEndString = "\(datePart) \(endTimePart)"

        guard let startTime = formatter.date(from: fullStartString),
            let endTime = formatter.date(from: fullEndString)
        else {
            throw PhysicsExperimentHelperError.schedulesRetrievalFailed("日期字符串转换失败: \(timeString)")
        }

        return (startTime, endTime)
    }

    /// 解析周次和星期信息 (例如 "第13周 星期二")
    private func parseWeekInfo(_ weekInfoString: String) throws -> (week: Int, dayOfWeek: DayOfWeek) {
        let components = weekInfoString.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard components.count == 2,
            let weekPart = components.first,
            let dayPart = components.last
        else {
            throw PhysicsExperimentHelperError.schedulesRetrievalFailed("周信息格式无效: \(weekInfoString)")
        }

        // 解析周数
        let weekString = weekPart.replacingOccurrences(of: "第", with: "").replacingOccurrences(of: "周", with: "")
        guard let week = Int(weekString) else {
            throw PhysicsExperimentHelperError.schedulesRetrievalFailed("无法解析周次: \(weekPart)")
        }

        // 解析星期
        let dayOfWeek: DayOfWeek
        switch dayPart {
        case "星期一": dayOfWeek = .monday
        case "星期二": dayOfWeek = .tuesday
        case "星期三": dayOfWeek = .wednesday
        case "星期四": dayOfWeek = .thursday
        case "星期五": dayOfWeek = .friday
        case "星期六": dayOfWeek = .saturday
        case "星期日": dayOfWeek = .sunday
        default:
            throw PhysicsExperimentHelperError.schedulesRetrievalFailed("无法解析星期: \(dayPart)")
        }

        return (week, dayOfWeek)
    }

    /// 获取物理实验课程成绩
    /// - Throws: `PhysicsExperimentHelperError`
    /// - Returns: 课程成绩列表
    public func getCourseGrades() async throws -> [CourseGrade] {
        let response = try await performRequest(factory.make(.physicsExperiment, "/Student/GeneralCourseScore.aspx"))

        let document = try SwiftSoup.parse(response)
        guard let table = try document.getElementById("gvList") else {
            throw PhysicsExperimentHelperError.courseGradesRetrievalFailed("未找到成绩表格")
        }

        let rows = try table.getElementsByTag("tr")
        guard rows.count >= 1 else {
            throw PhysicsExperimentHelperError.courseGradesRetrievalFailed("成绩表格格式无效")
        }

        var courseGrades: [CourseGrade] = []
        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }

            let cols = try row.getElementsByTag("td")
            guard cols.count >= 7 else {
                throw PhysicsExperimentHelperError.courseGradesRetrievalFailed("成绩表格列数不足")
            }

            let courseCode = try cols[0].text().trim()
            let courseName = try cols[1].text().trim()
            let itemName = try cols[2].text().trim()
            let previewGrade = Int(try cols[3].text().trim())
            let operationGrade = Int(try cols[4].text().trim())
            let reportGrade = Int(try cols[5].text().trim())
            guard let totalGrade = Int(try cols[6].text().trim()) else {
                throw PhysicsExperimentHelperError.courseGradesRetrievalFailed("总成绩格式无效")
            }

            let grade = CourseGrade(
                courseCode: courseCode,
                courseName: courseName,
                itemName: itemName,
                previewGrade: previewGrade,
                operationGrade: operationGrade,
                reportGrade: reportGrade,
                totalGrade: totalGrade
            )
            courseGrades.append(grade)
        }

        return courseGrades
    }

    /// 登出当前账号
    public func logout() async throws {
        try await performDataRequest(factory.make(.physicsExperiment, "/logout.aspx"), validateLogin: false)
    }
}
