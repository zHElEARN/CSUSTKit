extension ChaoxingHelper {
    /// 个人资料
    public struct Profile: BaseModel {
        /// 姓名
        public let name: String

        public init(name: String) {
            self.name = name
        }
    }
}
