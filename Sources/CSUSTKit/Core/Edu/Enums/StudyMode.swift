extension EduHelper {
    /// 修读方式
    public enum StudyMode: String, CaseIterable, BaseModel {
        /// 主修
        case major = "主修"
        /// 辅修
        case minor = "辅修"
        /// 全部
        case all = "全部"

        /// 修读方式ID
        var id: String {
            switch self {
            case .major:
                return "0"
            case .minor:
                return "1"
            case .all:
                return "2"
            }
        }
    }
}
