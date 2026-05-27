import Alamofire
import Foundation

/// 校园卡助手
public class CampusCardHelper: BaseHelper {
    // 身份令牌
    private(set) var token: String?

    public override func isLoggedIn() async -> Bool {
        return (try? await getProfile()) != nil
    }

    private struct BaseResponse<T: Codable & Sendable>: Codable, Sendable {
        let code: Int
        let success: Bool?
        let data: T?
        let msg: String?
        // 错误时字段为message
        let message: String?
    }

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

    /// 获取个人信息
    /// - Throws: `CampusCardHelperError`
    /// - Returns: 个人信息
    public func getProfile() async throws -> Profile {
        guard let token else {
            throw CampusCardHelperError.notLoggedIn
        }
        let headers = [
            "synjones-auth": "bearer \(token)"
        ]
        let response = try await session.request(factory.make(.campusCard, "/berserker-base/user?synAccessSource=h5"), headers: .init(headers)).decodable(BaseResponse<Profile>.self)

        guard response.code != 401 else {
            throw CampusCardHelperError.notLoggedIn
        }
        guard let data = response.data else {
            throw CampusCardHelperError.profileRetrievalFailed("获取个人信息失败: \(response.message ?? "nil")")
        }
        return data
    }

    private struct BaseQueryResponse<T: Codable & Sendable>: Codable, Sendable {
        struct MapContainer<U: Codable & Sendable>: Codable {
            let data: U
        }
        let msg: String?
        // 错误时字段为message
        let message: String?
        let code: Int
        let map: MapContainer<T>?
    }

    private struct BuildingItem: Codable, Sendable {
        let name: String
        let value: String
    }

    private typealias RoomItem = BuildingItem

    struct RoomPowerInfo: Codable, Sendable {
        let roomId: String
        let allAmp: String
        let xiaoquId: String
        let usedAmp: String
        let loudongId: String

        enum CodingKeys: String, CodingKey {
            case roomId = "room_id"
            case allAmp
            case xiaoquId = "xiaoqu_id"
            case usedAmp
            case loudongId = "loudong_id"
        }
    }

    /// 获取楼栋列表
    /// - Parameter campus: 校区
    /// - Throws: `CampusCardHelperError`
    /// - Returns: 楼栋列表
    public func getBuildings(campus: Campus) async throws -> [Building] {
        guard let token else {
            throw CampusCardHelperError.notLoggedIn
        }
        let headers = [
            // base64 of magic string charge:charge_secret
            "Authorization": "Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=",
            "synjones-auth": "bearer \(token)",
        ]
        let parameters = [
            "feeitemid": campus.feeItemID,
            "type": "select",
            "level": "1",
            "xiaoqu_id": campus.campusID,
        ]
        let response = try await session.request(
            factory.make(.campusCard, "/charge/feeitem/getThirdData"),
            method: .post,
            parameters: parameters,
            headers: .init(headers)
        )
        .decodable(BaseQueryResponse<[BuildingItem]>.self)

        guard response.code != 401 else {
            throw CampusCardHelperError.notLoggedIn
        }
        guard let map = response.map else {
            throw CampusCardHelperError.buildingsRetrievalFailed("获取楼栋列表失败: \(response.message ?? "nil")")
        }

        return map.data.map { item in
            Building(name: item.name, id: item.value, campus: campus)
        }
    }

    /// 获取宿舍列表
    /// - Parameter building: 楼栋
    /// - Throws: `CampusCardHelperError`
    /// - Returns: 宿舍列表
    public func getRooms(building: Building) async throws -> [Room] {
        guard let token else {
            throw CampusCardHelperError.notLoggedIn
        }
        let headers = [
            "Authorization": "Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=",
            "synjones-auth": "bearer \(token)",
        ]
        let parameters = [
            "feeitemid": building.campus.feeItemID,
            "type": "select",
            "level": "2",
            "xiaoqu_id": building.campus.campusID,
            "loudong_id": building.id,
        ]
        let response = try await session.request(
            factory.make(.campusCard, "/charge/feeitem/getThirdData"),
            method: .post,
            parameters: parameters,
            headers: .init(headers)
        )
        .decodable(BaseQueryResponse<[RoomItem]>.self)

        guard response.code != 401 else {
            throw CampusCardHelperError.notLoggedIn
        }
        guard let map = response.map else {
            throw CampusCardHelperError.roomsRetrievalFailed("获取宿舍列表失败: \(response.message ?? "nil")")
        }

        return map.data.map { item in
            Room(name: item.name, id: item.value, building: building)
        }
    }

    /// 获取宿舍电量
    /// - Parameter room: 宿舍
    /// - Throws: `CampusCardHelperError`
    /// - Returns: 宿舍电量
    public func getElectricity(room: Room) async throws -> Double {
        guard let token else {
            throw CampusCardHelperError.electricityRetrievalFailed("无令牌")
        }
        let headers = [
            "Authorization": "Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=",
            "synjones-auth": "bearer \(token)",
        ]
        let parameters = [
            "feeitemid": room.building.campus.feeItemID,
            "type": "IEC",
            "level": "3",
            "xiaoqu_id": room.building.campus.campusID,
            "loudong_id": room.building.id,
            "room_id": room.id,
        ]
        let response = try await session.request(
            factory.make(.campusCard, "/charge/feeitem/getThirdData"),
            method: .post,
            parameters: parameters,
            headers: .init(headers)
        )
        .decodable(BaseQueryResponse<RoomPowerInfo>.self)

        guard response.code != 401 else {
            throw CampusCardHelperError.notLoggedIn
        }
        guard let map = response.map else {
            throw CampusCardHelperError.electricityRetrievalFailed("获取宿舍电量失败: \(response.message ?? "nil")")
        }

        guard let allValue = Double(map.data.allAmp), let usedValue = Double(map.data.usedAmp) else {
            throw CampusCardHelperError.electricityRetrievalFailed("无法解析电量")
        }

        return allValue - usedValue
    }

    /// 登出
    public func logout() async throws {
        try await session.request(factory.make(.campusCard, "/berserker-base/redirect?type=logout&synjones-auth=\(token ?? "")&loginFrom=h5&synAccessSource=h5")).data()
        // 以防万一
        token = nil
    }
}
