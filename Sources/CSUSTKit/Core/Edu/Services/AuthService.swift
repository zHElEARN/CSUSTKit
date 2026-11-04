import Alamofire
import Foundation

extension EduHelper {
    /// 认证服务
    public class AuthService: BaseService {
        /// 登出当前用户
        public func logout() async throws {
            try await session.request(factory.make(.education, "/jsxsd/xk/LoginToXk?method=exit&tktime=\(Date().millisecondsSince1970)")).data()
        }
    }
}
