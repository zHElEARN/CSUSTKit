extension EduHelper {
    /// 显示模式
    public enum DisplayMode: String, CaseIterable, BaseModel {
        /// 显示最好成绩
        case bestGrade = "显示最好成绩"
        /// 显示全部成绩
        case allGrades = "显示全部成绩"

        /// 显示模式ID
        var id: String {
            switch self {
            case .bestGrade:
                return "max"
            case .allGrades:
                return "all"
            }
        }
    }
}
