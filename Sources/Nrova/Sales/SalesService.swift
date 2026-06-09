import Foundation

/// Client for the **Nrova Sales API**
/// (`https://us-central1-nrovallc.cloudfunctions.net/crmSalesApi`).
public struct SalesService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)/sales"
    }

    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `POST …/sales/submissions`.
    public func createSubmission(_ request: CreateSalesSubmissionRequest) async throws -> SalesSubmission {
        let envelope: SalesSubmissionResponse = try await http.post("\(base())/submissions", body: request)
        return envelope.submission
    }

    /// `GET …/sales/submissions?contactEmail=…&limit=…`.
    public func listSubmissions(
        contactEmail: String,
        limit: Int? = nil
    ) async throws -> [SalesSubmission] {
        let envelope: SalesSubmissionsResponse = try await http.get(
            "\(base())/submissions",
            query: [
                "contactEmail": contactEmail,
                "limit": limit.map(String.init)
            ]
        )
        return envelope.submissions
    }

    /// `GET …/sales/submissions/{submissionId}`.
    public func getSubmission(submissionId: String) async throws -> SalesSubmission {
        let envelope: SalesSubmissionResponse = try await http.get("\(base())/submissions/\(submissionId)")
        return envelope.submission
    }

    /// `GET …/sales/submissions/{submissionId}/comments`.
    public func listComments(submissionId: String) async throws -> [SalesComment] {
        let envelope: SalesCommentsResponse = try await http.get("\(base())/submissions/\(submissionId)/comments")
        return envelope.comments
    }

    /// `POST …/sales/submissions/{submissionId}/comments`.
    public func addComment(
        submissionId: String,
        request: CreateSalesCommentRequest
    ) async throws -> SalesComment {
        let envelope: SalesCommentResponse = try await http.post(
            "\(base())/submissions/\(submissionId)/comments",
            body: request
        )
        return envelope.comment
    }
}
