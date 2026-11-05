/// 校园卡系统专用参数
extension Campus {
    // parameter feeitemid
    internal var feeItemID: String {
        switch self {
        case .jinpenling:
            return "468"
        case .yuntang:
            return "448"
        }
    }

    // parameter xiaoqu_id
    internal var campusID: String {
        switch self {
        case .jinpenling:
            return "22"
        case .yuntang:
            return "1"
        }
    }
}
