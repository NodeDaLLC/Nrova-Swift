import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Client for the **NodeDa Vertex Distribution API**
/// (`https://api.nodeda.com`).
///
/// Endpoints covered:
/// * `GET /health`
/// * `GET /v1/organizations/{orgId}/applications/public` (no auth)
/// * `GET /v1/organizations/{orgId}/applications`
/// * `GET /v1/organizations/{orgId}/applications/{appId}`
/// * `GET /v1/organizations/{orgId}/applications/{appId}/releases`
/// * `GET /v1/organizations/{orgId}/applications/{appId}/releases/{releaseId}`
/// * `GET /v1/organizations/{orgId}/applications/{appId}/latest`
/// * `GET /v1/organizations/{orgId}/applications/{appId}/download` (302)
/// * `GET /v1/organizations/{orgId}/applications/{appId}/icon` (302 or JSON)
/// * `POST /v1/organizations/{orgId}/applications/{appId}/releases`
/// * `PATCH /v1/organizations/{orgId}/applications/{appId}/releases/{releaseId}`
public struct DistributionService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)/applications"
    }

    // MARK: - Health

    /// `GET /health` — does not require an API key.
    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    // MARK: - Listing

    /// Unauthenticated public app feed
    /// (`GET /v1/organizations/{orgId}/applications/public`).
    public func listPublicApplications() async throws -> DistributionApplicationsResponse {
        try await http.get("\(base())/public", authenticated: false)
    }

    /// `GET …/applications` — requires `distribution:read`.
    public func listApplications() async throws -> DistributionApplicationsResponse {
        try await http.get(base())
    }

    /// `GET …/applications/{appId}` — requires `distribution:read`.
    public func getApplication(appId: String) async throws -> DistributionApplication {
        let envelope: DistributionApplicationResponse = try await http.get("\(base())/\(appId)")
        return envelope.application
    }

    // MARK: - Releases

    /// `GET …/applications/{appId}/releases` — optional channel / platform / limit filters.
    public func listReleases(
        appId: String,
        channel: DistributionChannel? = nil,
        platform: DistributionPlatform? = nil,
        limit: Int? = nil
    ) async throws -> [DistributionRelease] {
        let query: [String: String?] = [
            "channel": channel?.rawValue,
            "platform": platform?.rawValue,
            "limit": limit.map(String.init)
        ]
        let envelope: DistributionReleasesResponse = try await http.get("\(base())/\(appId)/releases", query: query)
        return envelope.releases
    }

    /// `GET …/applications/{appId}/releases/{releaseId}`.
    public func getRelease(appId: String, releaseId: String) async throws -> DistributionRelease {
        let envelope: DistributionReleaseResponse = try await http.get("\(base())/\(appId)/releases/\(releaseId)")
        return envelope.release
    }

    /// `GET …/applications/{appId}/latest` — resolves the latest release for
    /// the requested `platform` + `channel`, optionally narrowing to
    /// `install` or `update` artifacts.
    public func latest(
        appId: String,
        platform: DistributionPlatform,
        channel: DistributionChannel = .stable,
        purpose: DistributionArtifactPurpose? = nil
    ) async throws -> DistributionLatestResponse {
        let query: [String: String?] = [
            "platform": platform.rawValue,
            "channel": channel.rawValue,
            "purpose": purpose?.rawValue
        ]
        return try await http.get("\(base())/\(appId)/latest", query: query)
    }

    // MARK: - Convenience 302 helpers

    /// Resolves the final download URL for the `GET …/download` endpoint by
    /// reading the `Location` header from its 302 response. Does **not**
    /// actually fetch the binary bytes — that's left to the caller.
    public func resolveDownloadURL(
        appId: String,
        platform: DistributionPlatform,
        channel: DistributionChannel = .stable,
        purpose: DistributionArtifactPurpose = .install
    ) async throws -> URL {
        let query: [String: String?] = [
            "platform": platform.rawValue,
            "channel": channel.rawValue,
            "purpose": purpose.rawValue
        ]
        let (_, response) = try await http.head("\(base())/\(appId)/download", query: query)
        guard let location = response.value(forHTTPHeaderField: "Location"),
              let url = URL(string: location) else {
            throw NodeDaError.unexpectedStatus(response.statusCode, data: nil)
        }
        return url
    }

    /// Returns the public icon URL for an app.
    ///
    /// - Parameter format: `.json` (default) returns the typed JSON payload;
    ///   `.redirect` follows the underlying 302 and returns the resolved URL.
    public func icon(
        appId: String,
        format: IconFormat = .json
    ) async throws -> DistributionIconResponse {
        switch format {
        case .json:
            return try await http.get("\(base())/\(appId)/icon", query: ["format": "json"])
        case .redirect:
            let (_, response) = try await http.head("\(base())/\(appId)/icon")
            guard let location = response.value(forHTTPHeaderField: "Location") else {
                throw NodeDaError.unexpectedStatus(response.statusCode, data: nil)
            }
            return DistributionIconResponse(schema: nil, appId: appId, iconUrl: location, iconStoragePath: nil)
        }
    }

    public enum IconFormat: Sendable {
        case json
        case redirect
    }

    // MARK: - Mutations

    /// `POST …/applications/{appId}/releases` — requires `distribution:write`.
    public func publishRelease(
        appId: String,
        request: PublishReleaseRequest
    ) async throws -> DistributionRelease {
        let envelope: DistributionReleaseResponse = try await http.post(
            "\(base())/\(appId)/releases",
            body: request
        )
        return envelope.release
    }

    /// `PATCH …/applications/{appId}/releases/{releaseId}` — update notes or
    /// yank the release. Requires `distribution:write`.
    public func updateRelease(
        appId: String,
        releaseId: String,
        update: UpdateReleaseRequest
    ) async throws -> DistributionRelease {
        let envelope: DistributionReleaseResponse = try await http.patch(
            "\(base())/\(appId)/releases/\(releaseId)",
            body: update
        )
        return envelope.release
    }
}
