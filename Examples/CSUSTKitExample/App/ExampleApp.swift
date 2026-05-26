import Alamofire
import CSUSTKit

struct ExampleApp {
    private let session: Session

    init(session: Session) {
        self.session = session
    }

    func run() async {
        while true {
            print("")
            print("=== 入口菜单 ===")
            print("1. 登录演示")
            print("2. WebVPN 工具")
            print("0. 退出")

            switch prompt("请选择操作") {
            case "1":
                await runLoginDemo(session: session)
            case "2":
                runWebVPNMenu()
            case "0":
                return
            default:
                print("输入无效，请重新选择。")
            }
        }
    }
}
