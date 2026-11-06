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
        try await perform(
            url, method, parameters,
            headers: headers,
            serializer: StringResponseSerializer(encoding: stringEncoding),
            validateLogin: validateLogin,
            responseText: { $0 }
        ).result.get()
    }

    internal func performDecodableRequest<T: Decodable & Sendable>(
        _ url: String,
        _ method: HTTPMethod = .get,
        _ parameters: [String: String]? = nil,
        headers: HTTPHeaders? = nil,
        validateLogin: Bool = true
    ) async throws -> T {
        let response = try await perform(
            url, method, parameters,
            headers: headers,
            serializer: DataResponseSerializer(),
            validateLogin: validateLogin
        )
        return try DecodableResponseSerializer<T>().serialize(
            request: response.request,
            response: response.response,
            data: response.result.get(),
            error: nil
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
        try await perform(
            url, method, parameters,
            headers: headers,
            serializer: StringResponseSerializer(encoding: stringEncoding),
            validateLogin: validateLogin,
            responseText: { $0 }
        )
    }

    @discardableResult
    internal func performDataRequest(
        _ url: String,
        _ method: HTTPMethod = .get,
        _ parameters: [String: String]? = nil,
        headers: HTTPHeaders? = nil,
        validateLogin: Bool = true
    ) async throws -> Data {
        try await perform(
            url, method, parameters,
            headers: headers,
            serializer: DataResponseSerializer(),
            validateLogin: validateLogin
        ).result.get()
    }

    private func perform<Serializer: ResponseSerializer>(
        _ url: String,
        _ method: HTTPMethod,
        _ parameters: [String: String]?,
        headers: HTTPHeaders?,
        serializer: Serializer,
        validateLogin: Bool,
        responseText: (Serializer.SerializedObject) -> String? = { _ in nil }
    ) async throws -> DataResponse<Serializer.SerializedObject, AFError> {
        let response = await session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            interceptor: requestInterceptor
        ).serializingResponse(using: serializer).response

        guard validateLogin, let httpResponse = response.response, let finalURL = httpResponse.url,
            response.error == nil || response.error?.isResponseSerializationError == true
        else { return response }

        // 网关可能返回与子系统指定编码不同的页面。没有可用正文时，按响应编码尝试读取。
        let text =
            response.value.flatMap(responseText)
            ?? (try? StringResponseSerializer(encoding: httpResponse.textEncodingName == nil ? .utf8 : nil).serialize(
                request: response.request,
                response: httpResponse,
                data: response.data,
                error: nil
            ))
        try validateLoginResponse(text ?? "", finalURL: finalURL)
        return response
    }
}
