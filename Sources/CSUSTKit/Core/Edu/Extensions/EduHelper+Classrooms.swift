import Alamofire
import Foundation
import SwiftSoup

extension EduHelper {
    /// 获取指定校区在指定时间内空闲的教室列表
    /// - Parameters:
    ///   - campus: 校区
    ///   - week: 周数
    ///   - dayOfWeek: 星期
    ///   - section: 节次（大节，范围：1-5）
    /// - Throws: `EduHelperError`
    /// - Returns: 空闲教室列表
    public func getAvailableClassrooms(campus: Campus, week: Int, dayOfWeek: DayOfWeek, section: Int) async throws -> [String] {
        let sectionMapper = [1: ("01", "02"), 2: ("03", "04"), 3: ("05", "06"), 4: ("07", "08"), 5: ("09", "10")]
        guard section >= 1 && section <= 5,
            let (startSection, endSection) = sectionMapper[section]
        else {
            throw EduHelperError.availableClassroomsRetrievalFailed("节次范围错误：1-5")
        }
        let dayOfWeekValue = dayOfWeek == .sunday ? 7 : dayOfWeek.rawValue
        let queryParams = [
            // 学年学期，不填写则教务系统默认
            // "xnxqh": "2025-2026-1",
            // 课表时间模式，不填写则教务系统默认
            // "kbjcmsid": "94673FF3230E4769E0533C41FF0A2703",
            // 上课院系
            "skyx": "",
            // 校区ID
            "xqid": campus == .yuntang ? "1" : "2",
            // 教学楼
            "jzwid": "",
            // 功能区
            "gnq": "",
            "skjsid": "",
            "skjs": "",
            "zc1": "\(week)",
            "zc2": "\(week)",
            "skxq1": "\(dayOfWeekValue)",
            "skxq2": "\(dayOfWeekValue)",
            "jc1": "\(startSection)",
            "jc2": "\(endSection)",
        ]
        let response = try await performRequest(factory.make(.education, "/jsxsd/kbcx/kbxx_classroom_ifr"), .post, queryParams)
        let document = try SwiftSoup.parse(response)
        guard let table = try document.select("#kbtable").first() else {
            throw EduHelperError.courseScheduleRetrievalFailed("未找到课程表")
        }
        let trList = try table.select("#kbtable > tbody > tr")
        var availableClassrooms: [String] = []

        for tr in trList {
            let tds = try tr.select("td")
            guard let firstTd = tds.first() else {
                continue
            }
            let classroom = try firstTd.text().trim()
            var isOccupied = false
            for slotTd in tds.dropFirst() {
                let hasCourseDiv = try !slotTd.select("div.kbcontent1").isEmpty()
                let content = try slotTd.text().trim()
                if hasCourseDiv || !content.isEmpty {
                    isOccupied = true
                    break
                }
            }
            if !isOccupied {
                availableClassrooms.append(classroom)
            }
        }
        return availableClassrooms
    }
}
