import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import NodeDa

/// Test transport that returns canned responses. Each invocation passes the
/// outgoing `URLRequest` to the supplied `responder` closure so tests can
/// assert on URL composition, headers, and request bodies.
final class MockTransport: NodeDaTransport, @unchecked Sendable {
    typealias Responder = (URLRequest) throws -> (Data, URLResponse)

    private let responder: Responder

    init(responder: @escaping Responder = MockTransport.defaultResponder) {
        self.responder = responder
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try responder(request)
    }

    static func defaultResponder(_ request: URLRequest) -> (Data, URLResponse) {
        (Data("{}".utf8), response(for: request, status: 200))
    }

    static func response(for request: URLRequest, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}
