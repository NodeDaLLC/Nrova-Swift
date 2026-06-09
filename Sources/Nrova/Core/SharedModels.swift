import Foundation

/// Response returned by every `GET /health` endpoint across Nrova services.
public struct HealthResponse: Codable, Sendable, Equatable {
    public let ok: Bool
    public let service: String?
}
