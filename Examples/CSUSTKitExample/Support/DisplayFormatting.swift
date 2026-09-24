import CSUSTKit
import Foundation

struct ClassroomQuery {
    let campus: CampusCardHelper.Campus
    let week: Int
    let dayOfWeek: EduHelper.DayOfWeek
    let section: Int
}

func printMoocCourses(_ courses: [MoocHelper.Course]) {
    guard !courses.isEmpty else {
        print("暂无课程数据。")
        return
    }

    print("")
    print("课程列表:")
    for (index, course) in courses.enumerated() {
        let number = course.number?.isEmpty == false ? course.number! : "无编号"
        let teacher = course.teacher?.isEmpty == false ? course.teacher! : "未知教师"
        let department = course.department?.isEmpty == false ? course.department! : "未知院系"
        print("\(index + 1). \(course.name)")
        print("   编号: \(number) | 教师: \(teacher) | 院系: \(department)")
    }
}

func printAssignments(_ assignments: [MoocHelper.Assignment], for course: MoocHelper.Course) {
    guard !assignments.isEmpty else {
        print("\(course.name) 暂无作业数据。")
        return
    }

    print("")
    print("\(course.name) 的作业:")
    for (index, assignment) in assignments.enumerated() {
        print("\(index + 1). \(assignment.title)")
        print("   发布人: \(assignment.publisher)")
        print("   开始时间: \(displayDate(assignment.startTime))")
        print("   截止时间: \(displayDate(assignment.deadline))")
        let canSubmitText = assignment.canSubmit ? "是" : "否"
        let submitStatusText = assignment.submitStatus ? "是" : "否"
        print("   可提交: \(canSubmitText) | 已提交: \(submitStatusText)")
    }
}

func printMoocExams(_ exams: [MoocHelper.Exam], for course: MoocHelper.Course) {
    guard !exams.isEmpty else {
        print("\(course.name) 暂无测验数据。")
        return
    }

    print("")
    print("\(course.name) 的测验:")
    for (index, exam) in exams.enumerated() {
        let retakeText = exam.allowRetake.map(String.init) ?? "不限制"
        print("\(index + 1). \(exam.title)")
        print("   开始时间: \(exam.startTime)")
        print("   截止时间: \(exam.endTime)")
        let submittedText = exam.isSubmitted ? "是" : "否"
        print("   限时: \(exam.timeLimit) 分钟 | 可重考次数: \(retakeText) | 已交卷: \(submittedText)")
    }
}

func printChaoxingAssignments(_ assignments: [ChaoxingHelper.Assignment]) {
    guard !assignments.isEmpty else {
        print("暂无作业数据。")
        return
    }

    print("")
    print("作业列表（共 \(assignments.count) 条）:")
    for (index, assignment) in assignments.enumerated() {
        print("")
        print("\(index + 1). \(assignment.title)")
        print("   状态: \(assignment.isCompleted ? "已完成" : "未提交")")
        print("   课程: \(assignment.courseName)")
        print("   截止: \(assignment.deadline.map { displayDate($0) } ?? "（无截止时间）")")
        print("   图标: \(assignment.iconURL)")
        print("   详情: \(assignment.detailURL)")
    }
}

func printEducationExams(_ exams: [EduHelper.Exam]) {
    guard !exams.isEmpty else {
        print("暂无考试安排。")
        return
    }

    print("")
    print("考试安排:")
    for (index, exam) in exams.enumerated() {
        print("\(index + 1). \(exam.courseName) [\(exam.courseID)]")
        print("   时间: \(exam.examTime)")
        print("   校区: \(exam.campus) | 考场: \(exam.examRoom) | 座位号: \(exam.seatNumber)")
        print("   教师: \(exam.teacher) | 场次: \(exam.session)")
    }
}

func printCourseGrades(_ grades: [EduHelper.CourseGrade]) {
    guard !grades.isEmpty else {
        print("暂无课程成绩。")
        return
    }

    print("")
    print("课程成绩:")
    for (index, grade) in grades.enumerated() {
        print("\(index + 1). \(grade.courseName) [\(grade.courseID)]")
        print("   学期: \(grade.semester) | 成绩: \(grade.grade) | 绩点: \(grade.gradePoint)")
        print("   学分: \(grade.credit) | 考核方式: \(grade.assessmentMethod) | 课程性质: \(grade.courseNature.rawValue)")
    }
}

func printEducationCourses(_ courses: [EduHelper.Course]) {
    guard !courses.isEmpty else {
        print("暂无课程表数据。")
        return
    }

    print("")
    print("课程表:")
    for (index, course) in courses.enumerated() {
        let teacher = course.teacher?.isEmpty == false ? course.teacher! : "未知教师"
        print("\(index + 1). \(course.courseName) - \(teacher)")
        for session in course.sessions.sorted(by: compareSessions) {
            let classroom = session.classroom ?? "未提供"
            print("   \(displayDayOfWeek(session.dayOfWeek)) 第\(session.startSection)-\(session.endSection)节 | 周次: \(displayWeeks(session.weeks)) | 教室: \(classroom)")
        }
    }
}

func printAvailableClassrooms(_ classrooms: [String], query: ClassroomQuery) {
    let campus = query.campus.displayName
    let dayOfWeek = displayDayOfWeek(query.dayOfWeek)

    guard !classrooms.isEmpty else {
        print("\(campus) 第\(query.week)周 \(dayOfWeek) 第\(query.section)大节暂无空闲教室。")
        return
    }

    print("")
    print("\(campus) 第\(query.week)周 \(dayOfWeek) 第\(query.section)大节空闲教室:")
    for (index, classroom) in classrooms.enumerated() {
        print("\(index + 1). \(classroom)")
    }
}

private func compareSessions(_ lhs: EduHelper.ScheduleSession, _ rhs: EduHelper.ScheduleSession) -> Bool {
    if lhs.dayOfWeek.rawValue != rhs.dayOfWeek.rawValue {
        return lhs.dayOfWeek.rawValue < rhs.dayOfWeek.rawValue
    }
    if lhs.startSection != rhs.startSection {
        return lhs.startSection < rhs.startSection
    }
    return lhs.endSection < rhs.endSection
}

private func displayDayOfWeek(_ dayOfWeek: EduHelper.DayOfWeek) -> String {
    switch dayOfWeek {
    case .monday:
        return "星期一"
    case .tuesday:
        return "星期二"
    case .wednesday:
        return "星期三"
    case .thursday:
        return "星期四"
    case .friday:
        return "星期五"
    case .saturday:
        return "星期六"
    case .sunday:
        return "星期日"
    }
}

private func displayWeeks(_ weeks: [Int]) -> String {
    let sortedWeeks = weeks.sorted()
    return sortedWeeks.map(String.init).joined(separator: ",")
}

private func displayDate(_ date: Date) -> String {
    DateFormatters.display.string(from: date)
}

func formatElectricity(_ electricity: Double) -> String {
    String(format: "%.2f", electricity)
}

private enum DateFormatters {
    static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }()
}
