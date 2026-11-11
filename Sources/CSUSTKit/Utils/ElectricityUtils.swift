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

/// 宿舍电量计算工具
public enum ElectricityUtils {
    /// 预测电量耗尽时间
    ///
    /// 取最近 14 天内首尾两条读数算出日均耗电量，再按当前剩余电量推算耗尽时间。
    /// 只统计最后一次充电之后的数据。
    /// - Parameter records: 电量读数，按时间升序排列
    /// - Returns: 预计耗尽时间；读数不足、跨度小于 1 天或电量未下降时返回 nil
    public static func predictExhaustionDate(from records: [ElectricityRecord]) -> Date? {
        guard let last = records.last, last.electricity > 0 else { return nil }

        // 从末尾往回找最后一次"充电"（电量上升）的位置，只保留其后的数据
        var segmentStart = records.count - 1
        while segmentStart > 0 && records[segmentStart].electricity <= records[segmentStart - 1].electricity {
            segmentStart -= 1
        }

        let startDate = last.date.addingTimeInterval(-consumptionWindowInDays * 86_400)
        guard let first = records[segmentStart...].first(where: { $0.date >= startDate }),
            first.date < last.date
        else {
            return nil
        }

        let days = last.date.timeIntervalSince(first.date) / 86_400
        let consumed = first.electricity - last.electricity
        guard days >= minimumSpanInDays, consumed > 0 else { return nil }

        return last.date.addingTimeInterval(last.electricity / (consumed / days) * 86_400)
    }

    /// 计算日均耗电量的时间窗口（天）
    private static let consumptionWindowInDays: Double = 14

    /// 估算日均耗电量所需的最短时间跨度（天）
    private static let minimumSpanInDays: Double = 1

    /// 降采样
    ///
    /// 在保持曲线形状的前提下把读数压缩到指定数量，用于绘制趋势图。
    /// - Parameters:
    ///   - records: 电量读数，按时间升序排列
    ///   - threshold: 目标数量，小于等于 0 时原样返回
    /// - Returns: 采样后的读数，首尾两条始终保留
    public static func downsample(from records: [ElectricityRecord], to threshold: Int) -> [ElectricityRecord] {
        let dataCount = records.count

        guard threshold > 0, dataCount > threshold else { return records }

        if threshold <= 2 {
            return [records.first, records.last].compactMap { $0 }
        }

        var sampled: [ElectricityRecord] = []
        sampled.reserveCapacity(threshold)
        sampled.append(records[0])

        let bucketSize = Double(dataCount - 2) / Double(threshold - 2)
        var lastSelectedStep = 0

        for i in 0..<(threshold - 2) {
            let bucketStart = Int(floor(Double(i) * bucketSize)) + 1
            let bucketEnd = Int(floor(Double(i + 1) * bucketSize)) + 1

            let nextBucketStart = Int(floor(Double(i + 1) * bucketSize)) + 1
            let nextBucketEnd = min(Int(floor(Double(i + 2) * bucketSize)) + 1, dataCount)

            var avgX: Double = 0
            var avgY: Double = 0

            if nextBucketStart < dataCount {
                let nextCount = Double(nextBucketEnd - nextBucketStart)
                for j in nextBucketStart..<nextBucketEnd {
                    avgX += records[j].date.timeIntervalSince1970
                    avgY += records[j].electricity
                }
                avgX /= nextCount
                avgY /= nextCount
            } else {
                avgX = records[dataCount - 1].date.timeIntervalSince1970
                avgY = records[dataCount - 1].electricity
            }

            let pointA = records[lastSelectedStep]
            let pointAX = pointA.date.timeIntervalSince1970
            let pointAY = pointA.electricity

            var maxArea: Double = -1
            var selectedIndex = bucketStart

            for j in bucketStart..<min(bucketEnd, dataCount) {
                let area = abs(
                    (pointAX * (records[j].electricity - avgY) + records[j].date.timeIntervalSince1970 * (avgY - pointAY) + avgX * (pointAY - records[j].electricity))
                )

                if area > maxArea {
                    maxArea = area
                    selectedIndex = j
                }
            }

            sampled.append(records[selectedIndex])
            lastSelectedStep = selectedIndex
        }

        sampled.append(records[dataCount - 1])

        return sampled
    }

    /// 电量值域
    ///
    /// 由读数范围计算绘制趋势图时的纵轴范围。
    /// - Parameters:
    ///   - records: 电量读数
    ///   - padding: 上下留白
    ///   - minimumSpan: 值域最小跨度
    ///   - fallback: 读数为空时返回的值域
    /// - Returns: 值域，下界不小于 0
    public static func valueRange(
        for records: [ElectricityRecord],
        padding: Double = 2,
        minimumSpan: Double = 1,
        fallback: ClosedRange<Double> = 0...2
    ) -> ClosedRange<Double> {
        guard let minValue = records.map({ $0.electricity }).min(),
            let maxValue = records.map({ $0.electricity }).max()
        else {
            return fallback
        }

        let lowerBound = max(0, minValue - padding)
        let upperBound = max(lowerBound + minimumSpan, maxValue + padding)

        return lowerBound...upperBound
    }
}
