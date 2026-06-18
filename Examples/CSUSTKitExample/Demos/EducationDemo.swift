import CSUSTKit

func runEducationMenu(using eduHelper: EduHelper) async {
    while true {
        print("")
        print("=== 教务系统 ===")
        print("1. 查看个人信息")
        print("2. 查看考试安排")
        print("3. 查看课程成绩")
        print("4. 查看课程表")
        print("5. 查看空闲教室")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            await handleAsyncOperation {
                let profile = try await eduHelper.profileService.getProfile()
                print("")
                print("姓名: \(profile.name)")
                print("学号: \(profile.studentID)")
                print("院系: \(profile.department)")
                print("专业: \(profile.major)")
                print("班级: \(profile.className)")
                print("联系电话: \(profile.personalPhone)")
            }
        case "2":
            await handleAsyncOperation {
                let exams = try await eduHelper.examService.getExamSchedule()
                printEducationExams(exams)
            }
        case "3":
            await handleAsyncOperation {
                let grades = try await eduHelper.courseService.getCourseGrades()
                printCourseGrades(grades)
            }
        case "4":
            await handleAsyncOperation {
                let (courses, remarks) = try await eduHelper.courseService.getCourseSchedule()
                printEducationCourses(courses)
                print("备注:")
                print(remarks)
            }
        case "5":
            await handleAsyncOperation {
                let classroomQuery = promptClassroomQuery()
                let classrooms = try await eduHelper.courseService.getAvailableClassrooms(
                    campus: classroomQuery.campus,
                    week: classroomQuery.week,
                    dayOfWeek: classroomQuery.dayOfWeek,
                    section: classroomQuery.section
                )
                printAvailableClassrooms(classrooms, query: classroomQuery)
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}

private func promptClassroomQuery() -> ClassroomQuery {
    let campus = promptCampus()
    let week = promptInt("请输入周次", validRange: 1...30)
    let dayNumber = promptInt("请输入星期（1-7）", validRange: 1...7)
    let section = promptInt("请输入大节（1-5）", validRange: 1...5)

    let dayOfWeekMap: [Int: EduHelper.DayOfWeek] = [
        1: .monday,
        2: .tuesday,
        3: .wednesday,
        4: .thursday,
        5: .friday,
        6: .saturday,
        7: .sunday,
    ]

    return ClassroomQuery(
        campus: campus,
        week: week,
        dayOfWeek: dayOfWeekMap[dayNumber] ?? .monday,
        section: section
    )
}
