import Alamofire

/// 教务助手
public class EduHelper: BaseHelper {
    internal override func validateLoginResponse<T>(_ response: T) throws {
        guard let html = response as? String else { return }
        if html.contains("请输入账号") || isWebVpnLoginPage(html) {
            throw EduHelperError.notLoggedIn
        }
    }

    internal override var requestInterceptor: (any RequestInterceptor)? {
        return EmptyBodyRetryInterceptor()
    }

    public override func isLoggedIn() async -> Bool {
        return (try? await getProfile()) != nil
    }
}
