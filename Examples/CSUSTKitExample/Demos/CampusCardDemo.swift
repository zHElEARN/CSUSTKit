import CSUSTKit

func runCampusCardMenu(using campusCardHelper: CampusCardHelper, ticket: String) async {
    do {
        try await campusCardHelper.syncToken(ticket: ticket)
    } catch {
        print("无法获取token: \(error)")
        return
    }
    while true {
        print("")
        print("=== 宿舍电量查询 ===")
        print("1. 获取用户信息")
        print("2. 查询电量")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            await handleAsyncOperation {
                print(try await campusCardHelper.getProfile())
            }
        case "2":
            await handleAsyncOperation {
                let campus = promptCampus()
                let buildings = try await campusCardHelper.getBuildings(campus: campus).sorted { $0.name < $1.name }
                guard let building = selectIndexedItem(title: "\(campus.displayName) 楼栋列表", items: buildings, display: { $0.name }) else {
                    return
                }
                let rooms = try await campusCardHelper.getRooms(building: building).sorted { $0.name < $1.name }
                guard let room = selectIndexedItem(title: "\(building.name) 宿舍列表", items: rooms, display: { $0.name }) else {
                    return
                }
                let electricity = try await campusCardHelper.getElectricity(room: room)
                print("")
                print("查询结果:")
                print("校区: \(campus.displayName)")
                print("楼栋: \(building.name)")
                print("宿舍号: \(room)")
                print("剩余电量: \(formatElectricity(electricity)) 度")
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}

func promptCampus() -> CampusCardHelper.Campus {
    let campus: CampusCardHelper.Campus = promptSelection(
        title: "请选择校区",
        options: [("1", "云塘"), ("2", "金盆岭")],
        mapper: { input in
            switch input {
            case "1":
                return .yuntang
            case "2":
                return .jinpenling
            default:
                return nil
            }
        }
    )
    return campus
}
