import Foundation

/// 一节课：某门课的一个上课时段
public struct CourseOccurrence: BaseModel {
    /// 课程
    public let course: EduHelper.Course
    /// 该时段在课程 sessions 中的下标
    public let sessionIndex: Int

    internal init(course: EduHelper.Course, sessionIndex: Int) {
        self.course = course
        self.sessionIndex = sessionIndex
    }

    /// 上课时段
    public var session: EduHelper.ScheduleSession {
        return course.sessions[sessionIndex]
    }
}
