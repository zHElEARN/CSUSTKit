import Alamofire

public class BaseHelper {
    public let session: Session
    internal let mode: ConnectionMode
    internal let factory: URLFactory

    public init(mode: ConnectionMode = .direct, session: Session = Session()) {
        self.mode = mode
        self.session = session
        self.factory = .init(mode: mode)
    }

    /// 解析响应前判断是否已被登出
    internal var loginValidator: ((String) throws -> Void)? { return nil }

    /// 该子系统所有请求默认携带的拦截器
    internal var requestInterceptor: (any RequestInterceptor)? { return nil }

    /// 检查是否登录
    /// - Returns: 是否登录
    public func isLoggedIn() async -> Bool {
        return false
    }
}
