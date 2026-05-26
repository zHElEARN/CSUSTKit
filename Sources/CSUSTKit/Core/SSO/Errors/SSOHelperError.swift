import Foundation

extension SSOHelper {
    /// 统一身份认证相关错误
    public enum SSOHelperError: Error, LocalizedError {
        /// 获取登录表单失败
        case getLoginFormFailed(String)
        /// 登录失败
        case loginFailed(String)
        /// 验证码获取失败
        case captchaRetrievalFailed
        /// 动态码获取失败
        case dynamicCodeRetrievalFailed(String)
        /// 网络课程中心登录失败
        case loginToMoocFailed(String)
        /// 校园卡系统登录失败
        case loginToCampusCardFailed(String)
        /// 未登录
        case notLoggedIn

        /// 错误描述
        public var errorDescription: String? {
            switch self {
            case .getLoginFormFailed(let message):
                return "获取登录表单失败: \(message)"
            case .loginFailed(let message):
                return "登录失败: \(message)"
            case .captchaRetrievalFailed:
                return "验证码获取失败"
            case .dynamicCodeRetrievalFailed(let message):
                return "动态码获取失败: \(message)"
            case .loginToMoocFailed(let message):
                return "网络课程中心登录失败: \(message)"
            case .loginToCampusCardFailed(let message):
                return "校园卡系统登录失败: \(message)"
            case .notLoggedIn:
                return "统一身份认证未登录"
            }
        }
    }
}
