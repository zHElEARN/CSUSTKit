/// 每周的日期。周日为0，周六为6
public enum DayOfWeek: Int, Sendable, CaseIterable, Codable {
    case sunday = 0
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}
