import Alamofire
import Foundation

extension URL {
    init(_ string: String) {
        self = URL(string: string)!
    }
}

extension DataRequest {
    func string(_ encoding: String.Encoding? = nil) async throws -> String {
        return try await self.serializingString(encoding: encoding).value
    }

    @discardableResult
    func data() async throws -> Data {
        return try await self.serializingData().value
    }

    func decodable<T: Decodable & Sendable>(_ type: T.Type) async throws -> T {
        return try await self.serializingDecodable(T.self).value
    }
}
