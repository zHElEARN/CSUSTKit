import Alamofire
import Foundation
import SwiftSoup

extension EduHelper {
    /// 获取教室课表。
    /// - Parameters:
    ///   - campus: 校区。省略时查询全部校区。
    ///   - academicYearSemester: 学年学期，如 "2026-2027-1"。默认使用教务系统当前学期。
    ///   - weeks: 查询周次，包含两端。省略时查询整学期。由调用方确保周次在学期范围内。
    ///   - weekdays: 查询星期，周一为 1，周日为 7。省略时查询一周七天。
    ///   - sections: 查询小节范围。教务按课表格的起始小节筛选，省略时查询全部节次。
    /// - Returns: 每个课表格中的每个课程块各对应一条记录。指定周次时，记录只包含范围内的周次。
    public func getClassroomSchedule(
        campus: Campus? = nil,
        academicYearSemester: String? = nil,
        weeks: ClosedRange<Int>? = nil,
        weekdays: ClosedRange<Int>? = nil,
        sections: ClosedRange<Int>? = nil
    ) async throws -> [ClassroomScheduleSession] {
        let campusID = campus.map { $0 == .yuntang ? "1" : "2" } ?? ""
        let queryParams = [
            "xnxqh": academicYearSemester ?? "",
            "skyx": "",
            "xqid": campusID,
            "jzwid": "",
            "gnq": "",
            "skjsid": "",
            "skjs": "",
            "zc1": weeks.map { String($0.lowerBound) } ?? "",
            "zc2": weeks.map { String($0.upperBound) } ?? "",
            "skxq1": weekdays.map { String($0.lowerBound) } ?? "1",
            "skxq2": weekdays.map { String($0.upperBound) } ?? "7",
            "jc1": sections.map { String(format: "%02ld", $0.lowerBound) } ?? "",
            "jc2": sections.map { String(format: "%02ld", $0.upperBound) } ?? "",
        ]
        let response = try await performRequest(factory.make(.education, "/jsxsd/kbcx/kbxx_classroom_ifr"), .post, queryParams)
        let document = try SwiftSoup.parse(response)
        let rows = try document.select("#kbtable > thead > tr, #kbtable > tbody > tr")
        guard rows.count >= 2 else {
            throw EduHelperError.classroomScheduleRetrievalFailed("未找到教室课表表头")
        }

        let dayHeaders = rows[0].children().dropFirst()
        let sectionHeader = rows[1].children()
        guard try sectionHeader.first()?.text().trim() == "教室\\节次" else {
            throw EduHelperError.classroomScheduleRetrievalFailed("未找到节次表头")
        }

        let dayLabels: [String: DayOfWeek] = [
            "星期一": .monday, "星期二": .tuesday, "星期三": .wednesday, "星期四": .thursday,
            "星期五": .friday, "星期六": .saturday, "星期日": .sunday, "星期天": .sunday,
        ]
        var columns: [(day: DayOfWeek, startSection: Int, endSection: Int)] = []
        var seenDays: Set<DayOfWeek> = []
        var sectionCells = sectionHeader.dropFirst().makeIterator()
        for header in dayHeaders {
            let colspan = try header.hasAttr("colspan") ? header.attr("colspan") : "1"
            guard let day = dayLabels[try header.text().trim()], seenDays.insert(day).inserted,
                let span = Int(colspan), span >= 0
            else {
                throw EduHelperError.classroomScheduleRetrievalFailed("星期表头无效")
            }
            for _ in 0..<span {
                guard let cell = sectionCells.next() else {
                    throw EduHelperError.classroomScheduleRetrievalFailed("节次表头列数不足")
                }
                let label = try cell.text().trim()
                guard label.count == 4, let start = Int(label.prefix(2)), let end = Int(label.suffix(2)),
                    start > 0, start <= end
                else {
                    throw EduHelperError.classroomScheduleRetrievalFailed("节次表头无效: \(label)")
                }
                columns.append((day, start, end))
            }
        }
        guard seenDays.count == DayOfWeek.allCases.count, sectionCells.next() == nil else {
            throw EduHelperError.classroomScheduleRetrievalFailed("星期与节次表头不匹配")
        }

        var schedule: [ClassroomScheduleSession] = []
        for (index, row) in rows.dropFirst(2).enumerated() {
            let cells = row.children()
            guard cells.count == columns.count + 1, let room = try cells.first()?.text().trim(), !room.isEmpty else {
                throw EduHelperError.classroomScheduleRetrievalFailed("第 \(index + 1) 行教室或节次列无效")
            }
            for (column, cell) in zip(columns, cells.dropFirst()) {
                let blocks = try cell.select("div.kbcontent1")
                guard try !blocks.isEmpty || cell.text().trim().isEmpty else {
                    throw EduHelperError.classroomScheduleRetrievalFailed("教室 \(room) 的非空课表格缺少课程块")
                }
                for block in blocks {
                    let course = try parseClassroomScheduleBlock(block, classroom: room)
                    let matchingWeeks = weeks.map { range in course.weeks.filter(range.contains) } ?? course.weeks
                    guard !matchingWeeks.isEmpty else { continue }
                    schedule.append(
                        ClassroomScheduleSession(
                            classroom: room,
                            dayOfWeek: column.day,
                            startSection: column.startSection,
                            endSection: column.endSection,
                            weeks: matchingWeeks,
                            courseLabel: course.label
                        )
                    )
                }
            }
        }
        return schedule
    }

    private func parseClassroomScheduleBlock(_ block: Element, classroom: String) throws -> (label: String, weeks: [Int]) {
        var lines = [""]
        for node in block.getChildNodes() {
            if let text = node as? TextNode {
                lines[lines.count - 1] += text.getWholeText()
            } else if let element = node as? Element {
                if element.tagName() == "br" {
                    lines.append("")
                } else {
                    lines[lines.count - 1] += try element.text()
                }
            }
        }
        lines = lines.map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }

        // 单格有多条排课时，课程标签和周次可能分属两行。
        let dateLines = lines.prefix(2).indices.filter { lines[$0].hasSuffix("周)") || lines[$0].hasSuffix("周）") }
        let parseError = EduHelperError.classroomScheduleRetrievalFailed("无法解析教室 \(classroom) 的课程标签或周次")
        guard dateLines.count == 1, let index = dateLines.first,
            let opening = lines[index].lastIndex(where: { $0 == "(" || $0 == "（" })
        else {
            throw parseError
        }
        let line = lines[index]
        let date = line[line.index(after: opening)..<line.index(before: line.endIndex)]
        let label = index == 0 ? String(line[..<opening]).trim() : lines[0]
        guard !label.isEmpty, let type = ScheduleWeekType.allCases.first(where: { date.hasSuffix($0.rawValue) }) else {
            throw parseError
        }
        let weekText = String(date.dropLast(type.rawValue.count)).trim()
        guard let weeks = try? parseScheduleWeeks(weekText, type: type), !weeks.isEmpty else {
            throw parseError
        }
        let matchingWeeks = Set(weeks.filter(type.includes)).sorted()
        guard let firstWeek = matchingWeeks.first, firstWeek > 0 else {
            throw parseError
        }
        return (label, matchingWeeks)
    }
}
