extension EduHelper {
    /// 课程成绩信息
    public struct CourseGrade: BaseModel {
        /// 开课学期
        public let semester: String
        /// 课程编号
        public let courseID: String
        /// 课程名称
        public let courseName: String
        /// 分组名
        public let groupName: String
        /// 成绩
        public let grade: Int
        /// 详细成绩链接
        public let gradeDetailUrl: String
        /// 修读方式
        public let studyMode: String
        /// 成绩标识
        public let gradeIdentifier: String
        /// 学分
        public let credit: Double
        /// 总学时
        public let totalHours: Double
        /// 绩点
        public let gradePoint: Double
        /// 补重学期
        public let retakeSemester: String
        /// 考核方式
        public let assessmentMethod: String
        /// 考试性质
        public let examNature: String
        /// 课程属性
        public let courseAttribute: String
        /// 课程性质
        public let courseNature: CourseNature
        /// 课程类别
        public let courseCategory: String

        public init(
            semester: String,
            courseID: String,
            courseName: String,
            groupName: String,
            grade: Int,
            gradeDetailUrl: String,
            studyMode: String,
            gradeIdentifier: String,
            credit: Double,
            totalHours: Double,
            gradePoint: Double,
            retakeSemester: String,
            assessmentMethod: String,
            examNature: String,
            courseAttribute: String,
            courseNature: CourseNature,
            courseCategory: String
        ) {
            self.semester = semester
            self.courseID = courseID
            self.courseName = courseName
            self.groupName = groupName
            self.grade = grade
            self.gradeDetailUrl = gradeDetailUrl
            self.studyMode = studyMode
            self.gradeIdentifier = gradeIdentifier
            self.credit = credit
            self.totalHours = totalHours
            self.gradePoint = gradePoint
            self.retakeSemester = retakeSemester
            self.assessmentMethod = assessmentMethod
            self.examNature = examNature
            self.courseAttribute = courseAttribute
            self.courseNature = courseNature
            self.courseCategory = courseCategory
        }
    }

    /// 成绩组成
    public struct GradeComponent: Sendable, Codable {
        /// 成绩类型
        public let type: String
        /// 成绩
        public let grade: Double
        /// 成绩比例
        public let ratio: Int

        public init(type: String, grade: Double, ratio: Int) {
            self.type = type
            self.grade = grade
            self.ratio = ratio
        }
    }

    /// 成绩详情
    public struct GradeDetail: Sendable, Codable {
        /// 成绩组成
        public let components: [GradeComponent]
        /// 总成绩
        public let totalGrade: Int

        public init(components: [GradeComponent], totalGrade: Int) {
            self.components = components
            self.totalGrade = totalGrade
        }
    }
}
