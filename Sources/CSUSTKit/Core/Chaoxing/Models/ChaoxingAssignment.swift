import Foundation

extension ChaoxingHelper {
    /// 作业
    public struct Assignment: BaseModel {
        /// 作业名称
        public let title: String
        /// 是否已完成
        public let isCompleted: Bool
        /// 所属课程
        public let courseName: String
        /// 截止时间
        public let deadline: Date?
        /// 作业图标链接
        public let iconURL: String
        /// 详情页链接
        public let detailURL: String

        public init(
            title: String,
            isCompleted: Bool,
            courseName: String,
            deadline: Date?,
            iconURL: String,
            detailURL: String
        ) {
            self.title = title
            self.isCompleted = isCompleted
            self.courseName = courseName
            self.deadline = deadline
            self.iconURL = iconURL
            self.detailURL = detailURL
        }
    }
}
