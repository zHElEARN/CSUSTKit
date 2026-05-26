extension CampusCardHelper {
    /// 校区
    public enum Campus: String, CaseIterable, BaseModel {
        /// 云塘
        case yuntang = "云塘"
        /// 金盆岭
        case jinpenling = "金盆岭"

        /// 校区显示名称
        public var displayName: String {
            return "\(self.rawValue)校区"
        }

        // parameter feeitemid
        internal var feeItemID: String {
            switch self {
            case .jinpenling:
                return "468"
            case .yuntang:
                return "448"
            }
        }

        // parameter xiaoqu_id
        internal var campusID: String {
            switch self {
            case .jinpenling:
                return "22"
            case .yuntang:
                return "1"
            }
        }
    }
}
