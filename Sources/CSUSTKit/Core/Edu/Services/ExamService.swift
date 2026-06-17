import Alamofire
import Foundation
import SwiftSoup

extension EduHelper {
    /// 考试服务
    public class ExamService: BaseService {
        /// 获取考试安排
        /// - Parameters:
        ///   - academicYearSemester: 学年学期，格式为 "2023-2024-1"，如果为 `nil` 则使用当前默认学期
        ///   - semesterType: 学期类型，如果为 `nil` 则查询所有类型的考试
        /// - Throws: `EduHelperError`
        /// - Returns: 考试信息数组
        public func getExamSchedule(academicYearSemester: String? = nil, semesterType: SemesterType? = nil) async throws -> [Exam] {
            var queryAcademicYearSemester: String
            if let academicYearSemester {
                queryAcademicYearSemester = academicYearSemester
            } else {
                let semesters = try await getAvailableSemestersForExamSchedule()
                queryAcademicYearSemester = semesters.1
            }
            let queryParams = [
                "xqlbmc": semesterType?.rawValue ?? "",
                "xnxqid": queryAcademicYearSemester,
                "xqlb": semesterType?.id ?? "",
            ]
            let response = try await performRequest(factory.make(.education, "/jsxsd/xsks/xsksap_list"), .post, queryParams)
            let document = try SwiftSoup.parse(response)
            guard let table = try document.select("#dataList").first() else {
                throw EduHelperError.examScheduleRetrievalFailed("未找到考试安排表")
            }
            guard !(try table.html().contains("未查询到数据")) else {
                return []
            }
            let rows = try table.select("tr")
            var exams: [Exam] = []
            for (index, row) in rows.enumerated() {
                guard index > 0 else { continue }
                let cols = try row.select("td")
                guard cols.count >= 11 else {
                    throw EduHelperError.examScheduleRetrievalFailed("行列数不足: \(cols.count)")
                }
                let examTimeRange = try parseDate(from: try cols[6].text().trim())
                let exam = Exam(
                    campus: try cols[1].text().trim(),
                    session: try cols[2].text().trim(),
                    courseID: try cols[3].text().trim(),
                    courseName: try cols[4].text().trim(),
                    teacher: try cols[5].text().trim(),
                    examTime: try cols[6].text().trim(),
                    examStartTime: examTimeRange.0,
                    examEndTime: examTimeRange.1,
                    examRoom: try cols[7].text().trim(),
                    seatNumber: try cols[8].text().trim(),
                    admissionTicketNumber: try cols[9].text().trim(),
                    remarks: try cols[10].text().trim()
                )
                exams.append(exam)
            }
            return exams
        }

        /// 获取考试安排的所有可用学期以及默认学期
        /// - Throws: `EduHelperError`
        /// - Returns: 包含所有可用学期的数组和默认学期
        public func getAvailableSemestersForExamSchedule() async throws -> ([String], String) {
            let response = try await performRequest(factory.make(.education, "/jsxsd/xsks/xsksap_query"))
            let document = try SwiftSoup.parse(response)
            guard let semesterSelect = try document.select("#xnxqid").first() else {
                throw EduHelperError.availableSemestersForExamScheduleRetrievalFailed("未找到学期选择元素")
            }
            let options = try semesterSelect.select("option")
            var semesters: [String] = []
            var defaultSemester: String?
            for option in options {
                let name = try option.text().trim()
                if option.hasAttr("selected") {
                    defaultSemester = name
                }
                semesters.append(name)
            }
            guard !semesters.isEmpty else {
                throw EduHelperError.availableSemestersForExamScheduleRetrievalFailed("学期选择元素中未找到学期")
            }
            guard let defaultSemester = defaultSemester else {
                throw EduHelperError.availableSemestersForExamScheduleRetrievalFailed("未找到默认学期")
            }
            return (semesters, defaultSemester)
        }

        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            return formatter
        }()

        private func parseDate(from dateString: String) throws -> (Date, Date) {
            let components = dateString.split(separator: " ")
            guard components.count == 2 else {
                throw EduHelperError.dateParsingFailed("日期字符串格式无效: \(dateString)")
            }
            let timeComponents = components[1].split(separator: "~")
            guard timeComponents.count == 2 else {
                throw EduHelperError.dateParsingFailed("日期字符串中的时间格式无效: \(dateString)")
            }
            guard let startDate = Self.dateFormatter.date(from: "\(components[0]) \(timeComponents[0])"),
                let endDate = Self.dateFormatter.date(from: "\(components[0]) \(timeComponents[1])")
            else {
                throw EduHelperError.dateParsingFailed("无法从字符串解析日期: \(dateString)")
            }
            return (startDate, endDate)
        }
    }
}
