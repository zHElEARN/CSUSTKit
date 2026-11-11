import Foundation

/// 学期状态
public enum SemesterStatus: Equatable, Sendable {
    /// 还没开学，附带距离开学的天数
    case beforeSemester(daysUntilStart: Int)
    /// 学期进行中，附带当前是第几周
    case inSemester(week: Int)
    /// 学期已结束
    case afterSemester
}
