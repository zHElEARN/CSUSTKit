extension EvalHelper {
    public struct Profile: BaseModel {
        public let userId: Int
        public let loginName: String
        public let realName: String

        public init(userId: Int, loginName: String, realName: String) {
            self.userId = userId
            self.loginName = loginName
            self.realName = realName
        }
    }
}
