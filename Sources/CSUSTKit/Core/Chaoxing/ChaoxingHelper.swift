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
