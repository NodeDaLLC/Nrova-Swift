import Foundation

/// Client for the **NodeDa Vertex Legal Policies API**
/// (`https://api.nodeda.com`).
public struct LegalService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)/legal-policies"
    }

    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `GET …/legal-policies`.
    public func listPolicies() async throws -> LegalPoliciesResponse {
        try await http.get(base())
    }

    /// `GET …/legal-policies/by-key/{policyKey}`.
    public func getPolicy(byKey key: String) async throws -> LegalPolicyResponse {
        try await http.get("\(base())/by-key/\(key)")
    }

    /// `GET …/legal-policies/{policyId}`.
    public func getPolicy(byId policyId: String) async throws -> LegalPolicyResponse {
        try await http.get("\(base())/\(policyId)")
    }

    /// `POST …/legal-policies` — requires `legal:write`.
    public func createPolicy(_ request: CreateLegalPolicyRequest) async throws -> LegalPolicyResponse {
        try await http.post(base(), body: request)
    }

    /// `PUT …/legal-policies/{policyId}` — requires `legal:write`.
    public func updatePolicy(
        policyId: String,
        update: UpdateLegalPolicyRequest
    ) async throws -> LegalPolicyResponse {
        try await http.put("\(base())/\(policyId)", body: update)
    }

    /// `DELETE …/legal-policies/{policyId}` — requires `legal:write`.
    public func deletePolicy(policyId: String) async throws {
        try await http.delete("\(base())/\(policyId)")
    }

    /// `POST …/legal-policies/{policyId}/sections` — requires `legal:write`.
    public func createSection(
        policyId: String,
        request: CreateLegalSectionRequest
    ) async throws -> LegalPolicySection {
        let envelope: LegalPolicySectionResponse = try await http.post(
            "\(base())/\(policyId)/sections",
            body: request
        )
        return envelope.section
    }

    /// `PUT …/legal-policies/{policyId}/sections/{sectionId}` — requires `legal:write`.
    public func updateSection(
        policyId: String,
        sectionId: String,
        update: UpdateLegalSectionRequest
    ) async throws -> LegalPolicySection {
        let envelope: LegalPolicySectionResponse = try await http.put(
            "\(base())/\(policyId)/sections/\(sectionId)",
            body: update
        )
        return envelope.section
    }

    /// `DELETE …/legal-policies/{policyId}/sections/{sectionId}` — requires `legal:write`.
    public func deleteSection(policyId: String, sectionId: String) async throws {
        try await http.delete("\(base())/\(policyId)/sections/\(sectionId)")
    }
}
