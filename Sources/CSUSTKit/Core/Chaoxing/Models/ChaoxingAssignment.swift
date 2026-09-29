import Foundation

extension ChaoxingHelper {
    /// 作业
    public struct Assignment: BaseModel {
        /// 作业名称
        public let title: String
        /// 作业状态，原样保留学习通返回的文本
        public let status: String
        /// 所属课程
        public let courseName: String
        /// 截止时间，学习通未给出剩余时间时为 nil
        public let deadline: Date?
        /// 作业图标链接
        public let iconURL: String
        /// 详情页链接
        public let detailURL: String

        /// 是否已完成
        public var isCompleted: Bool { status == "已完成" }

        public init(
            title: String,
            status: String,
            courseName: String,
            deadline: Date?,
            iconURL: String,
            detailURL: String
        ) {
            self.title = title
            self.status = status
            self.courseName = courseName
            self.deadline = deadline
            self.iconURL = iconURL
            self.detailURL = detailURL
        }
    }
}
