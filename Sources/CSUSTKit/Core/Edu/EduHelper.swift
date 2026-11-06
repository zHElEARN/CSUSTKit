import Alamofire
import Foundation

/// 教务助手
public class EduHelper: BaseHelper {
    internal override var notLoggedInError: (any Error)? { EduHelperError.notLoggedIn }

    internal override func isSubsystemLoginResponse(_ body: String, finalURL: URL) -> Bool {
        body.contains("请输入账号")
    }

    internal override var requestInterceptor: (any RequestInterceptor)? {
        return EmptyBodyRetryInterceptor()
    }

    public override func isLoggedIn() async -> Bool {
        return (try? await getProfile()) != nil
    }
}
