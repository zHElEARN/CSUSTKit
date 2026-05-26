import CryptoSwift
import Foundation

/// WebVPN 助手
public class WebVPNHelper {
    private static let host: String = "vpn.csust.edu.cn"

    private static let key: String = "CASB2021EnLink!!"
    private static let keyBytes = [UInt8](key.data(using: .utf8)!)

    private static let iv: String = "CASB2021EnLink!!"
    private static let ivBytes = [UInt8](key.data(using: .utf8)!)

    private static let prefix: String = "webvpn"

    /// 将原始 URL 加密为 WebVPN URL
    /// - Parameter url: 原始 URL
    /// - Throws: `WebVPNHelperError`
    /// - Returns: 加密后的 WebVPN URL
    public static func encryptURL(_ url: URL) throws -> URL {
        guard let host = url.host, let scheme = url.scheme else {
            throw WebVPNHelperError.urlEncryptionFailed("无法获取主机名/协议")
        }

        var originalHost = host
        if let port = url.port {
            originalHost += ":\(port)"
        }

        let encryptedHost = try encryptHost(originalHost)

        var components = URLComponents()
        components.scheme = "https"
        components.host = self.host

        let basePath = url.path.hasPrefix("/") || url.path.isEmpty ? url.path : "/\(url.path)"
        let finalPath = basePath.isEmpty ? "/" : basePath

        components.path = "/\(scheme)/\(self.prefix)\(encryptedHost)\(finalPath)"

        components.query = url.query
        components.fragment = url.fragment

        guard let finalURL = components.url else {
            throw WebVPNHelperError.urlEncryptionFailed("无法构建加密后的 URL")
        }

        return finalURL
    }

    /// 将 WebVPN URL 解密为原始 URL
    /// - Parameter url: WebVPN URL
    /// - Throws: `WebVPNHelperError`
    /// - Returns: 原始 URL
    public static func decryptURL(_ url: URL) throws -> URL {
        let pathComponents = url.pathComponents

        guard pathComponents.count >= 3 else {
            throw WebVPNHelperError.urlDecryptionFailed("WebVPN URL 路径格式不正确")
        }

        let scheme = pathComponents[1]
        let encryptedHostComponent = pathComponents[2]

        guard encryptedHostComponent.hasPrefix(self.prefix) else {
            throw WebVPNHelperError.urlDecryptionFailed("未找到指定的 WebVPN 前缀")
        }

        let encryptedHost = String(encryptedHostComponent.dropFirst(self.prefix.count))
        let decryptedHost = try decryptHost(encryptedHost)

        var components = URLComponents()
        components.scheme = scheme

        let hostParts = decryptedHost.split(separator: ":")
        components.host = String(hostParts[0])
        if hostParts.count > 1, let port = Int(hostParts[1]) {
            components.port = port
        }

        let prefixToDrop = "/\(pathComponents[1])/\(encryptedHostComponent)"
        guard url.path.hasPrefix(prefixToDrop) else {
            throw WebVPNHelperError.urlDecryptionFailed("URL 路径与预期格式不符")
        }

        var originalPath = String(url.path.dropFirst(prefixToDrop.count))

        if originalPath == "/" {
            originalPath = ""
        } else if !originalPath.isEmpty && !originalPath.hasPrefix("/") {
            originalPath = "/\(originalPath)"
        }

        components.path = originalPath
        components.query = url.query
        components.fragment = url.fragment

        guard let finalURL = components.url else {
            throw WebVPNHelperError.urlDecryptionFailed("无法构建解密后的 URL")
        }

        return finalURL
    }

    private static func encryptHost(_ text: String) throws -> String {
        guard let textData = text.data(using: .utf8) else {
            throw WebVPNHelperError.hostEncryptionFailed("无法转换文本为字节数组")
        }

        let textBytes = [UInt8](textData)

        let aes = try AES(key: keyBytes, blockMode: CBC(iv: ivBytes), padding: .pkcs7)
        let encryptedBytes = try aes.encrypt(textBytes)
        return encryptedBytes.toHexString()
    }

    private static func decryptHost(_ hexText: String) throws -> String {
        let aes = try AES(key: keyBytes, blockMode: CBC(iv: ivBytes), padding: .pkcs7)
        let encryptedBytes = [UInt8](hex: hexText)

        let decryptedBytes = try aes.decrypt(encryptedBytes)

        guard let result = String(bytes: decryptedBytes, encoding: .utf8) else {
            throw WebVPNHelperError.hostDecryptionFailed("解密后无法转换为字符串")
        }
        return result
    }
}
