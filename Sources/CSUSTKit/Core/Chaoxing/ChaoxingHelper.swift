import Alamofire
import Foundation
import SwiftSoup

/// 学习通助手
public class ChaoxingHelper: BaseHelper {

    // MARK: - Methods

    public override func isLoggedIn() async -> Bool {
        return (try? await getProfile()) != nil
    }

    /// 获取个人信息
    /// - Throws: `ChaoxingHelperError`
    /// - Returns: 个人信息
    public func getProfile() async throws -> Profile {
        let response = try await performRequest(factory.make(.chaoxing, "/space/index"))
        let document = try SwiftSoup.parse(response)
        guard let personalNameElement = try document.select("p.personalName").first() else {
            throw ChaoxingHelperError.profileRetrievalFailed("未找到姓名元素")
        }
        let rawName = try personalNameElement.attr("title")
        let name = rawName.isEmpty ? try personalNameElement.text().trim() : rawName
        return Profile(name: name)
    }

    /// 获取全部作业
    /// - Throws: `ChaoxingHelperError`
    /// - Returns: 作业列表
    public func getAssignments() async throws -> [Assignment] {
        let response = try await performRequest(factory.make(.chaoxingAPI, "/mooc-ans/work/stu-work"))
        let document = try SwiftSoup.parse(response)
        let now = Date()
        guard let listElement = try document.select("#content ul.nav").first() else {
            throw ChaoxingHelperError.assignmentsRetrievalFailed("未找到作业列表")
        }

        var assignments: [Assignment] = []
        for itemElement in try listElement.select("li") {
            guard let titleElement = try itemElement.select("div[role=option] > p").first() else {
                throw ChaoxingHelperError.assignmentsRetrievalFailed("作业条目缺少名称")
            }
            guard let iconElement = try itemElement.select("img").first() else {
                throw ChaoxingHelperError.assignmentsRetrievalFailed("作业条目缺少图标")
            }
            let detailSpans = try itemElement.select("div[role=option] > span")
            guard detailSpans.count >= 2 else {
                throw ChaoxingHelperError.assignmentsRetrievalFailed("作业条目结构异常")
            }
            let statusText = try detailSpans[0].text().trim()
            let isCompleted: Bool =
                switch statusText {
                case "未提交":
                    false
                case "已完成":
                    true
                default:
                    throw ChaoxingHelperError.assignmentsRetrievalFailed("未知的作业状态: \(statusText)")
                }
            let remainingText = try itemElement.select("span.fr").first()?.text().trim()
            assignments.append(
                Assignment(
                    title: try titleElement.text().trim(),
                    isCompleted: isCompleted,
                    courseName: try detailSpans[1].text().trim(),
                    deadline: try remainingText.map { try Self.parseDeadline($0, now: now) },
                    iconURL: "https:" + (try iconElement.attr("src")),
                    detailURL: try itemElement.attr("data")
                )
            )
        }
        return assignments
    }

    // MARK: - Utils

    /// 把「剩余{小时}小时{分钟}分钟」换算成截止时间
    private static func parseDeadline(_ remainingText: String, now: Date) throws -> Date {
        guard remainingText.hasPrefix("剩余"), remainingText.hasSuffix("分钟") else {
            throw ChaoxingHelperError.assignmentsRetrievalFailed("剩余时间格式异常: \(remainingText)")
        }
        let body = String(remainingText.dropFirst("剩余".count).dropLast("分钟".count))
        let components = body.components(separatedBy: "小时")
        guard components.count == 2, let hours = Int(components[0]), let minutes = Int(components[1]) else {
            throw ChaoxingHelperError.assignmentsRetrievalFailed("剩余时间格式异常: \(remainingText)")
        }
        return now.addingTimeInterval(TimeInterval(hours * 3600 + minutes * 60))
    }

    // MARK: - Request

    /// 是否因未登录而被拒
    internal func isLoginRequired(response: String) -> Bool {
        return response.contains("<title>用户登录</title>") || response.contains("请输入账号")
    }

    internal func performRequest(_ url: String, _ method: HTTPMethod = .get, _ parameters: [String: String]? = nil) async throws -> String {
        let response = try await session.request(url, method: method, parameters: parameters, encoding: URLEncoding.default).string()
        if isLoginRequired(response: response) {
            throw ChaoxingHelperError.notLoggedIn
        }
        return response
    }
}
