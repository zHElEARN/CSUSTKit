import CryptoSwift
import Foundation

/// WebVPN 助手
public class WebVPNHelper {
    private static let host: String = "vpn.csust.edu.cn"
    private static let key: String = "CASB2021EnLink!!"
    private static let iv: String = "CASB2021EnLink!!"
    private static let prefix: String = "webvpn"

    /// 将原始 URL 加密为 WebVPN URL
    /// - Parameter originalURL: 原始 URL
    /// - Throws: `WebVPNHelperError`
    /// - Returns: 加密后的 WebVPN URL
    public static func encryptURL(originalURL: String) throws -> String {
        var urlString = originalURL

        // 如果用户没有输入 scheme，默认尝试补全 http
        if let u = URL(string: urlString), u.scheme == nil {
            if urlString.hasPrefix("//") {
                urlString = "http:" + urlString
            } else {
                urlString = "http://" + urlString
            }
        }

        guard let url = URL(string: urlString),
            let host = url.host,
            let scheme = url.scheme
        else {
            throw WebVPNHelperError.urlEncryptionFailed("无效的 URL 或无法获取主机名/协议")
        }

        var originalHost = host
        if let port = url.port {
            originalHost += ":\(port)"
        }

        let encryptedHost: String
        do {
            encryptedHost = try encryptHost(originalHost)
        } catch {
            throw WebVPNHelperError.urlEncryptionFailed("加密主机名失败: \(error.localizedDescription)")
        }

        var pathPart = url.path
        if let query = url.query {
            pathPart += "?\(query)"
        }
        if let fragment = url.fragment {
            pathPart += "#\(fragment)"
        }

        let finalPath = pathPart.isEmpty ? "/" : pathPart

        return "https://\(self.host)/\(scheme)/\(self.prefix)\(encryptedHost)\(finalPath)"
    }

    /// 将 WebVPN URL 解密为原始 URL
    /// - Parameter vpnURL: WebVPN URL
    /// - Throws: `WebVPNHelperError`
    /// - Returns: 原始 URL
    public static func decryptURL(vpnURL: String) throws -> String {
        guard let url = URL(string: vpnURL) else {
            throw WebVPNHelperError.urlDecryptionFailed("无效的 WebVPN URL")
        }

        let pathComponents = url.pathComponents

        guard pathComponents.count >= 3 else {
            throw WebVPNHelperError.urlDecryptionFailed("WebVPN URL 路径格式不正确")
        }

        let scheme = pathComponents[1]
        let encryptedHostComponent = pathComponents[2]

        guard encryptedHostComponent.hasPrefix(self.prefix) else {
            throw WebVPNHelperError.urlDecryptionFailed("未找到指定的 WebVPN 前缀")
        }

        // 剥离 "webvpn" 前缀获取真实加密 Hex
        let encryptedHost = String(encryptedHostComponent.dropFirst(self.prefix.count))

        let decryptedHost: String
        do {
            decryptedHost = try decryptHost(encryptedHost)
        } catch {
            throw WebVPNHelperError.urlDecryptionFailed("解密主机名失败: \(error.localizedDescription)")
        }

        let prefixToDrop = "/\(pathComponents[1])/\(encryptedHostComponent)"
        guard url.path.hasPrefix(prefixToDrop) else {
            throw WebVPNHelperError.urlDecryptionFailed("URL 路径与预期格式不符")
        }

        var originalPath = String(url.path.dropFirst(prefixToDrop.count))

        if originalPath.isEmpty {
            originalPath = "/"
        }

        if let query = url.query {
            originalPath += "?\(query)"
        }
        if let fragment = url.fragment {
            originalPath += "#\(fragment)"
        }

        return "\(scheme)://\(decryptedHost)\(originalPath)"
    }

    private static func encryptHost(_ text: String) throws -> String {
        guard let keyData = key.data(using: .utf8),
            let ivData = iv.data(using: .utf8),
            let textData = text.data(using: .utf8)
        else {
            throw WebVPNHelperError.hostEncryptionFailed("无法转换密钥、初始向量或文本为字节数组")
        }

        let keyBytes = [UInt8](keyData)
        let ivBytes = [UInt8](ivData)
        let textBytes = [UInt8](textData)

        do {
            let aes = try AES(key: keyBytes, blockMode: CBC(iv: ivBytes), padding: .pkcs7)
            let encryptedBytes = try aes.encrypt(textBytes)
            return encryptedBytes.toHexString()
        } catch {
            throw WebVPNHelperError.hostEncryptionFailed("AES加密失败: \(error.localizedDescription)")
        }
    }

    private static func decryptHost(_ hexText: String) throws -> String {
        guard let keyData = key.data(using: .utf8),
            let ivData = iv.data(using: .utf8)
        else {
            throw WebVPNHelperError.hostDecryptionFailed("无法转换密钥或初始向量为字节数组")
        }

        let keyBytes = [UInt8](keyData)
        let ivBytes = [UInt8](ivData)

        do {
            let aes = try AES(key: keyBytes, blockMode: CBC(iv: ivBytes), padding: .pkcs7)
            let encryptedBytes = [UInt8](hex: hexText)

            let decryptedBytes = try aes.decrypt(encryptedBytes)

            guard let result = String(bytes: decryptedBytes, encoding: .utf8) else {
                throw WebVPNHelperError.hostDecryptionFailed("解密后无法转换为字符串")
            }
            return result
        } catch let error as WebVPNHelperError {
            throw error
        } catch {
            throw WebVPNHelperError.hostDecryptionFailed("AES解密失败: \(error.localizedDescription)")
        }
    }
}
