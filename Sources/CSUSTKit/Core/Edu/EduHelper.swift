import Alamofire
import Foundation
import SwiftSoup

/// 教务助手
public class EduHelper: BaseHelper {
    public override func isLoggedIn() async -> Bool {
        return (try? await getProfile()) != nil
    }

    internal func isLoginRequired(response: String) -> Bool {
        return response.contains("请输入账号")
    }

    internal func performRequest(_ url: String, _ method: HTTPMethod = .get, _ parameters: [String: String]? = nil) async throws -> String {
        let response = try await session.request(url, method: method, parameters: parameters, encoding: URLEncoding.default).string()
        if isLoginRequired(response: response) {
            throw EduHelperError.notLoggedIn
        }
        return response
    }
}
