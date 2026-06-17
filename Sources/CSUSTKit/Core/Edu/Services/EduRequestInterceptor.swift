import Alamofire

extension EduHelper {
    public struct EduRequestInterceptor: RequestInterceptor {
        private let maxRetryCount: Int

        public init(maxRetryCount: Int = 5) {
            self.maxRetryCount = maxRetryCount
        }

        public func retry(_ request: Request, for session: Session, dueTo error: any Error, completion: @escaping (RetryResult) -> Void) {
            if let afError = error as? AFError,
                case .responseSerializationFailed(let reason) = afError,
                case .inputDataNilOrZeroLength = reason
            {
                let retryCount = request.retryCount
                debugPrint("Retrying request \(request) due to serialization failure. Attempt \(retryCount + 1) of \(maxRetryCount).")
                if retryCount < maxRetryCount {
                    completion(.retryWithDelay(1.0))
                } else {
                    completion(.doNotRetry)
                }
                return
            }
            completion(.doNotRetry)
        }
    }
}
