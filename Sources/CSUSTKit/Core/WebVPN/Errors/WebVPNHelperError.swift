import Foundation

/// WebVPN 相关错误
public enum WebVPNHelperError: Error, LocalizedError {
    /// URL加密失败
    case urlEncryptionFailed(String)
    /// URL解密失败
    case urlDecryptionFailed(String)
    /// 主机名加密失败
    case hostEncryptionFailed(String)
    /// 主机名解密失败
    case hostDecryptionFailed(String)

    /// 错误描述
    public var errorDescription: String? {
        switch self {
        case .urlEncryptionFailed(let message):
            return "URL加密失败: \(message)"
        case .urlDecryptionFailed(let message):
            return "URL解密失败: \(message)"
        case .hostEncryptionFailed(let message):
            return "主机名加密失败: \(message)"
        case .hostDecryptionFailed(let message):
            return "主机名解密失败: \(message)"
        }
    }
}
