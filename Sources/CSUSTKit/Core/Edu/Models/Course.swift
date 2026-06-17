extension EduHelper {
    /// 课表课程信息
    public struct Course: BaseModel {
        /// 课程名称
        public let courseName: String
        /// 课程分组名称
        public let groupName: String?
        /// 授课教师
        public let teacher: String?
        /// 上课时间
        public var sessions: [ScheduleSession]

        public init(
            courseName: String,
            groupName: String?,
            teacher: String?,
            sessions: [ScheduleSession]
        ) {
            self.courseName = courseName
            self.groupName = groupName
            self.teacher = teacher
            self.sessions = sessions
        }
    }
}
