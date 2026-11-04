import Alamofire
import Foundation

/// 带业务状态码的响应
private protocol CodedResponse {
    var code: Int { get }
}

/// 校园卡助手
public class CampusCardHelper: BaseHelper {
    // 身份令牌
    public var token: String?

    public override func isLoggedIn() async -> Bool {
        return (try? await getProfile()) != nil
    }

    internal override func validateLoginResponse<T>(_ response: T) throws {
        if let payload = response as? any CodedResponse, payload.code == 401 {
            throw CampusCardHelperError.notLoggedIn
        }
    }

    private struct BaseResponse<T: Codable & Sendable>: Codable, Sendable, CodedResponse {
        let code: Int
        let data: T?
        // 错误时字段为message
        let message: String?
    }

    private struct TokenResponse: Codable {
        let accessToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
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
        let response: TokenResponse = try await performDecodableRequest(
            factory.make(.campusCard, "/berserker-auth/oauth/token"),
            .post,
            parameters,
            headers: .init(header)
        )

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
        let response: BaseResponse<Profile> = try await performDecodableRequest(
            factory.make(.campusCard, "/berserker-base/user?synAccessSource=h5"),
            headers: .init(headers)
        )

        guard let data = response.data else {
            throw CampusCardHelperError.profileRetrievalFailed("获取个人信息失败: \(response.message ?? "nil")")
        }
        return data
    }

    private struct BaseQueryResponse<T: Codable & Sendable>: Codable, Sendable, CodedResponse {
        struct MapContainer<U: Codable & Sendable>: Codable {
            let data: U
        }
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
        let allAmp: String
        let usedAmp: String
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
        let response: BaseQueryResponse<[BuildingItem]> = try await performDecodableRequest(
            factory.make(.campusCard, "/charge/feeitem/getThirdData"),
            .post,
            parameters,
            headers: .init(headers)
        )

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
        let response: BaseQueryResponse<[RoomItem]> = try await performDecodableRequest(
            factory.make(.campusCard, "/charge/feeitem/getThirdData"),
            .post,
            parameters,
            headers: .init(headers)
        )

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
            throw CampusCardHelperError.notLoggedIn
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
        let response: BaseQueryResponse<RoomPowerInfo> = try await performDecodableRequest(
            factory.make(.campusCard, "/charge/feeitem/getThirdData"),
            .post,
            parameters,
            headers: .init(headers)
        )

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
        try await performDataRequest(factory.make(.campusCard, "/berserker-base/redirect?type=logout&synjones-auth=\(token ?? "")&loginFrom=h5&synAccessSource=h5"))
        // 以防万一
        token = nil
    }
}
