import Alamofire
import Foundation

/// 校园卡助手
public class CampusCardHelper: BaseHelper {
    private struct BaseResponse<T: Codable & Sendable>: Codable, Sendable {
        let code: Int
        let success: Bool
        let data: T
        let msg: String
    }

    private var token: String?

    private struct TokenResponse: Codable {
        let accessToken: String
        let tokenType: String
        let refreshToken: String
        let expiresIn: Int
        let scope: String
        let tenantId: String
        let isFirstLogin: Bool
        let flag: String
        let sno: String
        let logintype: String
        let name: String
        let mobile: String
        let id: Int
        let loginFrom: String
        let uuid: String
        let clientId: String
        let isPasswordExpired: Bool
        let jti: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case scope
            case tenantId = "tenant_id"
            case isFirstLogin = "is_first_login"
            case flag
            case sno
            case logintype
            case name
            case mobile
            case id
            case loginFrom
            case uuid
            case clientId = "client_id"
            case isPasswordExpired = "is_password_expired"
            case jti
        }
    }

    public func syncToken(ticket: String) async throws {
        let header = [
            // base64 of magic string mobile_service_platform:mobile_service_platform_secret
            "Authorization": "Basic bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm06bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm1fc2VjcmV0"
        ]
        let parameters = [
            "username": ticket,
            "password": ticket,
            "grant_type": "password",
            "scope": "all",
            "loginFrom": "h5",
            "logintype": "sso",
            "device_token": "h5",
            "synAccessSource": "h5",
        ]
        let response = try await session.request(
            factory.make(.campusCard, "/berserker-auth/oauth/token"),
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: .init(header)
        ).decodable(TokenResponse.self)

        self.token = response.accessToken
    }

    public func getProfile() async throws -> Profile {
        guard let token else {
            throw CampusCardHelperError.profileRetrievalFailed("无令牌")
        }
        let headers = [
            "synjones-auth": "bearer \(token)"
        ]
        let response = try await session.request(factory.make(.campusCard, "/berserker-base/user?synAccessSource=h5"), headers: .init(headers)).decodable(BaseResponse<Profile>.self)
        return response.data
    }
}
