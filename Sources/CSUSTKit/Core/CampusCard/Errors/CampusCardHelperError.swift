import Foundation

extension CampusCardHelper {
    /// 校园卡助手相关错误
    public enum CampusCardHelperError: Error, LocalizedError {
        /// 个人信息获取失败
        case profileRetrievalFailed(String)
        /// 楼栋列表获取失败
        case buildingsRetrievalFailed(String)
        /// 宿舍列表获取失败
        case roomsRetrievalFailed(String)
        /// 宿舍电量获取失败
        case electricityRetrievalFailed(String)

        /// 错误描述
        public var errorDescription: String? {
            switch self {
            case .profileRetrievalFailed(let message):
                return "个人信息获取失败: \(message)"
            case .buildingsRetrievalFailed(let message):
                return "楼栋信息获取失败: \(message)"
            case .roomsRetrievalFailed(let message):
                return "宿舍列表获取失败: \(message)"
            case .electricityRetrievalFailed(let message):
                return "宿舍电量获取失败: \(message)"
            }
        }
    }
}
