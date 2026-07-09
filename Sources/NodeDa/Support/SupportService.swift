import Foundation

/// Client for the **NodeDa Vertex Support API**
/// (`https://api.nodeda.com`).
public struct SupportService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)/support"
    }

    /// `GET /health`.
    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `POST …/support/tickets`.
    public func createTicket(_ request: CreateSupportTicketRequest) async throws -> SupportTicket {
        let envelope: SupportTicketResponse = try await http.post("\(base())/tickets", body: request)
        return envelope.ticket
    }

    /// `GET …/support/tickets?contactEmail=…`.
    public func listTickets(contactEmail: String) async throws -> [SupportTicket] {
        let envelope: SupportTicketsResponse = try await http.get(
            "\(base())/tickets",
            query: ["contactEmail": contactEmail]
        )
        return envelope.tickets
    }

    /// `GET …/support/tickets/{ticketId}`.
    public func getTicket(ticketId: String) async throws -> SupportTicket {
        let envelope: SupportTicketResponse = try await http.get("\(base())/tickets/\(ticketId)")
        return envelope.ticket
    }

    /// `GET …/support/tickets/{ticketId}/comments`.
    public func listComments(ticketId: String) async throws -> [SupportComment] {
        let envelope: SupportCommentsResponse = try await http.get("\(base())/tickets/\(ticketId)/comments")
        return envelope.comments
    }

    /// `POST …/support/tickets/{ticketId}/comments`.
    public func addComment(
        ticketId: String,
        request: CreateSupportCommentRequest
    ) async throws -> SupportComment {
        let envelope: SupportCommentResponse = try await http.post(
            "\(base())/tickets/\(ticketId)/comments",
            body: request
        )
        return envelope.comment
    }
}
