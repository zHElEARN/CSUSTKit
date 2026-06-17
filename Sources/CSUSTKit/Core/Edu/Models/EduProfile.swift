extension EduHelper {
    /// 学生档案信息
    public struct Profile: BaseModel {
        /// 院系
        public let department: String
        /// 专业
        public let major: String
        /// 学制
        public let educationSystem: String
        /// 班级
        public let className: String
        /// 学号
        public let studentID: String
        /// 姓名
        public let name: String
        /// 性别
        public let gender: String
        /// 姓名拼音
        public let namePinyin: String
        /// 出生日期
        public let birthDate: String
        /// 民族
        public let ethnicity: String
        /// 学习层次
        public let studyLevel: String
        /// 家庭现住址
        public let homeAddress: String
        /// 家庭电话
        public let homePhone: String
        /// 本人电话
        public let personalPhone: String
        /// 入学日期
        public let enrollmentDate: String
        /// 入学考号
        public let entranceExamID: String
        /// 身份证编号
        public let idCardNumber: String

        public init(
            department: String,
            major: String,
            educationSystem: String,
            className: String,
            studentID: String,
            name: String,
            gender: String,
            namePinyin: String,
            birthDate: String,
            ethnicity: String,
            studyLevel: String,
            homeAddress: String,
            homePhone: String,
            personalPhone: String,
            enrollmentDate: String,
            entranceExamID: String,
            idCardNumber: String
        ) {
            self.department = department
            self.major = major
            self.educationSystem = educationSystem
            self.className = className
            self.studentID = studentID
            self.name = name
            self.gender = gender
            self.namePinyin = namePinyin
            self.birthDate = birthDate
            self.ethnicity = ethnicity
            self.studyLevel = studyLevel
            self.homeAddress = homeAddress
            self.homePhone = homePhone
            self.personalPhone = personalPhone
            self.enrollmentDate = enrollmentDate
            self.entranceExamID = entranceExamID
            self.idCardNumber = idCardNumber
        }
    }
}
