import Foundation
import SwiftSoup

extension EduHelper {
    /// 学期服务
    public class SemesterService: BaseService {
        /// 获取学期首日
        /// - Parameter academicYearSemester: 学年学期，格式为 "2023-2024-1"，如果为 `nil` 则使用当前默认学期
        /// - Throws: `EduHelperError`
        /// - Returns: 学期首日
        public func getSemesterStartDate(academicYearSemester: String? = nil) async throws -> Date {
            let queryParams = [
                "xnxq01id": academicYearSemester ?? ""
            ]
            let response = try await performRequest(factory.make(.education, "/jsxsd/jxzl/jxzl_query"), .post, queryParams)
            let document = try SwiftSoup.parse(response)
            guard let table = try document.select("#kbtable").first() else {
                throw EduHelperError.semesterStartDateRetrievalFailed("未找到学期首日表")
            }
            let rows = try table.select("tr")
            guard rows.count > 1 else {
                throw EduHelperError.semesterStartDateRetrievalFailed("学期首日表行数不足")
            }
            let targetRow = rows[1]
            let cols = try targetRow.select("td")
            guard cols.count > 1 else {
                throw EduHelperError.semesterStartDateRetrievalFailed("目标行列数不足")
            }
            let startDateText = try cols[1].attr("title").trim()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy年MM月dd"
            guard let startDate = dateFormatter.date(from: startDateText) else {
                throw EduHelperError.semesterStartDateRetrievalFailed("无法解析学期首日: \(startDateText)")
            }
            return startDate
        }

        /// 获取学期首日所有可选的学期
        /// - Throws: `EduHelperError`
        /// - Returns: 包含所有可用学期的数组和默认学期
        public func getAvailableSemestersForStartDate() async throws -> ([String], String) {
            let response = try await performRequest(factory.make(.education, "/jsxsd/jxzl/jxzl_query"))
            let document = try SwiftSoup.parse(response)
            guard let select = try document.select("#xnxq01id").first() else {
                throw EduHelperError.availableSemestersForStartDateRetrievalFailed("未找到学期选择元素")
            }
            let options = try select.select("option")
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
                throw EduHelperError.availableSemestersForStartDateRetrievalFailed("学期选择元素中未找到学期")
            }
            guard let defaultSemester = defaultSemester else {
                throw EduHelperError.availableSemestersForStartDateRetrievalFailed("未找到默认学期")
            }
            return (semesters, defaultSemester)
        }
    }
}
