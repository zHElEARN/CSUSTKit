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
            try validateLoginResponse(response)
        }
        return response
    }

    internal func performDecodableRequest<T: Decodable & Sendable>(
        _ url: String,
        _ method: HTTPMethod = .get,
        _ parameters: [String: String]? = nil,
        headers: HTTPHeaders? = nil,
        validateLogin: Bool = true
    ) async throws -> T {
        let response = await session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            interceptor: self.requestInterceptor
        ).serializingData().response

        if validateLogin,
            let data = response.data,
            let text = String(data: data, encoding: .utf8),
            !text.isEmpty
        {
            try validateLoginResponse(text)
        }

        return try DecodableResponseSerializer<T>().serialize(
            request: response.request,
            response: response.response,
            data: response.data,
            error: response.error
        )
    }

    internal func performResponseRequest(
        _ url: String,
        _ method: HTTPMethod = .get,
        _ parameters: [String: String]? = nil,
        headers: HTTPHeaders? = nil,
        stringEncoding: String.Encoding? = nil,
        validateLogin: Bool = true
    ) async throws -> DataResponse<String, AFError> {
        let response = await session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            interceptor: self.requestInterceptor
        ).serializingString(encoding: stringEncoding).response
        if validateLogin {
            try validateLoginResponse(response)
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
