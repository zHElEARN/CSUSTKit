extension CampusCardHelper {
    /// 个人资料
    public struct Profile: BaseModel {
        /// 用户ID
        public let id: Int
        /// 账号
        public let account: String
        /// 姓名
        public let name: String
        /// 头像URL
        public let avatar: String
        /// 电子邮箱
        public let email: String?
        /// 手机号码
        public let mobile: String?
        /// 用户类型
        public let userType: String
        /// 学号
        public let sno: String
        /// 卡号
        public let cardId: String
        /// 卡账户
        public let cardAccount: String
        /// 性别
        public let sex: Int
        /// 国家代码
        public let countryCode: String
        /// 民族代码
        public let nationCode: String
        /// 政治面貌代码
        public let politicsStatusCode: String
        /// 证件类型代码
        public let identityCode: String
        /// 校区代码
        public let campusCode: String
        /// 部门/学院代码
        public let departmentCode: String
        /// 部门/学院名称
        public let departmentName: String
        /// 专业代码
        public let professionCode: String
        /// 专业名称
        public let professionName: String
        /// 班级代码
        public let classCode: String
        /// 班级名称
        public let className: String
        /// 状态标识
        public let flag: String
        /// 用户ID
        public let userId: Int
        /// 证件号码
        public let idNumber: String
        /// 证件名称
        public let identityName: String
        /// 证件有效期
        public let identityExpDate: String
        /// 备注信息
        public let remark: String

        public init(id: Int, account: String, name: String, avatar: String, email: String?, mobile: String?, userType: String, sno: String, cardId: String, cardAccount: String, sex: Int, countryCode: String, nationCode: String, politicsStatusCode: String, identityCode: String, campusCode: String, departmentCode: String, departmentName: String, professionCode: String, professionName: String, classCode: String, className: String, flag: String, userId: Int, idNumber: String, identityName: String, identityExpDate: String, remark: String) {
            self.id = id
            self.account = account
            self.name = name
            self.avatar = avatar
            self.email = email
            self.mobile = mobile
            self.userType = userType
            self.sno = sno
            self.cardId = cardId
            self.cardAccount = cardAccount
            self.sex = sex
            self.countryCode = countryCode
            self.nationCode = nationCode
            self.politicsStatusCode = politicsStatusCode
            self.identityCode = identityCode
            self.campusCode = campusCode
            self.departmentCode = departmentCode
            self.departmentName = departmentName
            self.professionCode = professionCode
            self.professionName = professionName
            self.classCode = classCode
            self.className = className
            self.flag = flag
            self.userId = userId
            self.idNumber = idNumber
            self.identityName = identityName
            self.identityExpDate = identityExpDate
            self.remark = remark
        }
    }
}
