import Foundation

extension EduHelper {
    /// 考试信息
    public struct Exam: BaseModel {
        /// 校区
        public let campus: String
        /// 考试场次
        public let session: String
        /// 课程编号
        public let courseID: String
        /// 课程名称
        public let courseName: String
        /// 授课教师
        public let teacher: String
        /// 考试时间
        public let examTime: String
        /// 考试开始时间
        public let examStartTime: Date
        /// 考试结束时间
        public let examEndTime: Date
        /// 考场
        public let examRoom: String
        /// 座位号
        public let seatNumber: String
        /// 准考证号
        public let admissionTicketNumber: String
        /// 备注
        public let remarks: String

        public init(
            campus: String,
            session: String,
            courseID: String,
            courseName: String,
            teacher: String,
            examTime: String,
            examStartTime: Date,
            examEndTime: Date,
            examRoom: String,
            seatNumber: String,
            admissionTicketNumber: String,
            remarks: String
        ) {
            self.campus = campus
            self.session = session
            self.courseID = courseID
            self.courseName = courseName
            self.teacher = teacher
            self.examTime = examTime
            self.examStartTime = examStartTime
            self.examEndTime = examEndTime
            self.examRoom = examRoom
            self.seatNumber = seatNumber
            self.admissionTicketNumber = admissionTicketNumber
            self.remarks = remarks
        }
    }
}
