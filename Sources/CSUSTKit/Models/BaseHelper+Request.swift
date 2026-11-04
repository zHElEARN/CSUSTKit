import Alamofire
import Foundation

extension BaseHelper {
    internal func performRequest(
        _ url: String,
        _ method: HTTPMethod = .get,
        _ parameters: [String: String]? = nil,
        headers: HTTPHeaders? = nil,
        stringEncoding: String.Encoding? = nil,
        validateLogin: Bool = true
    ) async throws -> String {
        let response = try await session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            interceptor: self.requestInterceptor
        ).string(stringEncoding)
        if validateLogin {
            try loginValidator?(response)
        }
        return response
    }

    @discardableResult
    internal func performDataRequest(
        _ url: String,
        _ method: HTTPMethod = .get,
        _ parameters: [String: String]? = nil,
        headers: HTTPHeaders? = nil
    ) async throws -> Data {
        try await session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            interceptor: self.requestInterceptor
        ).data()
    }
}
