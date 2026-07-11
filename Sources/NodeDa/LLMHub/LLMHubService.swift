import Foundation

/// Client for the **NodeDa Vertex LLM Hub API**
/// (`https://api.nodeda.com`).
///
/// OpenAI-compatible chat completions. The **server** chooses the upstream
/// (Nrova Gemini vs BYO) from Developer → LLM Hub `routingMode`
/// (`nrova` | `byo` | `prefer_byo`). Clients keep the same request shape;
/// `model` is an optional hint. Requires a developer API key with the
/// ``LLMHubScope/invoke`` (`llm:invoke`) scope.
///
/// ```swift
/// // Prefer omitting model — Hub / BYO defaults apply.
/// let completion = try await client.llmHub.chat(
///     messages: [
///         ChatMessage(role: .system, content: "You are a helpful assistant."),
///         ChatMessage(role: .user, content: "Summarize our release notes.")
///     ],
///     temperature: 0.2,
///     maxTokens: 512
/// )
/// print(completion.firstContent ?? "")
/// ```
public struct LLMHubService: Sendable {
    let http: HTTPClient
    let orgId: String

    init(http: HTTPClient, orgId: String) {
        self.http = http
        self.orgId = orgId
    }

    private func base() -> String {
        "/v1/organizations/\(orgId)/llm"
    }

    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `POST …/llm/chat/completions` — requires `llm:invoke`.
    @discardableResult
    public func createChatCompletion(
        _ request: ChatCompletionRequest
    ) async throws -> ChatCompletionResponse {
        try await http.post("\(base())/chat/completions", body: request)
    }

    /// Sugar for ``createChatCompletion(_:)``.
    @discardableResult
    public func chat(
        messages: [ChatMessage],
        model: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil
    ) async throws -> ChatCompletionResponse {
        try await createChatCompletion(
            ChatCompletionRequest(
                messages: messages,
                model: model,
                temperature: temperature,
                maxTokens: maxTokens
            )
        )
    }
}
