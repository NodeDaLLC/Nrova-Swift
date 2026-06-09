import Foundation

/// Client for the **Nrova Newsroom API**
/// (`https://us-central1-nrovallc.cloudfunctions.net/newsroomApi`).
public struct NewsroomService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)/newsroom"
    }

    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `GET …/newsroom/categories`.
    public func listCategories() async throws -> [NewsroomCategory] {
        let envelope: NewsroomCategoriesResponse = try await http.get("\(base())/categories")
        return envelope.categories
    }

    /// `GET …/newsroom/posts` with optional filters.
    public func listPosts(
        status: NewsroomStatus? = nil,
        categoryId: String? = nil,
        tag: String? = nil,
        limit: Int? = nil,
        includeDocument: Bool = false
    ) async throws -> [NewsroomPost] {
        let envelope: NewsroomPostsResponse = try await http.get(
            "\(base())/posts",
            query: [
                "status": status?.rawValue,
                "categoryId": categoryId,
                "tag": tag,
                "limit": limit.map(String.init),
                "include": includeDocument ? "document" : nil
            ]
        )
        return envelope.posts
    }

    /// `GET …/newsroom/posts/{idOrSlug}`.
    public func getPost(idOrSlug: String, includeDocument: Bool = false) async throws -> NewsroomPost {
        let envelope: NewsroomPostResponse = try await http.get(
            "\(base())/posts/\(idOrSlug)",
            query: ["include": includeDocument ? "document" : nil]
        )
        return envelope.post
    }

    /// `POST …/newsroom/posts` — requires `newsroom:write`.
    public func createPost(_ request: CreateNewsroomPostRequest) async throws -> NewsroomPost {
        let envelope: NewsroomPostResponse = try await http.post("\(base())/posts", body: request)
        return envelope.post
    }

    /// `PATCH …/newsroom/posts/{postId}` — requires `newsroom:write`.
    public func updatePost(
        postId: String,
        update: UpdateNewsroomPostRequest
    ) async throws -> NewsroomPost {
        let envelope: NewsroomPostResponse = try await http.patch("\(base())/posts/\(postId)", body: update)
        return envelope.post
    }

    /// `DELETE …/newsroom/posts/{postId}` — requires `newsroom:write`.
    public func deletePost(postId: String) async throws {
        try await http.delete("\(base())/posts/\(postId)")
    }
}
