import Foundation

/// Errors surfaced by the Nrova SDK.
///
/// Server-shaped errors (4xx / 5xx with a JSON body) are mapped to
/// ``NrovaError/api(_:)`` so callers can inspect the documented
/// `error` slug (`invalid_api_key`, `not_found`, …) without having to
/// parse the body themselves.
public enum NrovaError: Error, Sendable {
    /// Request URL could not be constructed (programmer error / bad input).
    case invalidURL(String)

    /// The underlying URLSession transport threw.
    case transport(Error)

    /// The server returned a non-success status with a structured payload.
    case api(APIError)

    /// JSON decoding of a successful response failed.
    case decoding(Error, data: Data?)

    /// The server returned an HTTP status code we don't know how to interpret.
    case unexpectedStatus(Int, data: Data?)

    /// Structured payload returned by every Nrova Cloud Function on failure.
    public struct APIError: Error, Sendable, Equatable, Codable {
        /// HTTP status that accompanied the payload (e.g. 400, 404, 503).
        public let status: Int
        /// Stable slug from the docs (`invalid_api_key`, `not_found`, …).
        public let code: String
        /// Optional human-readable description provided by the function.
        public let message: String?
        /// Additional fields the function included in the body, JSON-encoded.
        public let details: [String: JSONValue]?

        public init(
            status: Int,
            code: String,
            message: String? = nil,
            details: [String: JSONValue]? = nil
        ) {
            self.status = status
            self.code = code
            self.message = message
            self.details = details
        }
    }
}

extension NrovaError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let raw):
            return "Could not build a valid URL from \(raw)."
        case .transport(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .api(let apiError):
            if let message = apiError.message, !message.isEmpty {
                return "[\(apiError.status) \(apiError.code)] \(message)"
            }
            return "[\(apiError.status) \(apiError.code)]"
        case .decoding(let underlying, _):
            return "Failed to decode Nrova response: \(underlying.localizedDescription)"
        case .unexpectedStatus(let status, _):
            return "Unexpected HTTP status \(status)."
        }
    }
}
