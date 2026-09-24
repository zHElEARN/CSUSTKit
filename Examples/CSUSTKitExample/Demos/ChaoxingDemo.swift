import CSUSTKit

func runChaoxingMenu(using chaoxingHelper: ChaoxingHelper) async {
    while true {
        print("")
        print("=== 学习通 ===")
        print("1. 查看个人信息")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            await handleAsyncOperation {
                let profile = try await chaoxingHelper.getProfile()
                print("")
                print("姓名: \(profile.name)")
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}
