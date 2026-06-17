extension EduHelper {
    /// 上课时间
    public struct ScheduleSession: BaseModel {
        /// 课程周次
        public let weeks: [Int]
        /// 课程开始节次
        public let startSection: Int
        /// 课程结束节次
        public let endSection: Int
        //// 每周日期
        public let dayOfWeek: DayOfWeek
        /// 上课教室
        public let classroom: String?

        public init(
            weeks: [Int],
            startSection: Int,
            endSection: Int,
            dayOfWeek: DayOfWeek,
            classroom: String?
        ) {
            self.weeks = weeks
            self.startSection = startSection
            self.endSection = endSection
            self.dayOfWeek = dayOfWeek
            self.classroom = classroom
        }
    }
}
