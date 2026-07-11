import Foundation

/// OpenAI-compatible chat message role for LLM Hub completions.
public enum ChatMessageRole: String, Codable, Sendable, CaseIterable, Equatable {
    case system
    case user
    case assistant
}

/// One turn in an OpenAI-style chat completions request.
public struct ChatMessage: Codable, Sendable, Equatable {
    public var role: ChatMessageRole
    public var content: String

    public init(role: ChatMessageRole, content: String) {
        self.role = role
        self.content = content
    }
}

/// Request body for `POST …/llm/chat/completions`.
///
/// Wire field names follow the OpenAI chat-completions shape (`max_tokens`, …).
public struct ChatCompletionRequest: Codable, Sendable, Equatable {
    public var model: String?
    public var messages: [ChatMessage]
    public var temperature: Double?
    public var maxTokens: Int?

    public init(
        messages: [ChatMessage],
        model: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.maxTokens = maxTokens
    }

    private enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

/// Token usage reported by a chat completion response.
public struct ChatCompletionUsage: Codable, Sendable, Equatable {
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?

    private enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

/// Assistant message nested under a completion choice.
public struct ChatCompletionChoiceMessage: Codable, Sendable, Equatable {
    public let role: ChatMessageRole?
    public let content: String?
}

/// One choice in an OpenAI-style chat completion response.
public struct ChatCompletionChoice: Codable, Sendable, Equatable {
    public let index: Int?
    public let message: ChatCompletionChoiceMessage?
    public let finishReason: String?

    private enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

/// Response body for `POST …/llm/chat/completions`.
public struct ChatCompletionResponse: Codable, Sendable, Equatable {
    public let id: String?
    public let object: String?
    public let created: Int?
    public let model: String?
    public let choices: [ChatCompletionChoice]
    public let usage: ChatCompletionUsage?

    /// Convenience: first choice’s assistant text, if present.
    public var firstContent: String? {
        choices.first?.message?.content
    }
}

/// Catalog model ids for Nrova-routed Gemini models on LLM Hub.
///
/// Prefer these constants (or omit `model` to use the org default) over
/// hard-coding strings. BYO routing may accept additional provider ids
/// configured under Org Settings → Custom LLM.
public enum LLMHubModelID {
    /// Cost-efficient default for high-volume completions.
    public static let gemini31FlashLite = "gemini-3.1-flash-lite"
    /// Balanced speed and quality for general production workloads.
    public static let gemini25Flash = "gemini-2.5-flash"
    /// Strong reasoning and coding; elevated rates above 200k input tokens.
    public static let gemini25Pro = "gemini-2.5-pro"
    /// Frontier Flash-class model (preview).
    public static let gemini3FlashPreview = "gemini-3-flash-preview"
    /// Highest Flash intelligence with search and grounding strength.
    public static let gemini35Flash = "gemini-3.5-flash"

    /// Recommended default when the org has no configured default yet.
    public static let recommendedDefault = gemini31FlashLite
}

/// Scope required on Developer API keys to call LLM Hub inference.
public enum LLMHubScope {
    public static let invoke = "llm:invoke"
}
