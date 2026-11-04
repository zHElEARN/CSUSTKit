import Alamofire

extension BaseHelper {
    internal func performRequest(
        _ url: String,
        _ method: HTTPMethod = .get,
        _ parameters: [String: String]? = nil,
        headers: HTTPHeaders? = nil
    ) async throws -> String {
        let response = try await session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            interceptor: self.requestInterceptor
        ).string()
        try loginValidator?(response)
        return response
    }
}
