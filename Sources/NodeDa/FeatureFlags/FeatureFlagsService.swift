import Foundation

/// Client for the **NodeDa Vertex Feature Flags / Developer API**
/// (`https://api.nodeda.com`).
public struct FeatureFlagsService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)"
    }

    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `GET …/flags` — requires the `flags:read` scope.
    public func listFlags() async throws -> FeatureFlagsResponse {
        try await http.get("\(base())/flags")
    }

    /// `POST …/evaluate` — requires the `evaluate` scope. Returns a
    /// `[flagKey: Bool]` dictionary keyed by the flag key.
    public func evaluate(_ request: EvaluateFlagsRequest) async throws -> EvaluateFlagsResponse {
        try await http.post("\(base())/evaluate", body: request)
    }

    /// Convenience that evaluates a single subject and returns just the
    /// boolean result for the requested flag key.
    public func isEnabled(
        flagKey: String,
        subjectId: String,
        countryCode: String? = nil
    ) async throws -> Bool {
        let response = try await evaluate(
            EvaluateFlagsRequest(
                subjectId: subjectId,
                countryCode: countryCode,
                flagKeys: [flagKey]
            )
        )
        return response.results[flagKey] ?? false
    }
}
