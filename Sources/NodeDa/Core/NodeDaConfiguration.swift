import Foundation

/// Static configuration for talking to the public NodeDa Vertex HTTP APIs.
///
/// All org-scoped HTTP APIs share one unified gateway host
/// (`https://api.nodeda.com`). The gateway routes by path prefix
/// (`/v1/organizations/{orgId}/support/`, `/applications/`, …).
public struct NodeDaConfiguration: Sendable {
    /// API key used as `Authorization: Bearer <key>` and `X-API-Key`.
    public let apiKey: String

    /// Organization id used in the URL path (`/v1/organizations/{orgId}/...`).
    public let organizationId: String

    /// Service base URLs. In production every entry is the unified gateway.
    /// Override individual entries only when pointing a single surface at a
    /// staging proxy or local emulator.
    public var endpoints: ServiceEndpoints

    /// Extra headers sent with every request (e.g. tracing / telemetry).
    public var defaultHeaders: [String: String]

    /// Per-request timeout. Defaults to 30 seconds.
    public var timeout: TimeInterval

    public init(
        apiKey: String,
        organizationId: String = NodeDaConfiguration.defaultOrganizationId,
        endpoints: ServiceEndpoints = .production,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30
    ) {
        self.apiKey = apiKey
        self.organizationId = organizationId
        self.endpoints = endpoints
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
    }

    /// NodeDa organization id (`C1IRX…`). Set this as `NodeDaOrganizationId`
    /// in Info.plist. Also used when constructing a client by hand without an
    /// explicit `organizationId`.
    public static let defaultOrganizationId = "C1IRXJbknvZSTKMBxLDQ"

    /// Placeholder string for `NodeDaAPIKey` in Info.plist until a real key is
    /// pasted from the NodeDa Vertex dashboard. Leaving this value in place
    /// makes ``fromInfoPlist(bundle:keys:endpoints:defaultHeaders:timeout:)``
    /// fail with a paste-ready setup snippet.
    public static let apiKeyPlaceholder = "YOUR_NODEDA_API_KEY"

    /// Unified API gateway base URL (no trailing slash).
    public static let unifiedAPIBaseURL = URL(string: "https://api.nodeda.com")!
}

/// Base URLs used by each service client.
///
/// Production values all resolve to ``NodeDaConfiguration/unifiedAPIBaseURL``.
/// Paths stay org-scoped (`/v1/organizations/{orgId}/…`); only the host changed
/// from the legacy per-service Cloud Function URLs (sunset November 1, 2026).
public struct ServiceEndpoints: Sendable {
    public var distribution: URL
    public var support: URL
    public var sales: URL
    public var careers: URL
    public var newsroom: URL
    public var developer: URL
    public var systemStatus: URL
    public var legalPolicies: URL
    public var llmHub: URL
    public var appAnalytics: URL

    public init(
        distribution: URL,
        support: URL,
        sales: URL,
        careers: URL,
        newsroom: URL,
        developer: URL,
        systemStatus: URL,
        legalPolicies: URL,
        llmHub: URL,
        appAnalytics: URL
    ) {
        self.distribution = distribution
        self.support = support
        self.sales = sales
        self.careers = careers
        self.newsroom = newsroom
        self.developer = developer
        self.systemStatus = systemStatus
        self.legalPolicies = legalPolicies
        self.llmHub = llmHub
        self.appAnalytics = appAnalytics
    }

    /// Builds endpoints where every service shares the same base URL.
    public init(baseURL: URL) {
        self.init(
            distribution: baseURL,
            support: baseURL,
            sales: baseURL,
            careers: baseURL,
            newsroom: baseURL,
            developer: baseURL,
            systemStatus: baseURL,
            legalPolicies: baseURL,
            llmHub: baseURL,
            appAnalytics: baseURL
        )
    }

    /// Production endpoints on the unified NodeDa API gateway.
    public static let production = ServiceEndpoints(
        baseURL: NodeDaConfiguration.unifiedAPIBaseURL
    )
}
