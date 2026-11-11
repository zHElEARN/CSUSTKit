import CSUSTKit
import Foundation
import Testing

struct ElectricityUtilsTests {
    private let day: TimeInterval = 86_400
    private let base: TimeInterval = 1_700_000_000

    private func records(_ values: [Double]) -> [ElectricityRecord] {
        values.enumerated().map { index, value in
            ElectricityRecord(date: Date(timeIntervalSince1970: base + Double(index) * day), electricity: value)
        }
    }

    // MARK: - 预测耗尽时间

    @Test func predictReturnsNilWithoutEnoughReadings() {
        #expect(ElectricityUtils.predictExhaustionDate(from: []) == nil)
        #expect(ElectricityUtils.predictExhaustionDate(from: records([10])) == nil)
    }

    @Test func predictReturnsNilWhenNotDeclining() {
        #expect(ElectricityUtils.predictExhaustionDate(from: records([10, 10])) == nil)
        #expect(ElectricityUtils.predictExhaustionDate(from: records([10, 12])) == nil)
    }

    @Test func predictReturnsNilWhenSpanIsTooShort() {
        let short = [
            ElectricityRecord(date: Date(timeIntervalSince1970: base), electricity: 10),
            ElectricityRecord(date: Date(timeIntervalSince1970: base + 3_600), electricity: 9.9),
        ]
        #expect(ElectricityUtils.predictExhaustionDate(from: short) == nil)
    }

    @Test func predictLinearDecline() throws {
        let input = records((0...14).map { 24 - Double($0) })
        let predicted = try #require(ElectricityUtils.predictExhaustionDate(from: input))
        guard let last = input.last else { return }
        #expect(abs(predicted.timeIntervalSince(last.date) / day - 10) < 0.01)
    }

    @Test func predictOnlyUsesRecentWindow() throws {
        var values = (0...13).map { 100 - Double($0) * 5 }
        values += (14...27).map { 35 - Double($0 - 14) }
        let input = records(values)
        let predicted = try #require(ElectricityUtils.predictExhaustionDate(from: input))
        guard let last = input.last else { return }
        #expect(abs(predicted.timeIntervalSince(last.date) / day - 22 / (13.0 / 14.0)) < 0.05)
    }

    @Test func predictStartsAfterLastCharge() throws {
        let input = records([20, 19, 18, 30, 29, 28])
        let predicted = try #require(ElectricityUtils.predictExhaustionDate(from: input))
        guard let last = input.last else { return }
        #expect(abs(predicted.timeIntervalSince(last.date) / day - 28) < 0.05)
    }

    @Test func predictReturnsNilWhenSegmentHasSingleReading() {
        #expect(ElectricityUtils.predictExhaustionDate(from: records([10, 9, 20])) == nil)
    }

    // MARK: - 降采样

    @Test func downsampleKeepsInputWhenNotEnough() {
        let input = records([1, 2, 3, 4, 5])
        #expect(ElectricityUtils.downsample(from: input, to: 5).count == 5)
        #expect(ElectricityUtils.downsample(from: input, to: 10).count == 5)
        #expect(ElectricityUtils.downsample(from: input, to: 0).count == 5)
        #expect(ElectricityUtils.downsample(from: input, to: -3).count == 5)
        #expect(ElectricityUtils.downsample(from: [], to: 10).isEmpty)
    }

    @Test func downsampleKeepsEndpointsWhenThresholdIsTwo() {
        let input = records((0..<10).map { Double($0) })
        let output = ElectricityUtils.downsample(from: input, to: 2)
        #expect(output.count == 2)
        #expect(output.first == input.first)
        #expect(output.last == input.last)
    }

    @Test func downsampleHitsThresholdAndKeepsEndpoints() {
        let input = records((0..<1000).map { 1000 - Double($0) })
        let output = ElectricityUtils.downsample(from: input, to: 80)
        #expect(output.count == 80)
        #expect(output.first == input.first)
        #expect(output.last == input.last)
        #expect(zip(output, output.dropFirst()).allSatisfy { $0.electricity > $1.electricity })
    }

    // MARK: - 值域

    @Test func valueRangeFallsBackForEmptyInput() {
        #expect(ElectricityUtils.valueRange(for: []) == 0...2)
        #expect(ElectricityUtils.valueRange(for: [], fallback: 0...5) == 0...5)
    }

    @Test func valueRangeAppliesPadding() {
        #expect(ElectricityUtils.valueRange(for: records([10, 20])) == 8...22)
    }

    @Test func valueRangeNeverGoesBelowZero() {
        let range = ElectricityUtils.valueRange(for: records([0.5, 1]))
        #expect(range.lowerBound == 0)
        #expect(range.upperBound == 3)
    }

    @Test func valueRangeHonoursMinimumSpan() {
        #expect(ElectricityUtils.valueRange(for: records([10]), padding: 0, minimumSpan: 1) == 10...11)
    }
}
