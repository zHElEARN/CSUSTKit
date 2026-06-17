import CSUSTKit

func runEvalMenu(using evalHelper: EvalHelper, ticket: String) async {
    do {
        try await evalHelper.syncToken(ticket: ticket)
    } catch {
        print("无法获取token: \(error)")
        return
    }
    while true {
        print("")
        print("=== 评教系统 ===")
        print("1. 查看个人信息")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            await handleAsyncOperation {
                print(try await evalHelper.getProfile())
            }

        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}
