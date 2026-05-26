import CSUSTKit
import Foundation

func runWebVPNMenu() {
    while true {
        print("")
        print("=== WebVPN 工具 ===")
        print("1. 原始 URL 转 WebVPN URL")
        print("2. WebVPN URL 还原原始 URL")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            let originalURLString = promptNonEmpty("请输入原始 URL")
            guard let originalURL = URL(string: originalURLString) else {
                print("URL格式错误")
                break
            }
            do {
                let vpnURL = try WebVPNHelper.encryptURL(originalURL)
                print("")
                print("转换结果:")
                print(vpnURL)
            } catch {
                print("转换失败: \(error)")
            }
        case "2":
            let vpnURLString = promptNonEmpty("请输入 WebVPN URL")
            guard let vpnURL = URL(string: vpnURLString) else {
                print("URL格式错误")
                break
            }
            do {
                let originalURL = try WebVPNHelper.decryptURL(vpnURL)
                print("")
                print("转换结果:")
                print(originalURL)
            } catch {
                print("转换失败: \(error)")
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}
