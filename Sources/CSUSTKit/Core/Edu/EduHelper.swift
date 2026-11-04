import Alamofire

/// 教务助手
public class EduHelper: BaseHelper {
    internal override var loginValidator: ((String) throws -> Void)? {
        return { html in
            if html.contains("请输入账号") {
                throw EduHelperError.notLoggedIn
            }
        }
    }

    internal override var requestInterceptor: (any RequestInterceptor)? {
        return EmptyBodyRetryInterceptor()
    }

    public override func isLoggedIn() async -> Bool {
        return (try? await getProfile()) != nil
    }
}
