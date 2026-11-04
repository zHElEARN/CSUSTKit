import Alamofire

public class BaseHelper {
    internal let session: Session
    internal let mode: ConnectionMode
    internal let factory: URLFactory

    public init(mode: ConnectionMode = .direct, session: Session = Session()) {
        self.mode = mode
        self.session = session
        self.factory = .init(mode: mode)
    }

    /// 判断响应是否表示已被登出，由各子系统覆写
    internal func validateLoginResponse<T>(_ response: T) throws {}

    internal func isWebVpnLoginPage(_ html: String) -> Bool {
        return html.contains("window.location.href = './start.html")
    }

    /// 该子系统所有请求默认携带的拦截器
    internal var requestInterceptor: (any RequestInterceptor)? { return nil }

    /// 检查是否登录
    /// - Returns: 是否登录
    public func isLoggedIn() async -> Bool {
        return false
    }
}
