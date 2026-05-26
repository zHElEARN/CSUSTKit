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

    private struct GetDynamicCodeResponse: Decodable {
        let code: String
        let message: String
        let mobile: String?
        let intervalTime: Int?
        let time: Int?
    }

    // MARK: - Methods

    /// 获取登录表单
    /// - Throws: `SSOHelperError`
    /// - Returns: 登录表单数据
    public func getLoginForm() async throws -> LoginForm {
        let response = await session.request(factory.make(.authServer, "/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin")).stringResponse()
        // 已经登录
        guard response.response?.url != URL(factory.make(.ehall, "/index.html")) else {
            throw SSOHelperError.getLoginFormFailed("账号已登录")
        }
        guard let value = response.value else {
            throw SSOHelperError.getLoginFormFailed("无响应数据")
        }
        let document = try SwiftSoup.parse(value)
        guard let pwdEncryptSaltInput = try document.select("input#pwdEncryptSalt").first() else {
            throw SSOHelperError.getLoginFormFailed("未找到pwdEncryptSalt输入框")
        }
        guard let executionInput = try document.select("input#execution").first() else {
            throw SSOHelperError.getLoginFormFailed("未找到execution输入框")
        }
        return LoginForm(pwdEncryptSalt: try pwdEncryptSaltInput.attr("value"), execution: try executionInput.attr("value"))
    }

    /// 检查是否需要验证码
    /// - Parameter username: 用户名
    /// - Throws: `SSOHelperError`
    /// - Returns: 是否需要验证码
    public func checkNeedCaptcha(username: String) async throws -> Bool {
        let timestamp = Date().millisecondsSince1970
        let response = try await session.request(factory.make(.authServer, "/authserver/checkNeedCaptcha.htl?username=\(username)&_=\(timestamp)")).decodable(CheckResponse.self)
        return response.isNeed
    }

    /// 获取验证码
    /// - Throws: `SSOHelperError`
    /// - Returns: 验证码图片数据
    public func getCaptcha() async throws -> Data {
        let response = try await session.request(factory.make(.authServer, "/authserver/getCaptcha.htl")).data()
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
        let response = await session.post(factory.make(.authServer, "/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin"), parameters).stringResponse()
        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginFailed("未找到重定向链接")
        }

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
            let checkResponse = await session.request("https://vpn.csust.edu.cn/enclient/api/users/admin/custom/page/login/sso/cas").stringResponse()
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
        try await session.request(factory.make(.ehall, "/logout")).data()
        try await session.request(factory.make(.authServer, "/authserver/logout")).data()
    }

    /// 获取登录用户信息
    /// - Throws: `SSOHelperError`
    /// - Returns: 用户信息
    public func getLoginUser() async throws -> Profile {
        let response = try await session.request(factory.make(.ehall, "/getLoginUser")).decodable(LoginUserResponse.self)
        guard let user = response.data else {
            throw SSOHelperError.notLoggedIn
        }
        return user
    }

    /// 从统一身份认证登录教务系统
    /// - Throws: `SSOHelperError`
    /// - Returns: 教务系统的会话信息
    @discardableResult
    public func loginToEducation() async throws -> Session {
        try await session.request(factory.make(.education, "/sso.jsp")).data()
        let response = try await session.request(factory.make(.authServer, "/authserver/login?service=http%3A%2F%2Fxk.csust.edu.cn%2Fsso.jsp")).string()
        guard !response.contains("账号登录") else {
            throw SSOHelperError.notLoggedIn
        }
        return session
    }

    /// 从统一身份认证登录网络课程中心
    /// - Throws: `SSOHelperError`
    /// - Returns: 网络课程中心的会话信息
    @discardableResult
    public func loginToMooc() async throws -> Session {
        let request = session.request(factory.make(.mooc, "/meol/homepage/common/sso_login.jsp"))
        let response = await request.stringResponse()
        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginToMoocFailed("未找到重定向URL")
        }
        guard !finalURL.path.contains("/authserver/login") else {
            throw SSOHelperError.notLoggedIn
        }
        guard finalURL == URL(factory.make(.mooc, "/meol/personal.do")) || finalURL == URL(factory.make(.mooc, "/meol/index.do")) else {
            throw SSOHelperError.loginToMoocFailed("重定向URL异常: \(finalURL)")
        }
        return session
    }

    public override func isLoggedIn() async -> Bool {
        return (try? await getLoginUser()) != nil
    }
}
