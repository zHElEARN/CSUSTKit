import Alamofire
import Foundation

public class BaseHelper {
    internal let session: Session
    internal let mode: ConnectionMode
    internal let factory: URLFactory

    public init(mode: ConnectionMode = .direct, session: Session = Session()) {
        self.mode = mode
        self.session = session
        self.factory = .init(mode: mode)
    }

    /// 响应明确表示未登录时抛出的子系统错误
    internal var notLoggedInError: (any Error)? { nil }

    /// 各子系统只判断自己的登录标记。正文不可用时传入空字符串。
    internal func isSubsystemLoginResponse(_ body: String, finalURL: URL) -> Bool { false }

    internal final func validateLoginResponse(_ body: String, finalURL: URL) throws {
        guard let error = notLoggedInError else { return }
        if (mode == .webVPN && isWebVPNLoginPage(body)) || isSubsystemLoginResponse(body, finalURL: finalURL) {
            throw error
        }
    }

    private func isWebVPNLoginPage(_ body: String) -> Bool {
        body.contains("window.location.href = './start.html")
    }

    /// 该子系统所有请求默认携带的拦截器
    internal var requestInterceptor: (any RequestInterceptor)? { return nil }

    /// 检查是否登录
    /// - Returns: 是否登录
    public func isLoggedIn() async -> Bool {
        return false
    }
}
