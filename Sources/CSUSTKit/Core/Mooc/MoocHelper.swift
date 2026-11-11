import Alamofire
import Foundation
import SwiftSoup

/// 网络课程中心助手
public class MoocHelper: BaseHelper {

    // MARK: - Models

    private struct AssignmentsResponse: Codable {
        struct Datas: Codable {
            let hwtList: [Assignment]?
            struct Assignment: Codable {
                let realName: String
                let startDateTime: String
                let mutualTask: String
                let submitStruts: Bool
                let id: Int
                let title: String
                let deadLine: String
                let answerStatus: Bool?
            }
        }
        let datas: Datas
    }

    // MARK: - Methods

    public override func isLoggedIn() async -> Bool {
        return (try? await getProfile()) != nil
    }

    internal override var notLoggedInError: (any Error)? { MoocHelperError.notLoggedIn }

    internal override func isSubsystemLoginResponse(_ body: String, finalURL: URL) -> Bool {
        body.contains("<TITLE>错误！</TITLE>") || body.contains("请登录！")
    }

    /// 获取个人信息
    /// - Throws: `MoocHelperError`
    /// - Returns: 个人信息
    public func getProfile() async throws -> Profile {
        let response = try await performRequest(factory.make(.mooc, "/meol/personal.do"), stringEncoding: .gbk)
        let document = try SwiftSoup.parse(response)
        let elements = try document.select(".userinfobody > ul > li")
        guard elements.count >= 5 else {
            throw MoocHelperError.profileRetrievalFailed("个人信息格式异常")
        }
        let name = try elements[1].text()
        let lastLoginTime = try elements[2].text().replacingOccurrences(of: "登录时间：", with: "")
        let totalOnlineTime = try elements[3].text().replacingOccurrences(of: "在线总时长： ", with: "")
        let loginCountText = try elements[4].text().replacingOccurrences(of: "登录次数：", with: "")
        guard let loginCount = Int(loginCountText) else {
            throw MoocHelperError.profileRetrievalFailed("登录次数格式无效")
        }
        return Profile(
            name: name,
            lastLoginTime: lastLoginTime,
            totalOnlineTime: totalOnlineTime,
            loginCount: loginCount
        )
    }

    /// 获取课程列表
    /// - Throws: `MoocHelperError`
    /// - Returns: 课程列表
    public func getCourses() async throws -> [Course] {
        let response = try await performRequest(factory.make(.mooc, "/meol/lesson/blen.student.lesson.list.jsp"), stringEncoding: .gbk)
        let document = try SwiftSoup.parse(response)
        guard let tableElement = try document.getElementById("table2") else {
            throw MoocHelperError.courseRetrievalFailed("未找到课程表格")
        }
        let rows = try tableElement.select("tr")
        guard rows.count >= 1 else {
            throw MoocHelperError.courseRetrievalFailed("课程表格格式无效")
        }
        var courses: [Course] = []
        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }
            let cols = try row.select("td")
            guard cols.count >= 4 else {
                throw MoocHelperError.courseRetrievalFailed("课程行格式异常")
            }
            let number = try cols[0].text()
            let name = try cols[1].text()
            guard let a = try cols[1].getElementsByTag("a").first() else {
                throw MoocHelperError.courseRetrievalFailed("未找到课程ID")
            }
            var id = (try a.attr("onclick"))
                .replacingOccurrences(of: "window.open('../homepage/course/course_index.jsp?courseId=", with: "")
                .replacingOccurrences(of: "','manage_course')", with: "")

            if mode == .webVPN {
                id = id.replacingOccurrences(of: "var vpn_return;eval(vpn_rewrite_js((function () { ", with: "")
                    .replacingOccurrences(of: " }).toString().slice(14, -2), 2));return vpn_return;", with: "")
            }

            let department = try cols[2].text()
            let teacher = try cols[3].text()
            let course = Course(
                id: id,
                name: name,
                number: number,
                department: department,
                teacher: teacher
            )
            courses.append(course)
        }
        return courses
    }

    /// 获取课程作业列表
    /// - Parameter course: 课程
    /// - Throws: `MoocHelperError`
    /// - Returns: 课程作业列表
    public func getCourseAssignments(course: Course) async throws -> [Assignment] {
        let responseString = try await performRequest(factory.make(.mooc, "/meol/hw/stu/hwStuHwtList.do?sortDirection=-1&courseId=\(course.id)&pagingPage=1&pagingNumberPer=1000&sortColumn=deadline"))
        guard let responseData = responseString.data(using: .utf8) else {
            throw MoocHelperError.assignmentsRetrievalFailed("作业信息格式无效")
        }
        let response = try JSONDecoder().decode(AssignmentsResponse.self, from: responseData)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        return response.datas.hwtList?.compactMap {
            guard let deadline = dateFormatter.date(from: $0.deadLine),
                let startTime = dateFormatter.date(from: $0.startDateTime)
            else {
                return nil
            }
            return Assignment(
                id: $0.id,
                title: $0.title,
                publisher: $0.realName,
                canSubmit: $0.submitStruts,
                submitStatus: $0.answerStatus != nil,
                deadline: deadline,
                startTime: startTime
            )
        } ?? []
    }

    /// 获取课程测验列表
    /// - Parameter course: 课程
    /// - Throws: `MoocHelperError`
    /// - Returns: 课程测验列表
    public func getCourseExams(course: Course) async throws -> [Exam] {
        let response = try await performRequest(factory.make(.mooc, "/meol/common/question/test/student/list.jsp?sortColumn=createTime&sortDirection=-1&cateId=\(course.id)&pagingPage=1&status=1&pagingNumberPer=1000"), stringEncoding: .gbk)
        let document = try SwiftSoup.parse(response)
        guard let tableElement = try document.getElementsByClass("valuelist").first() else {
            throw MoocHelperError.testRetrievalFailed("未找到测试表格")
        }
        let rows = try tableElement.getElementsByTag("tr")
        guard rows.count >= 1 else {
            throw MoocHelperError.testRetrievalFailed("测试表格格式无效")
        }
        var exams: [Exam] = []
        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }
            let cols = try row.getElementsByTag("td")
            guard cols.count >= 8 else {
                throw MoocHelperError.testRetrievalFailed("测试表格行格式异常")
            }
            let title = try cols[0].text()
            let startTime = try cols[1].text()
            let endTime = try cols[2].text()
            let rawAllowRetake = try cols[3].text()
            let allowRetake = rawAllowRetake == "不限制" ? nil : Int(rawAllowRetake)
            guard let timeLimit = Int(try cols[4].text()) else {
                throw MoocHelperError.testRetrievalFailed("时间限制格式无效")
            }
            let isSubmitted = try cols[7].html().contains("查看结果")
            exams.append(
                Exam(
                    title: title,
                    startTime: startTime,
                    endTime: endTime,
                    allowRetake: allowRetake,
                    timeLimit: timeLimit,
                    isSubmitted: isSubmitted
                )
            )
        }
        return exams
    }

    /// 获取有待完成作业的课程
    /// - Throws: `MoocHelperError`
    /// - Returns: 课程列表
    public func getCoursesWithPendingAssignments() async throws -> [Course] {
        let response = try await performRequest(factory.make(.mooc, "/meol/welcomepage/student/interaction_reminder_v8.jsp"), stringEncoding: .gbk)
        let document = try SwiftSoup.parse(response)
        guard let reminderElement = try document.getElementById("reminder") else {
            throw MoocHelperError.courseNamesWithPendingAssignmentsRetrievalFailed("未找到提醒区域")
        }
        let assignmentsElement = reminderElement.children()
            .first(where: { (element: Element) -> Bool in
                guard let linkText = try? element.select("a").first()?.ownText() else {
                    return false
                }
                return linkText.contains("待提交作业")
            })

        guard let courseNamesContainer = assignmentsElement else {
            return []
        }

        let courseNameElements = try courseNamesContainer.select("ul > li > a")
        if courseNameElements.isEmpty() {
            return []
        }

        var courses: [Course] = []
        for courseNameElement in courseNameElements {
            let onclickAttr = try courseNameElement.attr("onclick")
            let regex = try NSRegularExpression(pattern: "lid=(\\d+)")
            guard let match = regex.firstMatch(in: onclickAttr, range: NSRange(onclickAttr.startIndex..., in: onclickAttr)),
                let range = Range(match.range(at: 1), in: onclickAttr)
            else {
                continue
            }
            let id = String(onclickAttr[range])
            let courseName = try courseNameElement.text().trim()
            courses.append(Course(id: id, name: courseName, number: nil, department: nil, teacher: nil))
        }
        return courses
    }

    /// 登出
    public func logout() async throws {
        try await performDataRequest(factory.make(.mooc, "/meol/homepage/V8/include/logout.jsp"), validateLogin: false)
    }
}
