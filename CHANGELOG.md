## 1.2.1

- LLM Hub: document **server-owned routing** (`nrova` / `byo` / `prefer_byo` from Hub config). Clients do not pick the provider.
- `ChatCompletionRequest` omits nil `model` / `temperature` / `max_tokens` on the wire (no JSON `null`).
- Docs: prefer omitting `model`; list gateway error slugs for Hub / BYO / spend-cap failures.

## 1.2.0

- Added Vertex LLM Hub client (`client.llmHub`) with OpenAI-compatible
  chat completions (`createChatCompletion` / `chat`).
- Catalog model ids on `LLMHubModelID`; scope constant `LLMHubScope.invoke`.
- Included `llmHub` in `ServiceEndpoints` and `healthAll()`.
