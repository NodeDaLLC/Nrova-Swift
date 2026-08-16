import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Top-level entry point to all NodeDa Vertex HTTP APIs.
///
/// `NodeDaClient` is intentionally lightweight: each public property
/// (``distribution``, ``support``, …) is a typed service struct backed
/// by a shared transport and the configured ``NodeDaConfiguration``.
///
/// ```swift
/// let client = NodeDaClient(apiKey: "sk_live_…")
/// let latest = try await client.distribution.latest(
///     appId: "acme-notes",
///     platform: .macos,
///     channel: .stable
/// )
/// print(latest.artifact.downloadUrl)
/// ```
public struct NodeDaClient: Sendable {
    public let configuration: NodeDaConfiguration
    public let transport: NodeDaTransport

    public let distribution: DistributionService
    public let support: SupportService
    public let sales: SalesService
    public let careers: CareersService
    public let newsroom: NewsroomService
    public let featureFlags: FeatureFlagsService
    public let systemStatus: SystemStatusService
    public let legal: LegalService
    public let llmHub: LLMHubService
    public let appAnalytics: AppAnalyticsService
    public let drive: DriveService

    /// Builds a fully wired client. Pass an explicit `transport` to swap in
    /// a stub or proxy implementation (handy for tests and offline mode).
    public init(
        apiKey: String,
        organizationId: String = NodeDaConfiguration.defaultOrganizationId,
        endpoints: ServiceEndpoints = .production,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30,
        transport: NodeDaTransport = URLSession.shared
    ) {
        let configuration = NodeDaConfiguration(
            apiKey: apiKey,
            organizationId: organizationId,
            endpoints: endpoints,
            defaultHeaders: defaultHeaders,
            timeout: timeout
        )
        self.init(configuration: configuration, transport: transport)
    }

    /// Construct a client from a fully prepared ``NodeDaConfiguration``.
    public init(
        configuration: NodeDaConfiguration,
        transport: NodeDaTransport = URLSession.shared
    ) {
        self.configuration = configuration
        self.transport = transport

        let orgId = configuration.organizationId

        self.distribution = DistributionService(
            http: HTTPClient(baseURL: configuration.endpoints.distribution, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.support = SupportService(
            http: HTTPClient(baseURL: configuration.endpoints.support, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.sales = SalesService(
            http: HTTPClient(baseURL: configuration.endpoints.sales, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.careers = CareersService(
            http: HTTPClient(baseURL: configuration.endpoints.careers, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.newsroom = NewsroomService(
            http: HTTPClient(baseURL: configuration.endpoints.newsroom, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.featureFlags = FeatureFlagsService(
            http: HTTPClient(baseURL: configuration.endpoints.developer, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.systemStatus = SystemStatusService(
            http: HTTPClient(baseURL: configuration.endpoints.systemStatus, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.legal = LegalService(
            http: HTTPClient(baseURL: configuration.endpoints.legalPolicies, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.llmHub = LLMHubService(
            http: HTTPClient(baseURL: configuration.endpoints.llmHub, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.appAnalytics = AppAnalyticsService(
            http: HTTPClient(baseURL: configuration.endpoints.appAnalytics, configuration: configuration, transport: transport),
            orgId: orgId
        )
        self.drive = DriveService(
            http: HTTPClient(baseURL: configuration.endpoints.drive, configuration: configuration, transport: transport)
        )
    }

    /// Issues `GET /health` against every service base URL in parallel.
    /// Returns a dictionary keyed by service name.
    public func healthAll() async throws -> [String: HealthResponse] {
        try await withThrowingTaskGroup(of: (String, HealthResponse).self) { group in
            group.addTask { ("distribution", try await distribution.health()) }
            group.addTask { ("support", try await support.health()) }
            group.addTask { ("sales", try await sales.health()) }
            group.addTask { ("careers", try await careers.health()) }
            group.addTask { ("newsroom", try await newsroom.health()) }
            group.addTask { ("featureFlags", try await featureFlags.health()) }
            group.addTask { ("systemStatus", try await systemStatus.health()) }
            group.addTask { ("legal", try await legal.health()) }
            group.addTask { ("llmHub", try await llmHub.health()) }
            group.addTask { ("appAnalytics", try await appAnalytics.health()) }
            group.addTask { ("drive", try await drive.health()) }

            var result: [String: HealthResponse] = [:]
            for try await (name, health) in group {
                result[name] = health
            }
            return result
        }
    }
}
