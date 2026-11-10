import CSUSTKit

func runEducationMenu(using eduHelper: EduHelper) async {
    while true {
        print("")
        print("=== 教务系统 ===")
        print("1. 查看个人信息")
        print("2. 查看考试安排")
        print("3. 查看课程成绩")
        print("4. 查看课程表")
        print("5. 查看教室课表")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            await handleAsyncOperation {
                let profile = try await eduHelper.getProfile()
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
                let exams = try await eduHelper.getExamSchedule()
                printEducationExams(exams)
            }
        case "3":
            await handleAsyncOperation {
                let grades = try await eduHelper.getCourseGrades()
                printCourseGrades(grades)
            }
        case "4":
            await handleAsyncOperation {
                let (courses, remarks) = try await eduHelper.getCourseSchedule()
                printEducationCourses(courses)
                print("备注:")
                print(remarks)
            }
        case "5":
            await handleAsyncOperation {
                let campus = promptCampus()
                let schedule = try await eduHelper.getClassroomSchedule(campus: campus)
                printClassroomSchedule(schedule, campus: campus)
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}
