import CSUSTKit
import Foundation
import Testing

struct GradeScaleTests {
    @Test func standardCoversElevenRangesInDescendingOrder() {
        let scales = GradeScale.standard
        #expect(scales.count == 11)
        #expect(scales.first?.minGrade == 90)
        #expect(scales.last?.gradePoint == 0.0)
        for (current, next) in zip(scales, scales.dropFirst()) {
            #expect(current.minGrade > next.minGrade)
        }
    }

    @Test func displayRangeFormats() {
        #expect(GradeScale(minGrade: 90, maxGrade: 100, gradePoint: 4.0).displayRange == "90-100")
        #expect(GradeScale(minGrade: 0, maxGrade: 59, gradePoint: 0.0).displayRange == "≤59")
    }

    @Test func gradePointLookupHandlesBoundaries() {
        #expect(GradeScale.gradePoint(forGrade: 100) == 4.0)
        #expect(GradeScale.gradePoint(forGrade: 90) == 4.0)
        #expect(GradeScale.gradePoint(forGrade: 89) == 3.7)
        #expect(GradeScale.gradePoint(forGrade: 85) == 3.7)
        #expect(GradeScale.gradePoint(forGrade: 60) == 1.0)
        #expect(GradeScale.gradePoint(forGrade: 59) == 0.0)
        #expect(GradeScale.gradePoint(forGrade: 0) == 0.0)
    }

    @Test func gradePointLookupRejectsOutOfRangeGrades() {
        #expect(GradeScale.gradePoint(forGrade: 101) == nil)
        #expect(GradeScale.gradePoint(forGrade: -1) == nil)
    }

    @Test func everyRangeResolvesToItsOwnPoint() {
        for scale in GradeScale.standard {
            #expect(GradeScale.gradePoint(forGrade: scale.minGrade) == scale.gradePoint)
            #expect(GradeScale.gradePoint(forGrade: scale.maxGrade) == scale.gradePoint)
        }
    }

    @Test func scaleLookupByGradePoint() {
        #expect(GradeScale.scale(forGradePoint: 3.7)?.displayRange == "85-89")
        #expect(GradeScale.scale(forGradePoint: 4.0)?.displayRange == "90-100")
        #expect(GradeScale.scale(forGradePoint: 0.0)?.displayRange == "≤59")
        #expect(GradeScale.scale(forGradePoint: 5.0) == nil)
        #expect(GradeScale.scale(forGradePoint: 2.5) == nil)
    }
}
