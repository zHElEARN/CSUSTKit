import Foundation

/// 绩点与百分制成绩段的对应关系
public struct GradeScale: BaseModel {
    /// 成绩段下界
    public let minGrade: Int
    /// 成绩段上界
    public let maxGrade: Int
    /// 对应的绩点
    public let gradePoint: Double

    public init(minGrade: Int, maxGrade: Int, gradePoint: Double) {
        self.minGrade = minGrade
        self.maxGrade = maxGrade
        self.gradePoint = gradePoint
    }

    /// 显示用的成绩段，如 "90-100"、"≤59"
    public var displayRange: String {
        return minGrade <= 0 ? "≤\(maxGrade)" : "\(minGrade)-\(maxGrade)"
    }

    /// 全部档位，按成绩从高到低
    public static let standard: [GradeScale] = [
        GradeScale(minGrade: 90, maxGrade: 100, gradePoint: 4.0),
        GradeScale(minGrade: 85, maxGrade: 89, gradePoint: 3.7),
        GradeScale(minGrade: 82, maxGrade: 84, gradePoint: 3.3),
        GradeScale(minGrade: 78, maxGrade: 81, gradePoint: 3.0),
        GradeScale(minGrade: 75, maxGrade: 77, gradePoint: 2.7),
        GradeScale(minGrade: 72, maxGrade: 74, gradePoint: 2.3),
        GradeScale(minGrade: 68, maxGrade: 71, gradePoint: 2.0),
        GradeScale(minGrade: 66, maxGrade: 67, gradePoint: 1.7),
        GradeScale(minGrade: 64, maxGrade: 65, gradePoint: 1.3),
        GradeScale(minGrade: 60, maxGrade: 63, gradePoint: 1.0),
        GradeScale(minGrade: 0, maxGrade: 59, gradePoint: 0.0),
    ]

    /// 查询百分制成绩对应的绩点
    /// - Parameter grade: 百分制成绩
    /// - Returns: 绩点；成绩不在任何档位内时返回 nil
    public static func gradePoint(forGrade grade: Int) -> Double? {
        return standard.first { grade >= $0.minGrade && grade <= $0.maxGrade }?.gradePoint
    }

    /// 查询绩点对应的成绩段
    /// - Parameter point: 绩点
    /// - Returns: 成绩段；绩点不在任何档位内时返回 nil
    public static func scale(forGradePoint point: Double) -> GradeScale? {
        return standard.first { abs($0.gradePoint - point) < 0.0001 }
    }
}
