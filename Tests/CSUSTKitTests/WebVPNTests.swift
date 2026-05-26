import Foundation
import Testing

@testable import CSUSTKit

struct WebVPNTests {
    @Test(
        "验证特定 WebVPN 链接解密为原始 URL",
        arguments: [
            (
                URL(string: "https://vpn.csust.edu.cn/http/webvpnca1e69080fcc45ac45bed760950fd677/")!,
                URL(string: "http://pt.csust.edu.cn")!
            ),
            (
                URL(string: "https://vpn.csust.edu.cn/http/webvpn505c0e70383db2ebb7035169513d1ffa/")!,
                URL(string: "http://xk.csust.edu.cn")!
            ),
            (
                URL(string: "https://vpn.csust.edu.cn/http/webvpn0290db6ae56290b8883befe06cf1faf082ff567793ebc8ea223c577d2c216af3/index.html")!,
                URL(string: "http://192.168.1.1:8080/index.html")!
            ),
        ]
    )
    func verifyDecryption(vpnURL: URL, originalURL: URL) throws {
        let decrypted = try WebVPNHelper.decryptURL(vpnURL)

        if decrypted != originalURL {
            print("❌ 解密不匹配")
            print("期望: \(originalURL)")
            print("实际: \(decrypted)")
        }

        #expect(decrypted == originalURL)
    }

    @Test(
        "验证原始 URL 加密为特定 WebVPN 链接",
        arguments: [
            (
                URL(string: "http://xk.csust.edu.cn")!,
                URL(string: "https://vpn.csust.edu.cn/http/webvpn505c0e70383db2ebb7035169513d1ffa/")!,
            ),
            (
                URL(string: "http://pt.csust.edu.cn")!,
                URL(string: "https://vpn.csust.edu.cn/http/webvpnca1e69080fcc45ac45bed760950fd677/")!,
            ),
            (
                URL(string: "http://192.168.1.1:8080/index.html")!,
                URL(string: "https://vpn.csust.edu.cn/http/webvpn0290db6ae56290b8883befe06cf1faf082ff567793ebc8ea223c577d2c216af3/index.html")!,
            ),
        ]
    )
    func verifyEncryption(originalURL: URL, expectedVPNURL: URL) throws {
        let encrypted = try WebVPNHelper.encryptURL(originalURL)

        if encrypted != expectedVPNURL {
            print("⚠️ 加密结果不一致")
            print("输入: \(originalURL)")
            print("期望: \(expectedVPNURL)")
            print("实际: \(encrypted)")
        }

        #expect(encrypted == expectedVPNURL)
    }

    @Test(
        "WebVPN 加密解密往返测试",
        arguments: [
            URL(string: "http://www.baidu.com")!,
            URL(string: "https://jwc.csust.edu.cn")!,
            URL(string: "http://192.168.1.1:8080/index.html")!,
            URL(string: "https://lofter.com/front/login?id=123")!,
        ]
    )
    func verifyRoundTrip(url: URL) throws {
        let encrypted = try WebVPNHelper.encryptURL(url)
        let decrypted = try WebVPNHelper.decryptURL(encrypted)

        #expect(decrypted == url)
    }
}
