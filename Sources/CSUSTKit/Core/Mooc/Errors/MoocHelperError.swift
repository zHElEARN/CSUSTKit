import Foundation

/// 网络课程中心助手相关错误
public enum MoocHelperError: Error, LocalizedError {
    /// 个人信息获取失败
    case profileRetrievalFailed(String)
    /// 课程信息获取失败
    case courseRetrievalFailed(String)
    /// 作业信息获取失败
    case assignmentsRetrievalFailed(String)
    /// 测验信息获取失败
    case testRetrievalFailed(String)
    /// 获取有待完成作业的课程名称失败
    case courseNamesWithPendingAssignmentsRetrievalFailed(String)
    /// 未登录
    case notLoggedIn

    /// 错误描述
    public var errorDescription: String? {
        switch self {
        case .profileRetrievalFailed(let message):
            return "获取个人信息失败: \(message)"
        case .courseRetrievalFailed(let message):
            return "获取课程信息失败: \(message)"
        case .assignmentsRetrievalFailed(let message):
            return "获取作业信息失败: \(message)"
        case .testRetrievalFailed(let message):
            return "获取测验信息失败: \(message)"
        case .courseNamesWithPendingAssignmentsRetrievalFailed(let message):
            return "获取有待完成作业的课程名称失败: \(message)"
        case .notLoggedIn:
            return "网络课程中心未登录"
        }
    }
}
