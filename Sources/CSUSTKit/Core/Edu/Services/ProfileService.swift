import SwiftSoup

extension EduHelper {
    /// 个人档案服务
    public class ProfileService: BaseService {
        private func parseTableCell(_ rows: Elements, _ rowIndex: Int, _ colIndex: Int) throws -> String {
            guard rowIndex < rows.count else {
                throw EduHelperError.profileRetrievalFailed("行索引越界")
            }
            let row = rows[rowIndex]
            let cols = try row.select("td")
            guard colIndex < cols.count else {
                throw EduHelperError.profileRetrievalFailed("列索引越界")
            }
            return try cols[colIndex].text().trim()
        }

        /// 获取学生档案信息
        /// - Throws: `EduHelperError`
        /// - Returns: 学生档案信息
        public func getProfile() async throws -> Profile {
            let response = try await performRequest(factory.make(.education, "/jsxsd/grxx/xsxx"))
            let document = try SwiftSoup.parse(response)
            guard let table = try document.select("#xjkpTable > tbody").first() else {
                throw EduHelperError.profileRetrievalFailed("未找到个人信息表")
            }
            let rows = try table.select("tr")
            return Profile(
                department: try parseTableCell(rows, 2, 0).components(separatedBy: "：")[1],
                major: try parseTableCell(rows, 2, 1).components(separatedBy: "：")[1],
                educationSystem: try parseTableCell(rows, 2, 2).components(separatedBy: "：")[1],
                className: try parseTableCell(rows, 2, 3).components(separatedBy: "：")[1],
                studentID: try parseTableCell(rows, 2, 4).components(separatedBy: "：")[1],
                name: try parseTableCell(rows, 3, 1),
                gender: try parseTableCell(rows, 3, 3),
                namePinyin: try parseTableCell(rows, 3, 5),
                birthDate: try parseTableCell(rows, 4, 1),
                ethnicity: try parseTableCell(rows, 7, 3),
                studyLevel: try parseTableCell(rows, 8, 3),
                homeAddress: try parseTableCell(rows, 9, 1),
                homePhone: try parseTableCell(rows, 10, 3),
                personalPhone: try parseTableCell(rows, 4, 5),
                enrollmentDate: try parseTableCell(rows, 46, 1),
                entranceExamID: try parseTableCell(rows, 47, 1),
                idCardNumber: try parseTableCell(rows, 47, 3)
            )
        }
    }
}
