extension ChaoxingHelper {
    /// 作业状态
    public enum AssignmentStatus: String, CaseIterable, BaseModel {
        /// 未提交
        case unsubmitted = "未提交"
        /// 待批阅
        case pendingReview = "待批阅"
        /// 已完成
        case completed = "已完成"
    }
}
