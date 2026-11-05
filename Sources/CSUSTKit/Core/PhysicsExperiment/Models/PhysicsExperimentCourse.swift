import Foundation

extension PhysicsExperimentHelper {
    /// 物理实验课程信息
    public struct Course: BaseModel {
        /// 项目编号
        public let id: Int
        /// 项目名称
        public let name: String
        /// 批次
        public let batch: String
        /// 教师
        public let teacher: String
        /// 上课地址
        public let location: String
        /// 上课开始时间
        public let startTime: Date
        /// 上课结束时间
        public let endTime: Date
        /// 课时
        public let classHours: Int
        /// 周次
        public let week: Int
        /// 每周日期
        public let dayOfWeek: DayOfWeek

        public init(
            id: Int,
            name: String,
            batch: String,
            teacher: String,
            location: String,
            startTime: Date,
            endTime: Date,
            classHours: Int,
            week: Int,
            dayOfWeek: DayOfWeek
        ) {
            self.id = id
            self.name = name
            self.batch = batch
            self.teacher = teacher
            self.location = location
            self.startTime = startTime
            self.endTime = endTime
            self.classHours = classHours
            self.week = week
            self.dayOfWeek = dayOfWeek
        }
    }
}
