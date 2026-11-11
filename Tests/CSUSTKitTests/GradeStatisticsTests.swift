import CSUSTKit
import Foundation
import Testing

struct GradeStatisticsTests {
    private func course(
        _ semester: String,
        grade: Int,
        credit: Double,
        gradePoint: Double,
        hours: Double = 48
    ) -> EduHelper.CourseGrade {
        EduHelper.CourseGrade(
            semester: semester,
            courseID: "\(semester)-\(grade)",
            courseName: "课程",
            groupName: "",
            grade: grade,
            gradeDetailURL: "",
            studyMode: "正常",
            gradeIdentifier: "",
            credit: credit,
            totalHours: hours,
            gradePoint: gradePoint,
            retakeSemester: "",
            assessmentMethod: "考试",
            examNature: "正常考试",
            courseAttribute: "必修",
            courseNature: .professionalCourse,
            courseCategory: "专业课"
        )
    }

    @Test func emptyGradesProduceZeroStatistics() {
        let statistics = GradeStatistics(courseGrades: [])
        #expect(statistics.totalCourses == 0)
        #expect(statistics.totalCredits == 0)
        #expect(statistics.totalHours == 0)
        #expect(statistics.averageGrade == 0)
        #expect(statistics.weightedAverageGrade == 0)
        #expect(statistics.gpa == 0)
        #expect(statistics.gradePointDistribution.isEmpty)
        #expect(statistics.semesters.isEmpty)
    }

    @Test func singleCourseStatistics() {
        let statistics = GradeStatistics(courseGrades: [course("2025-2026-1", grade: 90, credit: 3, gradePoint: 4.0)])
        #expect(statistics.totalCourses == 1)
        #expect(statistics.totalCredits == 3)
        #expect(statistics.totalHours == 48)
        #expect(statistics.averageGrade == 90)
        #expect(statistics.weightedAverageGrade == 90)
        #expect(statistics.gpa == 4.0)
    }

    @Test func averageAndWeightedAverageDiffer() {
        let statistics = GradeStatistics(courseGrades: [
            course("2025-2026-1", grade: 90, credit: 4, gradePoint: 4.0),
            course("2025-2026-1", grade: 80, credit: 1, gradePoint: 3.0),
        ])
        #expect(statistics.totalCredits == 5)
        #expect(statistics.averageGrade == 85)
        #expect(statistics.weightedAverageGrade == 88)
        #expect(statistics.gpa == 3.8)
    }

    @Test func gradePointDistributionIsSortedDescending() {
        let statistics = GradeStatistics(courseGrades: [
            course("2025-2026-1", grade: 80, credit: 1, gradePoint: 3.0),
            course("2025-2026-1", grade: 90, credit: 1, gradePoint: 4.0),
            course("2025-2026-2", grade: 85, credit: 1, gradePoint: 4.0),
        ])
        #expect(statistics.gradePointDistribution.map(\.gradePoint) == [4.0, 3.0])
        #expect(statistics.gradePointDistribution.map(\.count) == [2, 1])
    }

    @Test func semestersAreGroupedAndSorted() {
        let statistics = GradeStatistics(courseGrades: [
            course("2025-2026-2", grade: 70, credit: 2, gradePoint: 2.0),
            course("2025-2026-1", grade: 90, credit: 2, gradePoint: 4.0),
            course("2025-2026-1", grade: 80, credit: 2, gradePoint: 3.0),
        ])
        #expect(statistics.semesters.count == 2)

        let first = statistics.semesters[0]
        #expect(first.semester == "2025-2026-1")
        #expect(first.averageGrade == 85)
        #expect(first.gpa == 3.5)

        let second = statistics.semesters[1]
        #expect(second.semester == "2025-2026-2")
        #expect(second.averageGrade == 70)
        #expect(second.gpa == 2.0)
    }
}
