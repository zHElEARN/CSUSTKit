import Foundation

extension EduHelper {
    /// 教务助手相关错误
    public enum EduHelperError: Error, LocalizedError {
        /// 登录失败
        case loginFailed(String)
        /// 个人信息获取失败
        case profileRetrievalFailed(String)
        /// 未登录
        case notLoggedIn
        /// 考试安排获取失败
        case examScheduleRetrievalFailed(String)
        /// 考试安排可选学期获取失败
        case availableSemestersForExamScheduleRetrievalFailed(String)
        /// 课程成绩获取失败
        case courseGradesRetrievalFailed(String)
        /// 课程成绩可选学期获取失败
        case availableSemestersForCourseGradesRetrievalFailed(String)
        /// 成绩详情获取失败
        case gradeDetailRetrievalFailed(String)
        /// 课程表获取失败
        case courseScheduleRetrievalFailed(String)
        /// 课程表可选学期获取失败
        case availableSemestersForCourseScheduleRetrievalFailed(String)
        /// 学期开始日期获取失败
        case semesterStartDateRetrievalFailed(String)
        /// 开始日期可选学期获取失败
        case availableSemestersForStartDateRetrievalFailed(String)
        /// 日期解析失败
        case dateParsingFailed(String)
        /// 指定校区在指定时间内空闲的教室列表获取失败
        case availableClassroomsRetrievalFailed(String)

        /// 错误描述
        public var errorDescription: String? {
            switch self {
            case .loginFailed(let message):
                return "登录失败: \(message)"
            case .profileRetrievalFailed(let message):
                return "个人信息获取失败: \(message)"
            case .notLoggedIn:
                return "教务系统未登录"
            case .examScheduleRetrievalFailed(let message):
                return "考试安排获取失败: \(message)"
            case .availableSemestersForExamScheduleRetrievalFailed(let message):
                return "考试安排可选学期获取失败: \(message)"
            case .courseGradesRetrievalFailed(let message):
                return "课程成绩获取失败: \(message)"
            case .availableSemestersForCourseGradesRetrievalFailed(let message):
                return "课程成绩可选学期获取失败: \(message)"
            case .gradeDetailRetrievalFailed(let message):
                return "成绩详情获取失败: \(message)"
            case .courseScheduleRetrievalFailed(let message):
                return "课程表获取失败: \(message)"
            case .availableSemestersForCourseScheduleRetrievalFailed(let message):
                return "课程表可选学期获取失败: \(message)"
            case .semesterStartDateRetrievalFailed(let message):
                return "学期开始日期获取失败: \(message)"
            case .availableSemestersForStartDateRetrievalFailed(let message):
                return "开始日期可选学期获取失败: \(message)"
            case .dateParsingFailed(let message):
                return "日期解析失败: \(message)"
            case .availableClassroomsRetrievalFailed(let message):
                return "指定校区在指定时间内空闲的教室列表获取失败: \(message)"
            }
        }
    }
}
