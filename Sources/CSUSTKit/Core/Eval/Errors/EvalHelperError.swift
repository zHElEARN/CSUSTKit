import Foundation

extension EvalHelper {
    public enum EvalHelperError: Error, LocalizedError {
        case notLoggedIn
        case syncTokenFailed(String)
        case profileRetrievalFailed(String)

        public var errorDescription: String? {
            switch self {
            case .notLoggedIn:
                return "评教系统未登录"
            case .syncTokenFailed(let message):
                return "获取Token失败: \(message)"
            case .profileRetrievalFailed(let message):
                return "获取个人信息失败: \(message)"
            }
        }
    }
}
