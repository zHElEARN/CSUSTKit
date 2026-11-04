import Alamofire
import Foundation

extension EduHelper {
    /// 登出当前用户
    public func logout() async throws {
        try await performDataRequest(factory.make(.education, "/jsxsd/xk/LoginToXk?method=exit&tktime=\(Date().millisecondsSince1970)"))
    }
}
