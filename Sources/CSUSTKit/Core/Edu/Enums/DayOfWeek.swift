extension EduHelper {
    /// 每周的日期
    public enum DayOfWeek: Int, CaseIterable, BaseModel {
        /// 星期日
        case sunday = 0
        /// 星期一
        case monday
        /// 星期二
        case tuesday
        /// 星期三
        case wednesday
        /// 星期四
        case thursday
        /// 星期五
        case friday
        /// 星期六
        case saturday
    }
}
