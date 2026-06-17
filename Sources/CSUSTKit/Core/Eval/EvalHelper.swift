public class EvalHelper: BaseHelper {
    public var token: String?

    public override func isLoggedIn() async -> Bool {
        return true
    }

    private struct BaseResponse<T: Codable & Sendable>: Codable, Sendable {
        let code: Int
        let message: String
        let data: T?
    }

    private struct TokenResponse: Codable {
        let accessToken: String
    }

    private struct ProfileResponse: Codable {
        struct Wrapper: Codable {
            let userid: Int
            let loginname: String
            let realname: String
        }
        let data: Wrapper
    }

    private struct EvalListResponse: Codable {
        struct PageData: Codable {
            let taskname: String
            let starttime: String
            let migrationstatus: Int
            let sfpjwc: String
            let weeklytask: String
            let sl: String
            let taskfbfs: String
            let taskid: Int
            let evalcoursesnumber: String
            let objecttask: String
            let currentStatus: String
            let endtime: String
            let sfqxzdf: String
            let sfkydcpj: String
            let hjjstask: Int
            let qzqmtask: String
            let yearterm: Int
            let pjfs: String
            let sfqxzdzgf: String
            let indexid: String
            let status: Int
        }

        let pageData: [PageData]
    }

    private struct EvalCoursesResponse: Codable {
        struct PageData: Codable {
            let courseorgcode: String
            let coursename: String
            let studentname: String
            let yearterm: Int
            let courseorgname: String
            let studentid: String
            let jobnumber: String
            let teachername: String
            let hassubmit: Int
            let coursecode: String
            let classno: String
            let id: Int
            let pjcoursetype: String

            let pjjgid: Int?
            let pjjgtime: String?
        }

        let pageData: [PageData]
    }

    public func syncToken(ticket: String) async throws {
        let response = try await session.request(
            factory.make(.eval, "/api/manage/cas/doLogin?userToken=\(ticket)"),
            method: .post
        )
        .decodable(BaseResponse<TokenResponse>.self)

        guard response.code == 200,
            let data = response.data
        else {
            throw EvalHelperError.syncTokenFailed(response.message)
        }

        self.token = data.accessToken
    }

    public func getProfile() async throws -> Profile {
        guard let token else {
            throw EvalHelperError.notLoggedIn
        }

        let headers = [
            "Authorization": "Bearer\(token)"
        ]

        let response = try await session.request(
            factory.make(.eval, "/api/manage/common/getCurrenUser"),
            headers: .init(headers)
        )
        .decodable(BaseResponse<ProfileResponse>.self)

        guard response.code == 0,
            let data = response.data
        else {
            throw EvalHelperError.profileRetrievalFailed(response.message)
        }

        return Profile(userId: data.data.userid, loginName: data.data.loginname, realName: data.data.realname)
    }

    public func getEvals() async throws {
        guard let token else {
            throw EvalHelperError.notLoggedIn
        }

        let headers = [
            "Authorization": "Bearer\(token)"
        ]

        let response = try await session.request(
            factory.make(.eval, "/api/xspj/xspj/getXspjtask"),
            method: .post,
            headers: .init(headers)
        )
        .decodable(BaseResponse<EvalListResponse>.self)

        guard response.code == 200,
            let data = response.data
        else {
            throw EvalHelperError.evalsRetrievalFailed(response.message)
        }

        print(data)
    }

    public func getEvalCourses(id: String) async throws {
        guard let token else {
            throw EvalHelperError.notLoggedIn
        }

        let headers = [
            "Authorization": "Bearer\(token)"
        ]

        let response = try await session.request(
            factory.make(.eval, "/api/xspj/xspj/getXspjStudentCourses?taskid=\(id)"),
            method: .post,
            headers: .init(headers)
        )
        .decodable(BaseResponse<EvalCoursesResponse>.self)

        guard response.code == 200,
            let data = response.data
        else {
            throw EvalHelperError.evalCoursesRetrievalFailed(response.message)
        }

        print(data)
    }
}
