import Alamofire

extension EduHelper {
    struct EmptyBodyRetryInterceptor: RequestInterceptor {
        private let maxRetryCount: Int = 5

        func retry(_ request: Request, for session: Session, dueTo error: any Error, completion: @escaping (RetryResult) -> Void) {
            if let afError = error as? AFError,
                case .responseSerializationFailed(let reason) = afError,
                case .inputDataNilOrZeroLength = reason
            {
                let retryCount = request.retryCount
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
