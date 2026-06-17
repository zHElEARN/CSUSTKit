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
        print("2. 获取评教列表")
        print("3. 查看评教课程列表")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            await handleAsyncOperation {
                print(try await evalHelper.getProfile())
            }
        case "2":
            await handleAsyncOperation {
                try await evalHelper.getEvals()
            }
        case "3":
            let id = promptNonEmpty("评教ID")
            await handleAsyncOperation {
                try await evalHelper.getEvalCourses(id: id)
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}
