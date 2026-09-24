import Foundation

extension ChaoxingHelper {
    /// 学习通助手相关错误
    public enum ChaoxingHelperError: Error, LocalizedError {
        /// 个人信息获取失败
        case profileRetrievalFailed(String)
        /// 作业信息获取失败
        case assignmentsRetrievalFailed(String)
        /// 未登录
        case notLoggedIn

        /// 错误描述
        public var errorDescription: String? {
            switch self {
            case .profileRetrievalFailed(let message):
                return "获取个人信息失败: \(message)"
            case .assignmentsRetrievalFailed(let message):
                return "获取作业信息失败: \(message)"
            case .notLoggedIn:
                return "学习通未登录"
            }
        }
    }
}
