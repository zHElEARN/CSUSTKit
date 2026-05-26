public struct URLFactory {
    public let mode: ConnectionMode
    private let vpnBase = "https://vpn.csust.edu.cn"
    private let prefix = "webvpn"

    public init(mode: ConnectionMode) {
        self.mode = mode
    }

    /// 生成 URL
    /// - Parameters:
    ///   - domain: 目标子系统 (如 .mooc)
    ///   - path: 路径字符串 (包含 query 参数)，建议以 "/" 开头
    /// - Returns: 完整的 URL 字符串
    public func make(_ domain: ServiceDomain, _ path: String) -> String {
        return make(domain, path, for: self.mode)
    }

    /// 生成 URL
    /// - Parameters:
    ///   - domain: 目标子系统 (如 .mooc)
    ///   - path: 路径字符串 (包含 query 参数)，建议以 "/" 开头
    ///   - mode: 连接方式
    /// - Returns: 完整的 URL 字符串
    public func make(_ domain: ServiceDomain, _ path: String, for mode: ConnectionMode) -> String {
        let safePath = path.hasPrefix("/") ? path : "/\(path)"
        switch mode {
        case .direct:
            return "\(domain.scheme)://\(domain.directHost)\(safePath)"
        case .webVpn:
            return "\(vpnBase)/\(domain.scheme)/\(prefix)\(domain.vpnHex)\(safePath)"
        }
    }
}
