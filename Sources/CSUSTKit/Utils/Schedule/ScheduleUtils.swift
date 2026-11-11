import Foundation

/// 课表计算工具
public enum ScheduleUtils {
    /// 每节课的上下课时间，下标 0 对应第 1 节
    public static let sectionTimeStrings: [(start: String, end: String)] = [
        ("08:00", "08:45"),
        ("08:55", "09:40"),
        ("10:10", "10:55"),
        ("11:05", "11:50"),
        ("14:00", "14:45"),
        ("14:55", "15:40"),
        ("16:10", "16:55"),
        ("17:05", "17:50"),
        ("19:30", "20:15"),
        ("20:25", "21:10"),
    ]

    /// 学校课表的默认学期总周数，供调用方给 weekCount 兜底
    public static let defaultWeekCount: Int = 20

    /// 课程均以长沙当地时间为准
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }()

    /// 距离开课多少秒以内算即将开始
    private static let upcomingThreshold: TimeInterval = 1200

    /// 距下课多少秒以内算刚刚结束
    private static let recentlyFinishedThreshold: TimeInterval = 300

    // MARK: - 学期与周次

    /// 把按指定日历解析出的日期归一到上海时区下的同一自然日
    /// - Parameters:
    ///   - date: 待归一的日期
    ///   - sourceCalendar: 解析该日期所用的日历，默认设备当前日历
    /// - Returns: 上海时区下同一天的 0 点
    public static func normalizeSemesterStartDate(_ date: Date, sourceCalendar: Calendar = .current) -> Date {
        let components = sourceCalendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    /// 计算学期覆盖的半开区间：从开学日到开学日加 weekCount 周
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - weekCount: 学期总周数
    /// - Returns: 学期开始日与结束日
    public static func semesterDateRange(semesterStartDate: Date, weekCount: Int) -> (startDate: Date, endDate: Date) {
        let startDate = calendar.startOfDay(for: semesterStartDate)
        let endDate = calendar.date(byAdding: .weekOfYear, value: weekCount, to: startDate) ?? startDate
        return (startDate, endDate)
    }

    /// 计算某一周的 7 个日期，从周日开始
    /// - Parameters:
    ///   - week: 第几周，从 1 开始
    ///   - semesterStartDate: 学期开始日期
    /// - Returns: 该周周日到周六的 7 个日期
    public static func dates(ofWeek week: Int, semesterStartDate: Date) -> [Date] {
        let startDate = calendar.startOfDay(for: semesterStartDate)
        guard let firstDay = calendar.date(byAdding: .day, value: (week - 1) * 7, to: startDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDay) }
    }

    /// 把日期换算成星期
    /// - Parameter date: 目标日期
    /// - Returns: 星期
    public static func dayOfWeek(of date: Date) -> DayOfWeek {
        let weekday = calendar.component(.weekday, from: date)
        return DayOfWeek(rawValue: weekday - 1) ?? .sunday
    }

    /// 判断日期处于学期前、学期中还是学期后
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - date: 目标日期
    ///   - weekCount: 学期总周数
    /// - Returns: 学期状态；开学前带上距离开学的天数，学期中带上当前周次
    public static func semesterStatus(semesterStartDate: Date, at date: Date, weekCount: Int) -> SemesterStatus {
        let startDate = calendar.startOfDay(for: semesterStartDate)
        let targetDate = calendar.startOfDay(for: date)
        let endDate = semesterDateRange(semesterStartDate: semesterStartDate, weekCount: weekCount).endDate

        if targetDate < startDate {
            let days = calendar.dateComponents([.day], from: targetDate, to: startDate).day ?? 0
            return .beforeSemester(daysUntilStart: days)
        }
        guard targetDate < endDate else { return .afterSemester }

        let days = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
        return .inSemester(week: days / 7 + 1)
    }

    /// 判断日期是否为今天
    /// - Parameter date: 目标日期
    /// - Returns: 是否为今天
    public static func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }

    // MARK: - 课程

    /// 按周次分组课程
    /// - Parameter courses: 课程列表
    /// - Returns: 周次到课程时段的字典
    public static func weeklyCourses(_ courses: [EduHelper.Course]) -> [Int: [CourseOccurrence]] {
        var result: [Int: [CourseOccurrence]] = [:]
        for course in courses {
            for (index, session) in course.sessions.enumerated() {
                let occurrence = CourseOccurrence(course: course, sessionIndex: index)
                for week in session.weeks {
                    result[week, default: []].append(occurrence)
                }
            }
        }
        return result
    }

    /// 计算某个上课时段在指定周的具体起止时间
    /// - Parameters:
    ///   - session: 上课时段
    ///   - week: 第几周，从 1 开始
    ///   - semesterStartDate: 学期开始日期
    /// - Returns: 开始与结束时间；节次或星期越界时返回 nil
    public static func timeRange(
        of session: EduHelper.ScheduleSession,
        inWeek week: Int,
        semesterStartDate: Date
    ) -> (startDate: Date, endDate: Date)? {
        let dates = dates(ofWeek: week, semesterStartDate: semesterStartDate)
        guard session.dayOfWeek.rawValue < dates.count else { return nil }
        return timeRange(of: session, on: dates[session.dayOfWeek.rawValue])
    }

    /// 计算指定日期要上的课，按开始节次排序
    /// - Parameters:
    ///   - date: 目标日期
    ///   - semesterStartDate: 学期开始日期
    ///   - courses: 课程列表
    ///   - weekCount: 学期总周数
    /// - Returns: 当天的课程时段；不在学期内时返回空数组
    public static func courses(
        on date: Date,
        semesterStartDate: Date,
        courses: [EduHelper.Course],
        weekCount: Int
    ) -> [CourseOccurrence] {
        guard case .inSemester(let week) = semesterStatus(semesterStartDate: semesterStartDate, at: date, weekCount: weekCount)
        else {
            return []
        }
        let weekday = dayOfWeek(of: date)

        return
            courses
            .flatMap { course in
                course.sessions.enumerated().compactMap { index, session -> CourseOccurrence? in
                    guard session.weeks.contains(week), session.dayOfWeek == weekday else { return nil }
                    return CourseOccurrence(course: course, sessionIndex: index)
                }
            }
            .sorted { $0.session.startSection < $1.session.startSection }
    }

    /// 计算指定时刻还没下课的课
    /// - Parameters:
    ///   - now: 当前时刻
    ///   - semesterStartDate: 学期开始日期
    ///   - courses: 课程列表
    ///   - weekCount: 学期总周数
    /// - Returns: 课程时段与是否正在上的数组
    public static func unfinishedCourses(
        at now: Date,
        semesterStartDate: Date,
        courses: [EduHelper.Course],
        weekCount: Int
    ) -> [(occurrence: CourseOccurrence, isCurrent: Bool)] {
        return Self.courses(on: now, semesterStartDate: semesterStartDate, courses: courses, weekCount: weekCount).compactMap {
            occurrence in
            guard let range = timeRange(of: occurrence.session, on: now), now < range.endDate else { return nil }
            return (occurrence, now >= range.startDate)
        }
    }

    /// 选出与当前时刻最相关的一节课
    ///
    /// 依次尝试：正在上的课、20 分钟内即将开始的课、5 分钟内刚下课的课。
    /// - Parameters:
    ///   - now: 当前时刻
    ///   - semesterStartDate: 学期开始日期
    ///   - courses: 课程列表
    ///   - weekCount: 学期总周数
    /// - Returns: 最相关的课程时段；没有则返回 nil
    public static func relevantCourse(
        at now: Date,
        semesterStartDate: Date,
        courses: [EduHelper.Course],
        weekCount: Int
    ) -> CourseOccurrence? {
        var upcoming: (occurrence: CourseOccurrence, interval: TimeInterval)?
        var finished: (occurrence: CourseOccurrence, interval: TimeInterval)?

        for occurrence in Self.courses(on: now, semesterStartDate: semesterStartDate, courses: courses, weekCount: weekCount) {
            guard let range = timeRange(of: occurrence.session, on: now) else { continue }

            if now >= range.startDate && now < range.endDate {
                return occurrence
            }

            if now < range.startDate {
                let interval = range.startDate.timeIntervalSince(now)
                if upcoming == nil || interval < upcoming!.interval {
                    upcoming = (occurrence, interval)
                }
            } else {
                let interval = now.timeIntervalSince(range.endDate)
                if finished == nil || interval < finished!.interval {
                    finished = (occurrence, interval)
                }
            }
        }

        if let upcoming, upcoming.interval <= upcomingThreshold {
            return upcoming.occurrence
        }
        if let finished, finished.interval <= recentlyFinishedThreshold {
            return finished.occurrence
        }
        return nil
    }

    // MARK: - 内部

    /// 计算某个上课时段在指定日期上的起止时间
    private static func timeRange(
        of session: EduHelper.ScheduleSession,
        on date: Date
    ) -> (startDate: Date, endDate: Date)? {
        guard session.startSection >= 1, session.endSection >= session.startSection,
            session.endSection <= sectionTimeStrings.count
        else {
            return nil
        }

        guard let startDate = self.date(on: date, at: sectionTimeStrings[session.startSection - 1].start),
            let endDate = self.date(on: date, at: sectionTimeStrings[session.endSection - 1].end)
        else {
            return nil
        }
        return (startDate, endDate)
    }

    /// 把 HH:mm 设置到指定日期上
    private static func date(on date: Date, at timeString: String) -> Date? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        return calendar.date(bySettingHour: components[0], minute: components[1], second: 0, of: date)
    }
}
