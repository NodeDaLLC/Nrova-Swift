import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Internal HTTP plumbing shared by every service client. Handles base-URL
/// composition, query-string encoding, Bearer + `X-API-Key` auth headers,
/// JSON encoding/decoding, and the documented error payload shape.
struct HTTPClient: Sendable {
    let baseURL: URL
    let configuration: NrovaConfiguration
    let transport: NrovaTransport
    let requiresAuth: Bool

    init(
        baseURL: URL,
        configuration: NrovaConfiguration,
        transport: NrovaTransport,
        requiresAuth: Bool = true
    ) {
        self.baseURL = baseURL
        self.configuration = configuration
        self.transport = transport
        self.requiresAuth = requiresAuth
    }

    // MARK: - Decoders / encoders

    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    // MARK: - Public request entry points

    func get<Response: Decodable>(
        _ path: String,
        query: [String: String?] = [:],
        as type: Response.Type = Response.self,
        authenticated: Bool = true
    ) async throws -> Response {
        let request = try buildRequest(method: "GET", path: path, query: query, body: nil, authenticated: authenticated)
        return try await perform(request)
    }

    @discardableResult
    func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        query: [String: String?] = [:],
        body: Body,
        as type: Response.Type = Response.self,
        authenticated: Bool = true
    ) async throws -> Response {
        let data = try Self.jsonEncoder.encode(body)
        let request = try buildRequest(method: "POST", path: path, query: query, body: data, authenticated: authenticated)
        return try await perform(request)
    }

    @discardableResult
    func patch<Body: Encodable, Response: Decodable>(
        _ path: String,
        query: [String: String?] = [:],
        body: Body,
        as type: Response.Type = Response.self,
        authenticated: Bool = true
    ) async throws -> Response {
        let data = try Self.jsonEncoder.encode(body)
        let request = try buildRequest(method: "PATCH", path: path, query: query, body: data, authenticated: authenticated)
        return try await perform(request)
    }

    @discardableResult
    func put<Body: Encodable, Response: Decodable>(
        _ path: String,
        query: [String: String?] = [:],
        body: Body,
        as type: Response.Type = Response.self,
        authenticated: Bool = true
    ) async throws -> Response {
        let data = try Self.jsonEncoder.encode(body)
        let request = try buildRequest(method: "PUT", path: path, query: query, body: data, authenticated: authenticated)
        return try await perform(request)
    }

    func delete(
        _ path: String,
        query: [String: String?] = [:],
        authenticated: Bool = true
    ) async throws {
        let request = try buildRequest(method: "DELETE", path: path, query: query, body: nil, authenticated: authenticated)
        let (data, response) = try await transport.send(request)
        try Self.validate(response: response, data: data)
    }

    // MARK: - Redirect-following helpers (for the 302 endpoints)

    /// Returns the underlying HTTPURLResponse from a request, useful when
    /// the API answers with a 302 redirect (download / icon helpers).
    func head(
        _ path: String,
        query: [String: String?] = [:],
        authenticated: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        let request = try buildRequest(method: "GET", path: path, query: query, body: nil, authenticated: authenticated)
        let (data, response) = try await transport.send(request)
        guard let http = response as? HTTPURLResponse else {
            throw NrovaError.unexpectedStatus(-1, data: data)
        }
        return (data, http)
    }

    // MARK: - Request building

    private func buildRequest(
        method: String,
        path: String,
        query: [String: String?],
        body: Data?,
        authenticated: Bool
    ) throws -> URLRequest {
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        let fullURL = baseURL.appendingPathComponent(normalizedPath, isDirectory: false)

        guard var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false) else {
            throw NrovaError.invalidURL(fullURL.absoluteString)
        }

        // appendingPathComponent percent-encodes everything; keep raw `/` and
        // double-decoded characters by reconstructing from the joined string.
        components.path = (baseURL.path + normalizedPath)
            .replacingOccurrences(of: "//", with: "/")

        let filteredQuery = query.compactMapValues { $0 }
        if !filteredQuery.isEmpty {
            components.queryItems = filteredQuery.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            throw NrovaError.invalidURL(fullURL.absoluteString)
        }

        var request = URLRequest(url: url, timeoutInterval: configuration.timeout)
        request.httpMethod = method
        request.httpBody = body

        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if authenticated && requiresAuth && !configuration.apiKey.isEmpty {
            request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue(configuration.apiKey, forHTTPHeaderField: "X-API-Key")
        }

        for (key, value) in configuration.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    // MARK: - Response handling

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await transport.send(request)
        } catch {
            throw NrovaError.transport(error)
        }

        try Self.validate(response: response, data: data)

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }
        do {
            return try Self.jsonDecoder.decode(Response.self, from: data)
        } catch {
            throw NrovaError.decoding(error, data: data)
        }
    }

    static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NrovaError.unexpectedStatus(-1, data: data)
        }
        guard (200..<300).contains(http.statusCode) else {
            if let apiError = try? Self.decodeAPIError(status: http.statusCode, data: data) {
                throw NrovaError.api(apiError)
            }
            throw NrovaError.unexpectedStatus(http.statusCode, data: data)
        }
    }

    static func decodeAPIError(status: Int, data: Data) throws -> NrovaError.APIError? {
        guard !data.isEmpty else { return nil }
        struct Envelope: Decodable {
            let error: String?
            let code: String?
            let message: String?
            let details: [String: JSONValue]?
        }
        let envelope = try jsonDecoder.decode(Envelope.self, from: data)
        let code = envelope.error ?? envelope.code ?? "unknown_error"
        return NrovaError.APIError(
            status: status,
            code: code,
            message: envelope.message,
            details: envelope.details
        )
    }
}

/// Placeholder used by endpoints (currently the `DELETE` family) that
/// don't return a structured body.
public struct EmptyResponse: Decodable, Sendable {
    public init() {}
}
