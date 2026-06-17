import Alamofire
import CSUSTKit
import Foundation

func runLoginDemo(session: Session) async {
    let connectionMode = selectConnectionMode()
    let ssoHelper = SSOHelper(mode: connectionMode, session: session)

    let didLogin = await performSSOLogin(using: ssoHelper)
    guard didLogin else {
        print("已返回入口菜单。")
        return
    }

    await runMainMenu(using: ssoHelper, connectionMode: connectionMode, session: session)
}

private func selectConnectionMode() -> ConnectionMode {
    while true {
        print("")
        print("=== 网络模式 ===")
        print("1. 直接连接")
        print("2. WebVPN")
        let input = prompt("请选择网络模式")

        switch input {
        case "1":
            return .direct
        case "2":
            return .webVpn
        default:
            print("输入无效，请输入 1 或 2。")
        }
    }
}

private func performSSOLogin(using ssoHelper: SSOHelper) async -> Bool {
    while true {
        do {
            print("")
            print("=== 统一认证登录 ===")

            let loginForm = try await ssoHelper.getLoginForm()
            let username = promptNonEmpty("请输入用户名")
            let needCaptcha = try await ssoHelper.checkNeedCaptcha(username: username)

            var captcha: String?
            if needCaptcha {
                let captchaImageData = try await ssoHelper.getCaptcha()
                let captchaImageURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("captcha.jpg")
                try captchaImageData.write(to: captchaImageURL)
                print("验证码已保存到 \(captchaImageURL.path)")
                captcha = promptNonEmpty("请输入验证码")
            }

            let password = promptNonEmpty("请输入密码")
            try await ssoHelper.login(
                loginForm: loginForm,
                username: username,
                password: password,
                captcha: captcha
            )

            let user = try await ssoHelper.getLoginUser()
            print("")
            print("登录成功")
            print("姓名: \(user.userName)")
            print("学号: \(user.userAccount)")
            print("学院: \(user.deptName)")
            return true
        } catch {
            print("")
            print("登录失败: \(error)")
            print("1. 重试登录")
            print("0. 返回入口菜单")
            let retryChoice = prompt("请选择")
            if retryChoice == "1" {
                continue
            }
            return false
        }
    }
}

private func runMainMenu(using ssoHelper: SSOHelper, connectionMode: ConnectionMode, session: Session) async {
    let moocHelper = MoocHelper(mode: connectionMode, session: session)
    let eduHelper = EduHelper(mode: connectionMode, session: session)
    let campusCardHelper = CampusCardHelper(mode: connectionMode, session: session)
    let evalHelper = EvalHelper(mode: .direct, session: session)

    while true {
        print("")
        print("=== 主菜单 ===")
        print("1. 网络课程中心")
        print("2. 教务系统")
        print("3. 校园卡系统")
        print("4. 评教系统登录")
        print("0. 返回入口菜单")

        switch prompt("请选择操作") {
        case "1":
            do {
                try await ssoHelper.loginToMooc()
                await runMoocMenu(using: moocHelper)
            } catch {
                print("进入网络课程中心失败: \(error)")
            }
        case "2":
            do {
                try await ssoHelper.loginToEducation()
                await runEducationMenu(using: eduHelper)
            } catch {
                print("进入教务系统失败: \(error)")
            }
        case "3":
            do {
                let (_, ticket) = try await ssoHelper.loginToCampusCard()
                await runCampusCardMenu(using: campusCardHelper, ticket: ticket)
            } catch {
                print("进入校园卡系统失败: \(error)")
            }
        case "4":
            do {
                let (_, ticket) = try await ssoHelper.loginToEval()
                await runEvalMenu(using: evalHelper, ticket: ticket)
            } catch {
                print("进入评教系统失败: \(error)")
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}
