extension EduHelper {
    /// 学期类型
    public enum SemesterType: String, CaseIterable, BaseModel {
        /// 期初
        case beginning = "期初"
        /// 期中
        case middle = "期中"
        /// 期末
        case end = "期末"

        /// 学期类型ID
        var id: String {
            switch self {
            case .beginning:
                return "1"
            case .middle:
                return "2"
            case .end:
                return "3"
            }
        }
    }
}
