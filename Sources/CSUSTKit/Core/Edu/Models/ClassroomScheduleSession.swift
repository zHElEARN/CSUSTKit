extension EduHelper {
    /// 教室课表中的一条排课记录
    public struct ClassroomScheduleSession: BaseModel {
        /// 上课教室
        public let classroom: String
        /// 星期
        public let dayOfWeek: DayOfWeek
        /// 所在课表格覆盖的起始小节
        public let startSection: Int
        /// 所在课表格覆盖的结束小节，包含该节
        public let endSection: Int
        /// 排课周次，按升序排列
        public let weeks: [Int]
        /// 页面显示的课程标签，可能同时包含课名和教师信息
        public let courseLabel: String

        public init(classroom: String, dayOfWeek: DayOfWeek, startSection: Int, endSection: Int, weeks: [Int], courseLabel: String) {
            self.classroom = classroom
            self.dayOfWeek = dayOfWeek
            self.startSection = startSection
            self.endSection = endSection
            self.weeks = weeks
            self.courseLabel = courseLabel
        }
    }
}
