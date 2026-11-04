import Alamofire
import Foundation
import SwiftSoup

/// 统一身份认证助手
public class SSOHelper: BaseHelper {

    // MARK: - Models

    private struct LoginUserResponse: Decodable, Sendable {
        let data: Profile?
    }

    private struct CheckResponse: Decodable {
        let isNeed: Bool
    }

    // MARK: - Methods

    /// 获取登录表单
    /// - Throws: `SSOHelperError`
    /// - Returns: 登录表单数据
    public func getLoginForm() async throws -> LoginForm {
        let response = try await performResponseRequest(
            factory.make(.authServer, "/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin"),
            validateLogin: false
        )
        // 已经登录
        guard response.response?.url != URL(factory.make(.ehall, "/index.html")) else {
            throw SSOHelperError.getLoginFormFailed("账号已登录")
        }
        guard let value = response.value else {
            throw SSOHelperError.getLoginFormFailed("无响应数据")
        }
        let document = try SwiftSoup.parse(value)

        try checkNeedImproveUserInfo(response)

        guard let pwdEncryptSaltInput = try document.select("input#pwdEncryptSalt").first() else {
            throw SSOHelperError.getLoginFormFailed("未找到pwdEncryptSalt输入框")
        }
        guard let executionInput = try document.select("input#execution, input[name=execution]").first() else {
            throw SSOHelperError.getLoginFormFailed("未找到execution输入框")
        }
        return LoginForm(pwdEncryptSalt: try pwdEncryptSaltInput.attr("value"), execution: try executionInput.attr("value"))
    }

    private func checkNeedImproveUserInfo(_ response: DataResponse<String, AFError>) throws {
        guard let html = response.value else { return }

        let currentURL = response.response?.url?.absoluteString ?? ""

        if html.contains("<title>完善资料</title>") || currentURL.contains("improveUserInfo") {
            throw SSOHelperError.needImproveUserInfo
        }
    }

    /// 检查是否需要验证码
    /// - Parameter username: 用户名
    /// - Throws: `SSOHelperError`
    /// - Returns: 是否需要验证码
    public func checkNeedCaptcha(username: String) async throws -> Bool {
        let timestamp = Date().millisecondsSince1970
        let response: CheckResponse = try await performDecodableRequest(factory.make(.authServer, "/authserver/checkNeedCaptcha.htl?username=\(username)&_=\(timestamp)"))
        return response.isNeed
    }

    /// 获取验证码
    /// - Throws: `SSOHelperError`
    /// - Returns: 验证码图片数据
    public func getCaptcha() async throws -> Data {
        let response = try await performDataRequest(factory.make(.authServer, "/authserver/getCaptcha.htl"))
        guard !response.isEmpty else {
            throw SSOHelperError.captchaRetrievalFailed
        }
        return response
    }

    /// 登录统一身份认证
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    ///   - captcha: 验证码
    /// - Throws: `SSOHelperError`
    public func login(loginForm: LoginForm, username: String, password: String, captcha: String?) async throws {
        let encryptedPassword = AESUtils.encryptPassword(password: password, salt: loginForm.pwdEncryptSalt)
        let parameters: [String: String] = [
            "username": username,
            "password": encryptedPassword,
            "captcha": captcha ?? "",
            "_eventId": "submit",
            "cllt": "userNameLogin",
            "dllt": "generalLogin",
            "lt": "",
            "execution": loginForm.execution,
        ]
        let response = try await performResponseRequest(
            factory.make(.authServer, "/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin"),
            .post,
            parameters,
            validateLogin: false
        )
        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginFailed("未找到重定向链接")
        }

        try checkNeedImproveUserInfo(response)

        var checkURL: URL = finalURL

        if mode == .webVpn {
            guard finalURL == URL("https://vpn.csust.edu.cn/enclient/") else {
                if let responseString = response.value {
                    let document = try SwiftSoup.parse(responseString)
                    if let errorElement = try document.select("#showErrorTip").first() {
                        throw SSOHelperError.loginFailed("登录失败: \(try errorElement.text())")
                    }
                }
                throw SSOHelperError.loginFailed("登录失败: \(finalURL)")
            }
            let checkResponse = try await performResponseRequest(
                "https://vpn.csust.edu.cn/enclient/api/users/admin/custom/page/login/sso/cas",
                validateLogin: false
            )
            guard let checkFinalURL = checkResponse.response?.url else {
                throw SSOHelperError.loginFailed("登录失败: \(finalURL)")
            }
            checkURL = checkFinalURL
        }

        guard checkURL == URL(factory.make(.ehall, "/index.html")) || finalURL == URL(factory.make(.ehall, "/default/index.html")) else {
            if let responseString = response.value {
                let document = try SwiftSoup.parse(responseString)
                if let errorElement = try document.select("#showErrorTip").first() {
                    throw SSOHelperError.loginFailed("登录失败: \(try errorElement.text())")
                }
            }
            throw SSOHelperError.loginFailed("登录失败: \(finalURL)")
        }
    }

    /// 登出统一身份认证
    public func logout() async throws {
        try await performDataRequest(factory.make(.ehall, "/logout"))
        try await performDataRequest(factory.make(.authServer, "/authserver/logout"))
    }

    /// 获取登录用户信息
    /// - Throws: `SSOHelperError`
    /// - Returns: 用户信息
    public func getLoginUser() async throws -> Profile {
        let response: LoginUserResponse = try await performDecodableRequest(factory.make(.ehall, "/getLoginUser"))
        guard let user = response.data else {
            throw SSOHelperError.notLoggedIn
        }
        return user
    }

    internal override func validateLoginResponse<T>(_ response: T) throws {
        guard let response = response as? DataResponse<String, AFError>,
            let finalURL = response.response?.url
        else {
            return
        }
        guard !finalURL.path.contains("/authserver/login") else {
            throw SSOHelperError.notLoggedIn
        }
    }

    /// 从统一身份认证登录教务系统
    /// - Throws: `SSOHelperError`
    public func loginToEducation() async throws {
        try await performDataRequest(factory.make(.education, "/sso.jsp"))
        let response = try await performResponseRequest(factory.make(.authServer, "/authserver/login?service=http%3A%2F%2Fxk.csust.edu.cn%2Fsso.jsp"))
        guard response.response?.url != nil else {
            throw SSOHelperError.loginToEducationFailed("未找到重定向URL")
        }
    }

    /// 从统一身份认证登录网络课程中心
    /// - Throws: `SSOHelperError`
    public func loginToMooc() async throws {
        let response = try await performResponseRequest(factory.make(.mooc, "/meol/homepage/common/sso_login.jsp"))
        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginToMoocFailed("未找到重定向URL")
        }
        guard finalURL == URL(factory.make(.mooc, "/meol/personal.do")) || finalURL == URL(factory.make(.mooc, "/meol/index.do")) else {
            throw SSOHelperError.loginToMoocFailed("重定向URL异常: \(finalURL)")
        }
    }

    /// 从统一身份认证登录学习通
    /// - Throws: `SSOHelperError`
    public func loginToChaoxing() async throws {
        let response = try await performResponseRequest(factory.make(.authServer, "/authserver/login?service=http%3A%2F%2Ffysso.chaoxing.com%2Fsso%2Fcsust"))
        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginToChaoxingFailed("未找到重定向URL")
        }
        // 登录成功后统一落在学校学习通门户的 /portal 上：
        // 直连是 http://mooc.csust.edu.cn/portal，
        // WebVPN 下则被网关包成 https://vpn.csust.edu.cn/http/webvpn{加密域名}/portal
        guard finalURL.path.hasSuffix("/portal") else {
            throw SSOHelperError.loginToChaoxingFailed("重定向URL异常: \(finalURL)")
        }
    }

    /// 从统一身份认证登录校园卡系统
    /// - Throws: `SSOHelperError`
    /// - Returns: 校园卡登录凭据
    public func loginToCampusCard() async throws -> String {
        let response = try await performResponseRequest(factory.make(.campusCard, "/berserker-auth/cas/login/wisedu?targetUrl=https://hxyxh5.csust.edu.cn/plat/?name=loginTransit"))
        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginToCampusCardFailed("未找到重定向URL")
        }
        guard finalURL.absoluteString.starts(with: factory.make(.campusCard, "/plat")) else {
            throw SSOHelperError.loginToCampusCardFailed("重定向URL异常: \(finalURL)")
        }

        guard let urlComponents = URLComponents(url: finalURL, resolvingAgainstBaseURL: false),
            let queryItems = urlComponents.queryItems,
            let queryItem = queryItems.first(where: { item in item.name == "ticket" }),
            // URLComponents默认会移除一次百分号编码，不过Ticket进行过两次百分号编码，所以这里还需要移除一次
            let ticket = queryItem.value?.removingPercentEncoding
        else {
            throw SSOHelperError.loginToCampusCardFailed("无法获取登录凭据")
        }

        return ticket
    }

    public override func isLoggedIn() async -> Bool {
        return (try? await getLoginUser()) != nil
    }
}
