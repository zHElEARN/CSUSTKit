import Foundation

/// 成绩统计
public struct GradeStatistics: BaseModel {
    /// 学期统计
    public struct SemesterSummary: BaseModel {
        /// 学期
        public let semester: String
        /// 算术平均分
        public let averageGrade: Double
        /// 学分加权 GPA
        public let gpa: Double

        public init(semester: String, averageGrade: Double, gpa: Double) {
            self.semester = semester
            self.averageGrade = averageGrade
            self.gpa = gpa
        }
    }

    /// 绩点分布
    public struct GradePointBucket: BaseModel {
        /// 绩点
        public let gradePoint: Double
        /// 课程数
        public let count: Int

        public init(gradePoint: Double, count: Int) {
            self.gradePoint = gradePoint
            self.count = count
        }
    }

    /// 课程数
    public let totalCourses: Int
    /// 总学时
    public let totalHours: Double
    /// 总学分
    public let totalCredits: Double
    /// 算术平均分
    public let averageGrade: Double
    /// 学分加权平均分
    public let weightedAverageGrade: Double
    /// 学分加权 GPA
    public let gpa: Double
    /// 绩点分布，按绩点从高到低
    public let gradePointDistribution: [GradePointBucket]
    /// 各学期统计，按学期升序
    public let semesters: [SemesterSummary]

    /// 由课程成绩计算统计结果
    /// - Parameter courseGrades: 课程成绩
    public init(courseGrades: [EduHelper.CourseGrade]) {
        let totalCredits = courseGrades.reduce(0.0) { $0 + $1.credit }
        let totalGrade = courseGrades.reduce(0) { $0 + $1.grade }

        self.totalCourses = courseGrades.count
        self.totalHours = courseGrades.reduce(0.0) { $0 + $1.totalHours }
        self.totalCredits = totalCredits
        self.averageGrade = courseGrades.isEmpty ? 0 : Double(totalGrade) / Double(courseGrades.count)
        self.weightedAverageGrade = totalCredits > 0 ? courseGrades.reduce(0.0) { $0 + Double($1.grade) * $1.credit } / totalCredits : 0
        self.gpa = totalCredits > 0 ? courseGrades.reduce(0.0) { $0 + $1.gradePoint * $1.credit } / totalCredits : 0

        self.gradePointDistribution =
            Dictionary(grouping: courseGrades, by: { $0.gradePoint })
            .map { GradePointBucket(gradePoint: $0.key, count: $0.value.count) }
            .sorted { $0.gradePoint > $1.gradePoint }

        self.semesters =
            Dictionary(grouping: courseGrades, by: { $0.semester })
            .map { semester, grades in
                let credits = grades.reduce(0.0) { $0 + $1.credit }
                let gradeSum = grades.reduce(0) { $0 + $1.grade }
                let average = grades.isEmpty ? 0 : Double(gradeSum) / Double(grades.count)
                let gpa = credits > 0 ? grades.reduce(0.0) { $0 + $1.gradePoint * $1.credit } / credits : 0
                return SemesterSummary(semester: semester, averageGrade: average, gpa: gpa)
            }
            .sorted { $0.semester < $1.semester }
    }
}
