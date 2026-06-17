extension EduHelper {
    /// 课程性质
    public enum CourseNature: String, CaseIterable, BaseModel {
        /// 其他
        case other = "其他"
        /// 公共课
        case publicCourse = "公共课"
        /// 公共基础课
        case publicBasicCourse = "公共基础课"
        /// 专业基础课
        case professionalBasicCourse = "专业基础课"
        /// 专业课
        case professionalCourse = "专业课"
        /// 专业选修课
        case professionalElectiveCourse = "专业选修课"
        /// 公共选修课
        case publicElectiveCourse = "公共选修课"
        /// 专业核心课
        case professionalCoreCourse = "专业核心课"
        /// 专业集中实践
        case professionalPracticalCourse = "专业集中实践"

        /// 课程性质ID
        var id: String {
            switch self {
            case .other:
                return "00"
            case .publicCourse:
                return "01"
            case .publicBasicCourse:
                return "02"
            case .professionalBasicCourse:
                return "03"
            case .professionalCourse:
                return "04"
            case .professionalElectiveCourse:
                return "05"
            case .publicElectiveCourse:
                return "06"
            case .professionalCoreCourse:
                return "07"
            case .professionalPracticalCourse:
                return "20"
            }
        }
    }
}
