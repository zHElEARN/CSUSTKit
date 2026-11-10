import CSUSTKit
import Foundation
import Testing

struct WebVPNHelperTests {
    @Test func encryptedHostMatchesReferenceVector() throws {
        let url = try #require(URL(string: "https://www.csust.edu.cn/"))
        let encrypted = try WebVPNHelper.encryptURL(url)

        #expect(encrypted.scheme == "https")
        #expect(encrypted.host == "vpn.csust.edu.cn")
        #expect(encrypted.absoluteString == "https://vpn.csust.edu.cn/https/webvpn4adab4fb272c5ac023304193e377fa2e12b40445ab95148eee69267083a2d062/")
    }

    @Test(
        "加密再解密可还原原始 URL",
        arguments: [
            "https://www.csust.edu.cn/",
            "https://jwc.csust.edu.cn/jwglxt/xtgl/index_initMenu.html?flag=1",
            "http://edu.csust.edu.cn:8080/api/v1/list?id=42#section",
            "https://example.com",
        ]
    )
    func roundTrip(urlString: String) throws {
        let original = try #require(URL(string: urlString))
        let decrypted = try WebVPNHelper.decryptURL(WebVPNHelper.encryptURL(original))

        #expect(normalized(decrypted) == normalized(original))
        #expect(decrypted.query == original.query)
        #expect(decrypted.fragment == original.fragment)
    }

    @Test func preservesPort() throws {
        let original = try #require(URL(string: "https://edu.csust.edu.cn:443/cas/login"))
        let encrypted = try WebVPNHelper.encryptURL(original)
        let decrypted = try WebVPNHelper.decryptURL(encrypted)

        #expect(encrypted.path.hasPrefix("/https/webvpn"))
        #expect(decrypted.host == "edu.csust.edu.cn")
        #expect(decrypted.port == 443)
    }

    @Test func rejectsPathWithoutWebVPNPrefix() throws {
        let url = try #require(URL(string: "https://vpn.csust.edu.cn/https/plainhost/"))
        #expect(throws: WebVPNHelperError.self) {
            try WebVPNHelper.decryptURL(url)
        }
    }

    @Test func rejectsPathThatIsTooShort() throws {
        let url = try #require(URL(string: "https://vpn.csust.edu.cn/only"))
        #expect(throws: WebVPNHelperError.self) {
            try WebVPNHelper.decryptURL(url)
        }
    }

    @Test func rejectsURLWithoutHost() {
        #expect(throws: WebVPNHelperError.self) {
            try WebVPNHelper.encryptURL(URL(fileURLWithPath: "/tmp/secret.txt"))
        }
    }
}

private func normalized(_ url: URL) -> String {
    var result = "\(url.scheme ?? "")://\(url.host ?? "")"
    if let port = url.port {
        result += ":\(port)"
    }
    if !url.path.isEmpty, url.path != "/" {
        result += url.path
    }
    if let query = url.query {
        result += "?\(query)"
    }
    if let fragment = url.fragment {
        result += "#\(fragment)"
    }
    return result
}
