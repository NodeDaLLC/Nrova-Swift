import XCTest
@testable import Nrova

final class NrovaClientTests: XCTestCase {
    // MARK: - Configuration

    func testDefaultConfigurationUsesProductionEndpoints() {
        let configuration = NrovaConfiguration(apiKey: "test")

        XCTAssertEqual(configuration.organizationId, "C1IRXJbknvZSTKMBxLDQ")
        XCTAssertEqual(
            configuration.endpoints.distribution.absoluteString,
            "https://us-central1-nrovallc.cloudfunctions.net/distributionApi"
        )
        XCTAssertEqual(
            configuration.endpoints.support.absoluteString,
            "https://us-central1-nrovallc.cloudfunctions.net/crmSupportApi"
        )
        XCTAssertEqual(
            configuration.endpoints.sales.absoluteString,
            "https://us-central1-nrovallc.cloudfunctions.net/crmSalesApi"
        )
        XCTAssertEqual(
            configuration.endpoints.careers.absoluteString,
            "https://us-central1-nrovallc.cloudfunctions.net/careersApi"
        )
        XCTAssertEqual(
            configuration.endpoints.newsroom.absoluteString,
            "https://us-central1-nrovallc.cloudfunctions.net/newsroomApi"
        )
        XCTAssertEqual(
            configuration.endpoints.developer.absoluteString,
            "https://us-central1-nrovallc.cloudfunctions.net/developerApi"
        )
        XCTAssertEqual(
            configuration.endpoints.systemStatus.absoluteString,
            "https://us-central1-nrovallc.cloudfunctions.net/systemStatusApi"
        )
        XCTAssertEqual(
            configuration.endpoints.legalPolicies.absoluteString,
            "https://us-central1-nrovallc.cloudfunctions.net/legalPoliciesApi"
        )
    }

    func testClientExposesEveryService() {
        let client = NrovaClient(apiKey: "test", transport: MockTransport())
        _ = client.distribution
        _ = client.support
        _ = client.sales
        _ = client.careers
        _ = client.newsroom
        _ = client.featureFlags
        _ = client.systemStatus
        _ = client.legal
    }

    // MARK: - Distribution wiring

    func testDistributionListApplicationsRequest() async throws {
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(
                request.url?.absoluteString,
                "https://us-central1-nrovallc.cloudfunctions.net/distributionApi/v1/organizations/C1IRXJbknvZSTKMBxLDQ/applications"
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "test-key")

            let json = """
            {
              "schema": "nrova.distribution.v1",
              "orgId": "C1IRXJbknvZSTKMBxLDQ",
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

        let client = NrovaClient(apiKey: "test-key", transport: mock)
        let response = try await client.distribution.listApplications()
        XCTAssertEqual(response.applications.count, 1)
        XCTAssertEqual(response.applications.first?.id, "acme-notes")
        XCTAssertEqual(response.applications.first?.platforms, [.macos, .windows])
    }

    func testDistributionLatestEncodesQueryAndDecodesPayload() async throws {
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "GET")
            let url = request.url!
            XCTAssertEqual(url.path, "/distributionApi/v1/organizations/C1IRXJbknvZSTKMBxLDQ/applications/acme-notes/latest")
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

        let client = NrovaClient(apiKey: "test-key", transport: mock)
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

        let client = NrovaClient(apiKey: "test-key", transport: mock)
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

        let client = NrovaClient(apiKey: "bad", transport: mock)
        do {
            _ = try await client.distribution.listApplications()
            XCTFail("Expected NrovaError.api to be thrown")
        } catch let NrovaError.api(apiError) {
            XCTAssertEqual(apiError.status, 401)
            XCTAssertEqual(apiError.code, "invalid_api_key")
            XCTAssertEqual(apiError.message, "Missing or unrecognized key.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Feature flags

    func testFeatureFlagsEvaluatePostsBody() async throws {
        let mock = MockTransport(responder: { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.url?.absoluteString,
                "https://us-central1-nrovallc.cloudfunctions.net/developerApi/v1/organizations/C1IRXJbknvZSTKMBxLDQ/evaluate"
            )

            let body = try XCTUnwrap(request.httpBody)
            struct Sent: Decodable { let subjectId: String; let countryCode: String?; let flagKeys: [String]? }
            let sent = try JSONDecoder().decode(Sent.self, from: body)
            XCTAssertEqual(sent.subjectId, "user-1")
            XCTAssertEqual(sent.countryCode, "US")
            XCTAssertEqual(sent.flagKeys, ["dark_mode"])

            let json = """
            {
              "orgId": "C1IRXJbknvZSTKMBxLDQ",
              "subjectId": "user-1",
              "countryCode": "US",
              "evaluatedAt": "2026-06-09T00:00:00.000Z",
              "results": { "dark_mode": true }
            }
            """
            return (Data(json.utf8), MockTransport.response(for: request, status: 200))
        })

        let client = NrovaClient(apiKey: "test-key", transport: mock)
        let enabled = try await client.featureFlags.isEnabled(
            flagKey: "dark_mode",
            subjectId: "user-1",
            countryCode: "US"
        )
        XCTAssertTrue(enabled)
    }

    // MARK: - Health

    func testHealthEndpointSkipsAuth() async throws {
        let mock = MockTransport(responder: { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            XCTAssertNil(request.value(forHTTPHeaderField: "X-API-Key"))
            let json = #"{"ok":true,"service":"distribution-api"}"#
            return (Data(json.utf8), MockTransport.response(for: request, status: 200))
        })
        let client = NrovaClient(apiKey: "test-key", transport: mock)
        let health = try await client.distribution.health()
        XCTAssertTrue(health.ok)
        XCTAssertEqual(health.service, "distribution-api")
    }
}
