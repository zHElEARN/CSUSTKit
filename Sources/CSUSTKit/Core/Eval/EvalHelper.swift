public class EvalHelper: BaseHelper {
    public var token: String?

    public override func isLoggedIn() async -> Bool {
        return true
    }

    private struct BaseResponse<T: Codable & Sendable>: Codable, Sendable {
        let code: Int
        let message: String
        let data: T?
    }

    private struct TokenResponse: Codable {
        let accessToken: String
    }

    private struct ProfileResponse: Codable {
        struct Wrapper: Codable {
            let userid: Int
            let loginname: String
            let realname: String
        }
        let data: Wrapper
    }

    public func syncToken(ticket: String) async throws {
        let response = try await session.request(
            factory.make(.eval, "/api/manage/cas/doLogin?userToken=\(ticket)"),
            method: .post
        )
        .decodable(BaseResponse<TokenResponse>.self)

        guard response.code == 200,
            let data = response.data
        else {
            throw EvalHelperError.syncTokenFailed(response.message)
        }

        self.token = data.accessToken
    }

    public func getProfile() async throws -> Profile {
        guard let token else {
            throw EvalHelperError.notLoggedIn
        }

        let headers = [
            "Authorization": "Bearer\(token)"
        ]

        let response = try await session.request(
            factory.make(.eval, "/api/manage/common/getCurrenUser"),
            headers: .init(headers)
        )
        .decodable(BaseResponse<ProfileResponse>.self)

        guard response.code == 0,
            let data = response.data
        else {
            throw EvalHelperError.profileRetrievalFailed(response.message)
        }

        return Profile(userId: data.data.userid, loginName: data.data.loginname, realName: data.data.realname)
    }
}
