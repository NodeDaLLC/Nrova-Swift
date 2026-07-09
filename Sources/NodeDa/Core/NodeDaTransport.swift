import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Minimal protocol the SDK uses to perform HTTP requests. Conforming
/// types can be substituted in tests to replay canned responses.
public protocol NodeDaTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NodeDaTransport {
    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
        #else
        return try await data(for: request)
        #endif
    }
}
