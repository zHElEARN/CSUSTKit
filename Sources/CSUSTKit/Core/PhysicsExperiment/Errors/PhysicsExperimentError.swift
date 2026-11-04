import Foundation

extension PhysicsExperimentHelper {
    public enum PhysicsExperimentHelperError: Error, LocalizedError {
        /// 登录失败
        case loginFailed(String)
        /// 获取课程表失败
        case schedulesRetrievalFailed(String)
        /// 获取课程成绩失败
        case courseGradesRetrievalFailed(String)
        /// 未登录
        case notLoggedIn

        /// 错误描述
        public var errorDescription: String? {
            switch self {
            case .loginFailed(let message):
                return "登录失败: \(message)"
            case .schedulesRetrievalFailed(let message):
                return "获取课程表失败: \(message)"
            case .courseGradesRetrievalFailed(let message):
                return "获取课程成绩失败: \(message)"
            case .notLoggedIn:
                return "大物实验平台未登录"
            }
        }
    }
}
