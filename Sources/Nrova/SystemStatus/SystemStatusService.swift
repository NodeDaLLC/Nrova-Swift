import Foundation

/// Client for the **Nrova System Status API**
/// (`https://us-central1-nrovallc.cloudfunctions.net/systemStatusApi`).
public struct SystemStatusService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)/status"
    }

    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `GET …/status` — rollup + components, sorted by sortOrder then name.
    public func rollup() async throws -> SystemStatusRollup {
        try await http.get(base())
    }

    /// `GET …/status/components/{componentId}`.
    public func getComponent(componentId: String) async throws -> SystemStatusComponent {
        let envelope: SystemStatusComponentResponse = try await http.get("\(base())/components/\(componentId)")
        return envelope.component
    }

    /// `POST …/status/components` — requires `status:write`.
    public func createComponent(_ request: CreateStatusComponentRequest) async throws -> SystemStatusComponent {
        let envelope: SystemStatusComponentResponse = try await http.post(
            "\(base())/components",
            body: request
        )
        return envelope.component
    }

    /// `PUT …/status/components/{componentId}` — requires `status:write`.
    public func updateComponent(
        componentId: String,
        update: UpdateStatusComponentRequest
    ) async throws -> SystemStatusComponent {
        let envelope: SystemStatusComponentResponse = try await http.put(
            "\(base())/components/\(componentId)",
            body: update
        )
        return envelope.component
    }

    /// `DELETE …/status/components/{componentId}` — requires `status:write`.
    public func deleteComponent(componentId: String) async throws {
        try await http.delete("\(base())/components/\(componentId)")
    }
}
