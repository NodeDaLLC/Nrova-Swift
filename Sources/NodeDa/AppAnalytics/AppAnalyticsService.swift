import Foundation

/// Client for the **NodeDa Vertex App Analytics ingest API**
/// (`https://api.nodeda.com` — schema `nrova.app-analytics.v1`).
///
/// POST session batches to `/v1/organizations/{orgId}/app-analytics/events`.
/// Apps auto-register from `bundleId`. Requires a developer API key with the
/// ``AppAnalyticsScope/write`` (`app-analytics:write`) scope.
/// `app-analytics:read` cannot ingest. `GET /health` needs no key.
///
/// Country and region are resolved server-side from the request IP. Never
/// send a raw IP or user identity.
///
/// ```swift
/// let result = try await client.appAnalytics.ingest(
///     bundleId: Bundle.main.bundleIdentifier ?? "com.example.notes",
///     platform: .current,
///     installId: AppAnalyticsOpaqueId.generate(),
///     sessionId: AppAnalyticsOpaqueId.generate(),
///     events: [
///         .sessionStart(),
///         .screen("Home"),
///         .heartbeat(foregroundDurationMs: 120_000)
///     ]
/// )
/// print(result.appId ?? "", result.qualifiedActive ?? false)
/// ```
public struct AppAnalyticsService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)/app-analytics"
    }

    /// `GET /health` — does not require an API key.
    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `POST …/app-analytics/events` — requires `app-analytics:write`.
    @discardableResult
    public func ingest(
        _ request: AppAnalyticsIngestRequest
    ) async throws -> AppAnalyticsIngestResponse {
        try await http.post("\(base())/events", body: request)
    }

    /// Sugar for ``ingest(_:)``.
    @discardableResult
    public func ingest(
        bundleId: String,
        platform: AppAnalyticsPlatform,
        installId: String,
        sessionId: String,
        events: [AppAnalyticsEvent],
        sdk: AppAnalyticsSDK? = .current,
        appVersion: String? = nil,
        osVersion: String? = nil,
        activeUserThresholdSeconds: Int? = nil
    ) async throws -> AppAnalyticsIngestResponse {
        try await ingest(
            AppAnalyticsIngestRequest(
                bundleId: bundleId,
                platform: platform,
                installId: installId,
                sessionId: sessionId,
                events: events,
                sdk: sdk,
                appVersion: appVersion,
                osVersion: osVersion,
                activeUserThresholdSeconds: activeUserThresholdSeconds
            )
        )
    }
}
