import CSUSTKit
import Foundation
import Testing

struct ScheduleUtilsTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }()

    /// 学期开始日：2026-09-06，周日
    private var semesterStartDate: Date { date(2026, 9, 6) }
    private let weekCount = 20

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    private func makeCourse(
        _ name: String,
        weeks: [Int],
        day: DayOfWeek,
        startSection: Int,
        endSection: Int
    ) -> EduHelper.Course {
        EduHelper.Course(
            courseName: name,
            groupName: nil,
            teacher: nil,
            sessions: [
                EduHelper.ScheduleSession(
                    weeks: weeks,
                    startSection: startSection,
                    endSection: endSection,
                    dayOfWeek: day,
                    classroom: "A101"
                )
            ]
        )
    }

    // MARK: - 学期与周次

    @Test func semesterStatusReportsWeekWithinSemester() {
        #expect(ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2026, 9, 6), weekCount: weekCount) == .inSemester(week: 1))
        #expect(ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2026, 9, 12), weekCount: weekCount) == .inSemester(week: 1))
        #expect(ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2026, 9, 13), weekCount: weekCount) == .inSemester(week: 2))
        #expect(ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2027, 1, 23), weekCount: weekCount) == .inSemester(week: 20))
        #expect(ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2026, 9, 5), weekCount: weekCount) == .beforeSemester(daysUntilStart: 1))
        #expect(ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2027, 1, 24), weekCount: weekCount) == .afterSemester)
    }

    @Test func datesOfWeekStartOnSunday() {
        let dates = ScheduleUtils.dates(ofWeek: 1, semesterStartDate: semesterStartDate)
        #expect(dates.count == 7)
        #expect(ScheduleUtils.dayOfWeek(of: dates[0]) == .sunday)
        #expect(ScheduleUtils.dayOfWeek(of: dates[1]) == .monday)
        #expect(dates[0] == date(2026, 9, 6))

        let secondWeek = ScheduleUtils.dates(ofWeek: 2, semesterStartDate: semesterStartDate)
        #expect(secondWeek[0] == date(2026, 9, 13))
    }

    @Test func dayOfWeekMapsCalendarWeekday() {
        #expect(ScheduleUtils.dayOfWeek(of: date(2026, 9, 6)) == .sunday)
        #expect(ScheduleUtils.dayOfWeek(of: date(2026, 9, 7)) == .monday)
        #expect(ScheduleUtils.dayOfWeek(of: date(2026, 9, 12)) == .saturday)
    }

    @Test func semesterStatusCarriesCountdownBeforeStart() {
        #expect(
            ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2026, 9, 1), weekCount: weekCount)
                == .beforeSemester(daysUntilStart: 5)
        )
        #expect(
            ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2026, 9, 5), weekCount: weekCount)
                == .beforeSemester(daysUntilStart: 1)
        )
        #expect(
            ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2026, 9, 6), weekCount: weekCount)
                == .inSemester(week: 1)
        )
        #expect(
            ScheduleUtils.semesterStatus(semesterStartDate: semesterStartDate, at: date(2027, 1, 24), weekCount: weekCount)
                == .afterSemester
        )
    }

    @Test func semesterDateRangeSpansWeekCount() {
        let range = ScheduleUtils.semesterDateRange(semesterStartDate: semesterStartDate, weekCount: 2)
        #expect(range.startDate == date(2026, 9, 6))
        #expect(range.endDate == date(2026, 9, 20))
    }

    // MARK: - 课程

    @Test func weeklyCoursesGroupedByWeek() {
        let courses = [makeCourse("高数", weeks: [1, 2, 3], day: .monday, startSection: 1, endSection: 2)]
        let weekly = ScheduleUtils.weeklyCourses(courses)
        #expect(weekly.keys.sorted() == [1, 2, 3])
        #expect(weekly[2]?.first?.course.courseName == "高数")
    }

    @Test func coursesOnDateFiltersByWeekAndDay() {
        let courses = [
            makeCourse("高数", weeks: [1, 2], day: .monday, startSection: 1, endSection: 2),
            makeCourse("英语", weeks: [3], day: .monday, startSection: 3, endSection: 4),
        ]

        let firstWeekMonday = ScheduleUtils.courses(
            on: date(2026, 9, 7),
            semesterStartDate: semesterStartDate,
            courses: courses,
            weekCount: weekCount
        )
        #expect(firstWeekMonday.map(\.course.courseName) == ["高数"])

        let thirdWeekMonday = ScheduleUtils.courses(
            on: date(2026, 9, 21),
            semesterStartDate: semesterStartDate,
            courses: courses,
            weekCount: weekCount
        )
        #expect(thirdWeekMonday.map(\.course.courseName) == ["英语"])

        #expect(
            ScheduleUtils.courses(on: date(2026, 9, 8), semesterStartDate: semesterStartDate, courses: courses, weekCount: weekCount)
                .isEmpty
        )
        #expect(
            ScheduleUtils.courses(on: date(2026, 9, 5), semesterStartDate: semesterStartDate, courses: courses, weekCount: weekCount)
                .isEmpty
        )
    }

    @Test func timeRangeMapsSectionsToClock() throws {
        let course = makeCourse("高数", weeks: [1], day: .monday, startSection: 3, endSection: 4)
        let session = try #require(course.sessions.first)

        let range = try #require(
            ScheduleUtils.timeRange(of: session, inWeek: 1, semesterStartDate: semesterStartDate)
        )
        #expect(range.startDate == date(2026, 9, 7, 10, 10))
        #expect(range.endDate == date(2026, 9, 7, 11, 50))
    }

    @Test func timeRangeRejectsOutOfBoundsSections() {
        let invalid = EduHelper.ScheduleSession(
            weeks: [1],
            startSection: 11,
            endSection: 12,
            dayOfWeek: .monday,
            classroom: nil
        )
        #expect(ScheduleUtils.timeRange(of: invalid, inWeek: 1, semesterStartDate: semesterStartDate) == nil)

        let reversed = EduHelper.ScheduleSession(
            weeks: [1],
            startSection: 5,
            endSection: 3,
            dayOfWeek: .monday,
            classroom: nil
        )
        #expect(ScheduleUtils.timeRange(of: reversed, inWeek: 1, semesterStartDate: semesterStartDate) == nil)
    }

    @Test func unfinishedCoursesIgnoreFinishedOnes() {
        let courses = [makeCourse("高数", weeks: [1], day: .monday, startSection: 1, endSection: 2)]

        let beforeClass = ScheduleUtils.unfinishedCourses(
            at: date(2026, 9, 7, 7, 0),
            semesterStartDate: semesterStartDate,
            courses: courses,
            weekCount: weekCount
        )
        #expect(beforeClass.count == 1)
        #expect(beforeClass.first?.isCurrent == false)

        let inClass = ScheduleUtils.unfinishedCourses(
            at: date(2026, 9, 7, 9, 0),
            semesterStartDate: semesterStartDate,
            courses: courses,
            weekCount: weekCount
        )
        #expect(inClass.first?.isCurrent == true)

        let afterClass = ScheduleUtils.unfinishedCourses(
            at: date(2026, 9, 7, 9, 45),
            semesterStartDate: semesterStartDate,
            courses: courses,
            weekCount: weekCount
        )
        #expect(afterClass.isEmpty)
    }

    @Test func relevantCourseFollowsPriorityOrder() {
        let courses = [makeCourse("高数", weeks: [1], day: .monday, startSection: 1, endSection: 2)]

        #expect(
            ScheduleUtils.relevantCourse(
                at: date(2026, 9, 7, 8, 30),
                semesterStartDate: semesterStartDate,
                courses: courses,
                weekCount: weekCount
            ) != nil
        )
        #expect(
            ScheduleUtils.relevantCourse(
                at: date(2026, 9, 7, 7, 50),
                semesterStartDate: semesterStartDate,
                courses: courses,
                weekCount: weekCount
            ) != nil
        )
        #expect(
            ScheduleUtils.relevantCourse(
                at: date(2026, 9, 7, 7, 35),
                semesterStartDate: semesterStartDate,
                courses: courses,
                weekCount: weekCount
            ) == nil
        )
        #expect(
            ScheduleUtils.relevantCourse(
                at: date(2026, 9, 7, 9, 42),
                semesterStartDate: semesterStartDate,
                courses: courses,
                weekCount: weekCount
            ) != nil
        )
        #expect(
            ScheduleUtils.relevantCourse(
                at: date(2026, 9, 7, 9, 50),
                semesterStartDate: semesterStartDate,
                courses: courses,
                weekCount: weekCount
            ) == nil
        )
    }

    // MARK: - 边界

    @Test func normalizeSemesterStartDateUsesSourceCalendarDay() {
        var deviceCalendar = Calendar(identifier: .gregorian)
        deviceCalendar.timeZone = TimeZone(identifier: "America/New_York")!

        let morning = deviceCalendar.date(from: DateComponents(year: 2026, month: 9, day: 6, hour: 9))!
        #expect(ScheduleUtils.normalizeSemesterStartDate(morning, sourceCalendar: deviceCalendar) == date(2026, 9, 6))

        // 纽约 2026-09-06 21:00（此时上海已是 09-07 09:00）仍按纽约日历取 09-06
        let night = deviceCalendar.date(from: DateComponents(year: 2026, month: 9, day: 6, hour: 21))!
        #expect(ScheduleUtils.normalizeSemesterStartDate(night, sourceCalendar: deviceCalendar) == date(2026, 9, 6))
    }

    @Test func isTodayRecognisesCurrentMoment() {
        #expect(ScheduleUtils.isToday(Date()))
        #expect(ScheduleUtils.isToday(date(2000, 1, 1)) == false)
    }

    @Test func coursesOnSameDayAreSortedByStartSection() {
        let courses = [
            makeCourse("下午课", weeks: [1], day: .monday, startSection: 5, endSection: 6),
            makeCourse("上午课", weeks: [1], day: .monday, startSection: 1, endSection: 2),
        ]
        let result = ScheduleUtils.courses(
            on: date(2026, 9, 7),
            semesterStartDate: semesterStartDate,
            courses: courses,
            weekCount: weekCount
        )
        #expect(result.map(\.course.courseName) == ["上午课", "下午课"])
    }

    @Test func unfinishedCoursesSkipOutOfBoundsSections() {
        let courses = [makeCourse("坏数据", weeks: [1], day: .monday, startSection: 11, endSection: 12)]
        #expect(
            ScheduleUtils.unfinishedCourses(
                at: date(2026, 9, 7, 9, 0),
                semesterStartDate: semesterStartDate,
                courses: courses,
                weekCount: weekCount
            ).isEmpty
        )
    }

    @Test func relevantCoursePicksNearestUpcoming() {
        let courses = [
            makeCourse("早课", weeks: [1], day: .monday, startSection: 1, endSection: 2),
            makeCourse("午课", weeks: [1], day: .monday, startSection: 5, endSection: 6),
        ]
        let result = ScheduleUtils.relevantCourse(
            at: date(2026, 9, 7, 7, 45),
            semesterStartDate: semesterStartDate,
            courses: courses,
            weekCount: weekCount
        )
        #expect(result?.course.courseName == "早课")
    }

    @Test func relevantCoursePicksMostRecentlyFinished() {
        let courses = [
            makeCourse("早课", weeks: [1], day: .monday, startSection: 1, endSection: 2),
            makeCourse("晚课", weeks: [1], day: .monday, startSection: 3, endSection: 4),
        ]
        let result = ScheduleUtils.relevantCourse(
            at: date(2026, 9, 7, 11, 52),
            semesterStartDate: semesterStartDate,
            courses: courses,
            weekCount: weekCount
        )
        #expect(result?.course.courseName == "晚课")
    }

    @Test func relevantCourseSkipsOutOfBoundsSections() {
        let courses = [makeCourse("坏数据", weeks: [1], day: .monday, startSection: 11, endSection: 12)]
        #expect(
            ScheduleUtils.relevantCourse(
                at: date(2026, 9, 7, 9, 0),
                semesterStartDate: semesterStartDate,
                courses: courses,
                weekCount: weekCount
            ) == nil
        )
    }
}
