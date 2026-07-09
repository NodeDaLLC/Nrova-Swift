import Foundation

/// Client for the **NodeDa Vertex Careers API**
/// (`https://api.nodeda.com`).
public struct CareersService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)/careers"
    }

    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `GET …/careers/postings`.
    public func listPostings() async throws -> [CareerPosting] {
        let envelope: CareerPostingsResponse = try await http.get("\(base())/postings")
        return envelope.postings
    }

    /// `GET …/careers/postings/{requisitionNodeId}`.
    public func getPosting(requisitionNodeId: String) async throws -> CareerPosting {
        let envelope: CareerPostingResponse = try await http.get("\(base())/postings/\(requisitionNodeId)")
        return envelope.posting
    }

    /// `GET …/careers/application-template` — sections + field ids for the
    /// dynamic application form.
    public func applicationTemplate() async throws -> CareerApplicationTemplate {
        let envelope: CareerApplicationTemplateResponse = try await http.get("\(base())/application-template")
        return envelope.template
    }

    /// `GET …/careers/applications`.
    public func listApplications(
        applicantEmail: String? = nil,
        contactEmail: String? = nil,
        status: String? = nil,
        limit: Int? = nil
    ) async throws -> [CareerApplication] {
        let envelope: CareerApplicationsResponse = try await http.get(
            "\(base())/applications",
            query: [
                "applicantEmail": applicantEmail,
                "contactEmail": contactEmail,
                "status": status,
                "limit": limit.map(String.init)
            ]
        )
        return envelope.applications
    }

    /// `GET …/careers/applications/{applicationId}`.
    public func getApplication(applicationId: String) async throws -> CareerApplication {
        let envelope: CareerApplicationResponse = try await http.get("\(base())/applications/\(applicationId)")
        return envelope.application
    }

    /// `POST …/careers/applications` — requires `careers:apply`.
    public func submitApplication(_ request: SubmitCareerApplicationRequest) async throws -> CareerApplication {
        let envelope: CareerApplicationResponse = try await http.post(
            "\(base())/applications",
            body: request
        )
        return envelope.application
    }
}
