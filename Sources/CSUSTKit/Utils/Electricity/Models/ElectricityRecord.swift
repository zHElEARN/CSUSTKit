import Foundation

/// 宿舍电量读数
public struct ElectricityRecord: BaseModel {
    /// 读数时间
    public let date: Date
    /// 剩余电量（度）
    public let electricity: Double

    public init(date: Date, electricity: Double) {
        self.date = date
        self.electricity = electricity
    }
}
