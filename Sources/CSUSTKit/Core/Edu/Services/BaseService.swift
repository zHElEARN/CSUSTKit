import Alamofire

extension EduHelper {
    public class BaseService {
        internal let mode: ConnectionMode
        internal let factory: URLFactory
        internal var session: Session

        init(mode: ConnectionMode, session: Session) {
            self.mode = mode
            self.factory = URLFactory(mode: mode)
            self.session = session
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
}
