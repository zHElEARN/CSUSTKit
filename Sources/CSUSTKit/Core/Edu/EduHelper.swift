import Alamofire
import Foundation
import SwiftSoup

/// 教务助手
public class EduHelper: BaseHelper {
    /// 认证服务
    public let authService: AuthService
    /// 课程服务
    public let courseService: CourseService
    /// 考试服务
    public let examService: ExamService
    /// 个人档案服务
    public let profileService: ProfileService
    /// 学期服务
    public let semesterService: SemesterService

    override public init(mode: ConnectionMode = .direct, session: Session = Session()) {
        authService = AuthService(mode: mode, session: session)
        courseService = CourseService(mode: mode, session: session)
        examService = ExamService(mode: mode, session: session)
        profileService = ProfileService(mode: mode, session: session)
        semesterService = SemesterService(mode: mode, session: session)
        super.init(mode: mode, session: session)
    }

    public override func isLoggedIn() async -> Bool {
        return (try? await profileService.getProfile()) != nil
    }
}
