import XCTest
@testable import NodeDa

final class NodeDaClientTests: XCTestCase {
    // MARK: - Configuration

    func testDefaultConfigurationUsesProductionEndpoints() {
        let configuration = NodeDaConfiguration(apiKey: "test")
        let unified = NodeDaConfiguration.unifiedAPIBaseURL.absoluteString

        XCTAssertEqual(configuration.organizationId, "C1IRXJbknvZSTKMBxLDQ")
        XCTAssertEqual(configuration.organizationId, NodeDaConfiguration.defaultOrganizationId)
        XCTAssertEqual(configuration.endpoints.distribution.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.support.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.sales.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.careers.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.newsroom.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.developer.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.systemStatus.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.legalPolicies.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.llmHub.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.appAnalytics.absoluteString, unified)
        XCTAssertEqual(configuration.endpoints.drive.absoluteString, unified)
    }

    func testClientExposesEveryService() {
        let client = NodeDaClient(apiKey: "test", transport: MockTransport())
        _ = client.distribution
        _ = client.support
        _ = client.sales
        _ = client.careers
        _ = client.newsroom
        _ = client.featureFlags
        _ = client.systemStatus
        _ = client.legal
        _ = client.llmHub
        _ = client.appAnalytics
        _ = client.drive
    }

    // MARK: - Distribution wiring

    func testDistributionListApplicationsRequest() async throws {
        let orgId = NodeDaConfiguration.defaultOrganizationId
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(
                request.url?.absoluteString,
                "https://api.nodeda.com/v1/organizations/\(orgId)/applications"
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "test-key")

            let json = """
            {
              "schema": "nrova.distribution.v1",
              "orgId": "\(orgId)",
              "applications": [
                {
                  "id": "acme-notes",
                  "slug": "acme-notes",
                  "name": "Acme Notes",
                  "platforms": ["macos", "windows"],
                  "createdAt": "2026-04-09T12:00:00.000Z",
                  "updatedAt": "2026-06-01T14:00:00.000Z"
                }
              ]
            }
            """
            return (Data(json.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let response = try await client.distribution.listApplications()
        XCTAssertEqual(response.applications.count, 1)
        XCTAssertEqual(response.applications.first?.id, "acme-notes")
        XCTAssertEqual(response.applications.first?.platforms, [.macos, .windows])
    }

    func testDistributionLatestEncodesQueryAndDecodesPayload() async throws {
        let orgId = NodeDaConfiguration.defaultOrganizationId
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "GET")
            let url = request.url!
            XCTAssertEqual(url.path, "/v1/organizations/\(orgId)/applications/acme-notes/latest")
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            XCTAssertTrue(items.contains(URLQueryItem(name: "platform", value: "macos")))
            XCTAssertTrue(items.contains(URLQueryItem(name: "channel", value: "stable")))
            XCTAssertTrue(items.contains(URLQueryItem(name: "purpose", value: "install")))

            let json = """
            {
              "schema": "nrova.distribution.v1",
              "appId": "acme-notes",
              "channel": "stable",
              "platform": "macos",
              "release": {
                "id": "rel_abc",
                "version": "1.2.3",
                "channel": "stable",
                "isYanked": false,
                "artifacts": [
                  {
                    "platform": "macos",
                    "fileName": "Acme-Notes-1.2.3.dmg",
                    "downloadUrl": "https://example.com/file.dmg",
                    "sizeBytes": 100,
                    "contentType": "application/x-apple-diskimage",
                    "installPurpose": "install"
                  }
                ]
              },
              "artifact": {
                "platform": "macos",
                "fileName": "Acme-Notes-1.2.3.dmg",
                "downloadUrl": "https://example.com/file.dmg",
                "sizeBytes": 100,
                "contentType": "application/x-apple-diskimage",
                "installPurpose": "install"
              }
            }
            """
            return (Data(json.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let latest = try await client.distribution.latest(
            appId: "acme-notes",
            platform: .macos,
            channel: .stable,
            purpose: .install
        )
        XCTAssertEqual(latest.appId, "acme-notes")
        XCTAssertEqual(latest.platform, .macos)
        XCTAssertEqual(latest.artifact.fileName, "Acme-Notes-1.2.3.dmg")
        XCTAssertEqual(latest.artifact.installPurpose, .install)
    }

    func testDistributionPublishReleaseSendsBody() async throws {
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let body = try XCTUnwrap(request.httpBody)
            let decoded = try JSONDecoder().decode(PublishReleaseRequest.self, from: body)
            XCTAssertEqual(decoded.version, "1.2.4")
            XCTAssertEqual(decoded.channel, .stable)
            XCTAssertEqual(decoded.artifacts.first?.fileName, "Acme.zip")

            let json = """
            {
              "schema": "nrova.distribution.v1",
              "release": {
                "id": "rel_new",
                "version": "1.2.4",
                "channel": "stable",
                "isYanked": false,
                "artifacts": [
                  {
                    "platform": "macos",
                    "fileName": "Acme.zip",
                    "downloadUrl": "https://example.com/file.zip",
                    "sizeBytes": 200,
                    "contentType": "application/zip"
                  }
                ]
              }
            }
            """
            return (Data(json.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let request = PublishReleaseRequest(
            version: "1.2.4",
            channel: .stable,
            artifacts: [
                DistributionArtifact(
                    platform: .macos,
                    fileName: "Acme.zip",
                    downloadUrl: "https://example.com/file.zip",
                    sizeBytes: 200,
                    contentType: "application/zip"
                )
            ]
        )
        let release = try await client.distribution.publishRelease(appId: "acme-notes", request: request)
        XCTAssertEqual(release.id, "rel_new")
    }

    // MARK: - Error mapping

    func testAPIErrorIsSurfaced() async {
        let mock = MockTransport(responder: { request in
            let payload = #"{"error":"invalid_api_key","message":"Missing or unrecognized key."}"#
            return (Data(payload.utf8), MockTransport.response(for: request, status: 401))
        })

        let client = NodeDaClient(apiKey: "bad", transport: mock)
        do {
            _ = try await client.distribution.listApplications()
            XCTFail("Expected NodeDaError.api to be thrown")
        } catch let NodeDaError.api(apiError) {
            XCTAssertEqual(apiError.status, 401)
            XCTAssertEqual(apiError.code, "invalid_api_key")
            XCTAssertEqual(apiError.message, "Missing or unrecognized key.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Feature flags

    func testFeatureFlagsEvaluatePostsBody() async throws {
        let orgId = NodeDaConfiguration.defaultOrganizationId
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.url?.absoluteString,
                "https://api.nodeda.com/v1/organizations/\(orgId)/evaluate"
            )

            let body = try XCTUnwrap(request.httpBody)
            struct Sent: Decodable { let subjectId: String; let countryCode: String?; let flagKeys: [String]? }
            let sent = try JSONDecoder().decode(Sent.self, from: body)
            XCTAssertEqual(sent.subjectId, "user-1")
            XCTAssertEqual(sent.countryCode, "US")
            XCTAssertEqual(sent.flagKeys, ["dark_mode"])

            let json = """
            {
              "orgId": "\(orgId)",
              "subjectId": "user-1",
              "countryCode": "US",
              "evaluatedAt": "2026-06-09T00:00:00.000Z",
              "results": { "dark_mode": true }
            }
            """
            return (Data(json.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let enabled = try await client.featureFlags.isEnabled(
            flagKey: "dark_mode",
            subjectId: "user-1",
            countryCode: "US"
        )
        XCTAssertTrue(enabled)
    }

    // MARK: - Info.plist loader

    func testInfoDictionaryLoaderUsesProvidedKeyAndOrg() throws {
        let configuration = try NodeDaConfiguration.fromInfoDictionary([
            "NodeDaAPIKey": "sk_test_abc",
            "NodeDaOrganizationId": "TenantXYZ"
        ])
        XCTAssertEqual(configuration.apiKey, "sk_test_abc")
        XCTAssertEqual(configuration.organizationId, "TenantXYZ")
    }

    func testInfoDictionaryLoaderTrimsWhitespace() throws {
        let configuration = try NodeDaConfiguration.fromInfoDictionary([
            "NodeDaAPIKey": "  sk_test_abc  ",
            "NodeDaOrganizationId": "  TenantXYZ  "
        ])
        XCTAssertEqual(configuration.apiKey, "sk_test_abc")
        XCTAssertEqual(configuration.organizationId, "TenantXYZ")
    }

    func testInfoDictionaryLoaderHonoursCustomKeyNames() throws {
        let keys = NodeDaConfiguration.InfoPlistKeys(
            apiKey: "MyApp.NodeDaKey",
            organizationId: "MyApp.NodeDaOrg"
        )
        let configuration = try NodeDaConfiguration.fromInfoDictionary(
            [
                "MyApp.NodeDaKey": "sk_test_abc",
                "MyApp.NodeDaOrg": "TenantXYZ"
            ],
            keys: keys
        )
        XCTAssertEqual(configuration.apiKey, "sk_test_abc")
        XCTAssertEqual(configuration.organizationId, "TenantXYZ")
    }

    func testInfoDictionaryLoaderThrowsWhenAPIKeyMissing() {
        XCTAssertThrowsError(try NodeDaConfiguration.fromInfoDictionary([:])) { error in
            guard case NodeDaConfiguration.InfoPlistError.missingAPIKey(let keys, _) = error else {
                XCTFail("Expected missingAPIKey, got \(error)")
                return
            }
            XCTAssertEqual(keys.apiKey, "NodeDaAPIKey")
            let description = (error as? LocalizedError)?.errorDescription ?? ""
            XCTAssertTrue(description.contains("<key>NodeDaAPIKey</key>"))
            XCTAssertTrue(description.contains("<string>YOUR_NODEDA_API_KEY</string>"))
            XCTAssertTrue(description.contains("<key>NodeDaOrganizationId</key>"))
            XCTAssertTrue(description.contains("<string>C1IRXJbknvZSTKMBxLDQ</string>"))
        }
    }

    func testInfoDictionaryLoaderThrowsWhenAPIKeyEmpty() {
        XCTAssertThrowsError(
            try NodeDaConfiguration.fromInfoDictionary(["NodeDaAPIKey": "   "])
        ) { error in
            guard case NodeDaConfiguration.InfoPlistError.missingAPIKey = error else {
                XCTFail("Expected missingAPIKey, got \(error)")
                return
            }
        }
    }

    func testInfoDictionaryLoaderThrowsWhenAPIKeyIsPlaceholder() {
        XCTAssertThrowsError(
            try NodeDaConfiguration.fromInfoDictionary([
                "NodeDaAPIKey": NodeDaConfiguration.apiKeyPlaceholder,
                "NodeDaOrganizationId": NodeDaConfiguration.defaultOrganizationId
            ])
        ) { error in
            guard case NodeDaConfiguration.InfoPlistError.unresolvedAPIKeyPlaceholder(let keys, let placeholder, _) = error else {
                XCTFail("Expected unresolvedAPIKeyPlaceholder, got \(error)")
                return
            }
            XCTAssertEqual(keys.apiKey, "NodeDaAPIKey")
            XCTAssertEqual(placeholder, "YOUR_NODEDA_API_KEY")
            let description = (error as? LocalizedError)?.errorDescription ?? ""
            XCTAssertTrue(description.contains("YOUR_NODEDA_API_KEY"))
            XCTAssertTrue(description.contains("C1IRXJbknvZSTKMBxLDQ"))
        }
    }

    func testInfoDictionaryLoaderThrowsWhenOrganizationEmpty() {
        XCTAssertThrowsError(
            try NodeDaConfiguration.fromInfoDictionary([
                "NodeDaAPIKey": "sk_test_abc",
                "NodeDaOrganizationId": ""
            ])
        ) { error in
            guard case NodeDaConfiguration.InfoPlistError.missingOrganizationId(let keys, _) = error else {
                XCTFail("Expected missingOrganizationId, got \(error)")
                return
            }
            XCTAssertEqual(keys.organizationId, "NodeDaOrganizationId")
        }
    }

    func testInfoDictionaryLoaderThrowsWhenOrganizationMissing() {
        XCTAssertThrowsError(
            try NodeDaConfiguration.fromInfoDictionary([
                "NodeDaAPIKey": "sk_test_abc"
            ])
        ) { error in
            guard case NodeDaConfiguration.InfoPlistError.missingOrganizationId(let keys, _) = error else {
                XCTFail("Expected missingOrganizationId, got \(error)")
                return
            }
            XCTAssertEqual(keys.organizationId, "NodeDaOrganizationId")
            let description = (error as? LocalizedError)?.errorDescription ?? ""
            XCTAssertTrue(description.contains("C1IRXJbknvZSTKMBxLDQ"))
        }
    }

    func testInfoPlistSetupSnippetUsesKnownPlaceholders() {
        let snippet = NodeDaConfiguration.infoPlistSetupSnippet()
        XCTAssertEqual(
            snippet,
            """
            <key>NodeDaAPIKey</key>
            <string>YOUR_NODEDA_API_KEY</string>
            <key>NodeDaOrganizationId</key>
            <string>C1IRXJbknvZSTKMBxLDQ</string>
            """
        )
    }

    func testNodeDaClientFromInfoDictionaryWiresEverything() throws {
        let client = try NodeDaClient.fromInfoDictionary(
            [
                "NodeDaAPIKey": "sk_test_abc",
                "NodeDaOrganizationId": NodeDaConfiguration.defaultOrganizationId
            ],
            transport: MockTransport()
        )
        XCTAssertEqual(client.configuration.apiKey, "sk_test_abc")
        XCTAssertEqual(client.configuration.organizationId, NodeDaConfiguration.defaultOrganizationId)
    }

    // MARK: - Version constant

    func testSDKVersionIsExposed() {
        XCTAssertFalse(NodeDa.version.isEmpty)
        XCTAssertEqual(NodeDa.version, "1.4.0")
    }

    // MARK: - LLM Hub

    func testLLMHubCreateChatCompletionEncodesOpenAIBody() async throws {
        let orgId = NodeDaConfiguration.defaultOrganizationId
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.url?.path,
                "/v1/organizations/\(orgId)/llm/chat/completions"
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(json?["model"] as? String, "gemini-3.1-flash-lite")
            let temperature = try XCTUnwrap((json?["temperature"] as? NSNumber)?.doubleValue)
            XCTAssertEqual(temperature, 0.2, accuracy: 0.0001)
            XCTAssertEqual((json?["max_tokens"] as? NSNumber)?.intValue, 512)
            let messages = try XCTUnwrap(json?["messages"] as? [[String: Any]])
            XCTAssertEqual(messages.count, 2)
            XCTAssertEqual(messages[0]["role"] as? String, "system")
            XCTAssertEqual(messages[1]["role"] as? String, "user")

            let responseJSON = """
            {
              "id": "chatcmpl_test",
              "object": "chat.completion",
              "created": 1752240000,
              "model": "gemini-3.1-flash-lite",
              "choices": [
                {
                  "index": 0,
                  "message": { "role": "assistant", "content": "Ship it." },
                  "finish_reason": "stop"
                }
              ],
              "usage": {
                "prompt_tokens": 24,
                "completion_tokens": 3,
                "total_tokens": 27
              }
            }
            """
            return (Data(responseJSON.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let completion = try await client.llmHub.createChatCompletion(
            ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .system, content: "You are a helpful assistant."),
                    ChatMessage(role: .user, content: "Summarize our release notes.")
                ],
                model: LLMHubModelID.gemini31FlashLite,
                temperature: 0.2,
                maxTokens: 512
            )
        )
        XCTAssertEqual(completion.id, "chatcmpl_test")
        XCTAssertEqual(completion.model, "gemini-3.1-flash-lite")
        XCTAssertEqual(completion.firstContent, "Ship it.")
        XCTAssertEqual(completion.usage?.totalTokens, 27)
        XCTAssertEqual(completion.choices.first?.finishReason, "stop")
    }

    func testLLMHubChatSugarPostsSameEndpoint() async throws {
        let orgId = NodeDaConfiguration.defaultOrganizationId
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.url?.path,
                "/v1/organizations/\(orgId)/llm/chat/completions"
            )
            let json = #"{"id":"c1","choices":[{"message":{"role":"assistant","content":"Hi"}}]}"#
            return (Data(json.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let completion = try await client.llmHub.chat(
            messages: [ChatMessage(role: .user, content: "Hello")]
        )
        XCTAssertEqual(completion.firstContent, "Hi")
    }

    func testLLMHubOmitsNilModelFromWireBody() async throws {
        let mock = MockTransport(responder: { request in
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertNil(json?["model"])
            XCTAssertNotNil(json?["messages"])
            let responseJSON = #"{"id":"c2","choices":[{"message":{"role":"assistant","content":"ok"}}]}"#
            return (Data(responseJSON.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        _ = try await client.llmHub.createChatCompletion(
            ChatCompletionRequest(
                messages: [ChatMessage(role: .user, content: "Hi")]
            )
        )
    }

    // MARK: - App Analytics

    func testAppAnalyticsIngestPostsSessionBatch() async throws {
        let orgId = NodeDaConfiguration.defaultOrganizationId
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.url?.path,
                "/v1/organizations/\(orgId)/app-analytics/events"
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "test-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(json?["bundleId"] as? String, "com.example.notes")
            XCTAssertEqual(json?["platform"] as? String, "ios")
            XCTAssertEqual(json?["sdk"] as? String, "ios")
            XCTAssertEqual(json?["installId"] as? String, "install-uuid-from-device")
            XCTAssertEqual(json?["sessionId"] as? String, "session-uuid-abcdef")
            XCTAssertEqual((json?["activeUserThresholdSeconds"] as? NSNumber)?.intValue, 120)
            let events = try XCTUnwrap(json?["events"] as? [[String: Any]])
            XCTAssertEqual(events.count, 3)
            XCTAssertEqual(events[0]["type"] as? String, "session_start")
            XCTAssertEqual((events[0]["ts"] as? NSNumber)?.intValue, 1_710_000_000_000)
            XCTAssertEqual(events[1]["type"] as? String, "screen")
            XCTAssertEqual(events[1]["screen"] as? String, "Home")
            XCTAssertEqual(events[2]["type"] as? String, "heartbeat")
            XCTAssertEqual((events[2]["foregroundDurationMs"] as? NSNumber)?.intValue, 120_000)
            XCTAssertNil(json?["appVersion"])
            XCTAssertNil(json?["osVersion"])

            let responseJSON = """
            {
              "ok": true,
              "schema": "nrova.app-analytics.v1",
              "appId": "example-notes",
              "bundleId": "com.example.notes",
              "qualifiedActive": false,
              "activeUserThresholdSeconds": 120
            }
            """
            return (Data(responseJSON.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let result = try await client.appAnalytics.ingest(
            bundleId: "com.example.notes",
            platform: .ios,
            installId: "install-uuid-from-device",
            sessionId: "session-uuid-abcdef",
            events: [
                .sessionStart(ts: 1_710_000_000_000),
                .screen("Home", ts: 1_710_000_000_500),
                .heartbeat(ts: 1_710_000_120_000, foregroundDurationMs: 120_000)
            ],
            sdk: .ios,
            activeUserThresholdSeconds: AppAnalyticsActiveUserThreshold.default
        )
        XCTAssertTrue(result.ok)
        XCTAssertEqual(result.schema, AppAnalyticsSchema.v1)
        XCTAssertEqual(result.appId, "example-notes")
        XCTAssertEqual(result.bundleId, "com.example.notes")
        XCTAssertEqual(result.qualifiedActive, false)
        XCTAssertEqual(result.activeUserThresholdSeconds, 120)
        XCTAssertEqual(AppAnalyticsScope.write, "app-analytics:write")
    }

    func testAppAnalyticsIngestOmitsNilOptionals() async throws {
        let mock = MockTransport(responder: { request in
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertNil(json?["sdk"])
            XCTAssertNil(json?["appVersion"])
            XCTAssertNil(json?["osVersion"])
            XCTAssertNil(json?["activeUserThresholdSeconds"])
            let events = try XCTUnwrap(json?["events"] as? [[String: Any]])
            XCTAssertNil(events[0]["ts"])
            XCTAssertNil(events[0]["screen"])
            XCTAssertNil(events[0]["foregroundDurationMs"])
            let responseJSON = #"{"ok":true,"schema":"nrova.app-analytics.v1","appId":"a","bundleId":"com.example.notes"}"#
            return (Data(responseJSON.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        _ = try await client.appAnalytics.ingest(
            AppAnalyticsIngestRequest(
                bundleId: "com.example.notes",
                platform: .macos,
                installId: "install-uuid-from-device",
                sessionId: "session-uuid-abcdef",
                events: [.sessionStart()]
            )
        )
    }

    func testAppAnalyticsOpaqueIdCharset() {
        let id = AppAnalyticsOpaqueId.generate()
        XCTAssertTrue(AppAnalyticsOpaqueId.isValid(id))
        XCTAssertEqual(id.count, 22)
        XCTAssertFalse(AppAnalyticsOpaqueId.isValid("short"))
        XCTAssertTrue(AppAnalyticsOpaqueId.isValid("install-uuid-from-device"))
    }

    // MARK: - Drive

    func testDriveSessionUsesIdTokenAndUserPath() async throws {
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/drive/session")
            XCTAssertFalse(request.url?.absoluteString.contains("/organizations/") ?? true)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer firebase-id-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Firebase-Id-Token"), "firebase-id-token")
            XCTAssertNil(request.value(forHTTPHeaderField: "X-API-Key"))
            let json = """
            {
              "schema": "nrova.drive.v1",
              "user": { "uid": "user_1", "email": "ada@example.com" },
              "accounts": [
                {
                  "id": "acct_1",
                  "name": "Acme",
                  "driveAccessible": true,
                  "drives": [
                    { "kind": "my", "space": "personal", "name": "My Drive" },
                    { "kind": "organization", "space": "shared", "name": "Organization Drive" }
                  ]
                }
              ]
            }
            """
            return (Data(json.utf8), MockTransport.response(for: request, status: 200))
        })
        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let session = try await client.drive.session(idToken: "firebase-id-token")
        XCTAssertEqual(session.user.uid, "user_1")
        XCTAssertEqual(session.accounts.count, 1)
        XCTAssertEqual(session.accounts.first?.drives.count, 2)
        XCTAssertEqual(session.accounts.first?.drives.first?.kind, .my)
    }

    func testDriveCreateAppFolderDoesNotUseOrganizationPath() async throws {
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/v1/drive/app-folders")
            XCTAssertFalse(request.url?.absoluteString.contains("/organizations/") ?? true)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer firebase-id-token")
            let json = """
            {
              "schema": "nrova.drive.v1",
              "created": true,
              "folder": {
                "id": "fld_1",
                "kind": "folder",
                "name": "Example Notes",
                "parentId": null,
                "space": "personal",
                "appKey": "com.example.notes"
              }
            }
            """
            return (Data(json.utf8), MockTransport.response(for: request, status: 201))
        })
        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let folder = try await client.drive.createAppFolder(
            idToken: "firebase-id-token",
            appKey: "com.example.notes",
            name: "Example Notes"
        )
        XCTAssertEqual(folder.folder.appKey, "com.example.notes")
        XCTAssertEqual(folder.folder.space, .personal)
    }

    // MARK: - Health

    func testHealthEndpointSkipsAuth() async throws {
        let mock = MockTransport(responder: { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            XCTAssertNil(request.value(forHTTPHeaderField: "X-API-Key"))
            let json = #"{"ok":true,"service":"nrova-api"}"#
            return (Data(json.utf8), MockTransport.response(for: request, status: 200))
        })
        let client = NodeDaClient(apiKey: "test-key", transport: mock)
        let health = try await client.distribution.health()
        XCTAssertTrue(health.ok)
        XCTAssertEqual(health.service, "nrova-api")
    }
}
