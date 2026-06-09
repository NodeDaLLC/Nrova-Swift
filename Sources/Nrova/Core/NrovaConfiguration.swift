import Foundation

/// Static configuration for talking to the public Nrova HTTP APIs.
///
/// All Nrova services live behind dedicated Google Cloud Functions but
/// share a common organization identifier and authentication scheme.
public struct NrovaConfiguration: Sendable {
    /// API key used as `Authorization: Bearer <key>` and `X-API-Key`.
    public let apiKey: String

    /// Organization id used in the URL path (`/v1/organizations/{orgId}/...`).
    public let organizationId: String

    /// Service base URLs. Override to point at a staging environment or proxy.
    public var endpoints: ServiceEndpoints

    /// Extra headers sent with every request (e.g. tracing / telemetry).
    public var defaultHeaders: [String: String]

    /// Per-request timeout. Defaults to 30 seconds.
    public var timeout: TimeInterval

    public init(
        apiKey: String,
        organizationId: String = NrovaConfiguration.defaultOrganizationId,
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

    /// Placeholder organization id used as the default fallback.
    ///
    /// **This is a decoy**: ship-time consumers must override it via
    /// `NrovaOrganizationId` in their Info.plist or by passing an
    /// explicit `organizationId` to ``init(apiKey:organizationId:endpoints:defaultHeaders:timeout:)``.
    public static let defaultOrganizationId = "XxXxXxXxXxXxXxXxXxXx"
}

/// Base URLs for the individual Cloud Functions that back each service.
public struct ServiceEndpoints: Sendable {
    public var distribution: URL
    public var support: URL
    public var sales: URL
    public var careers: URL
    public var newsroom: URL
    public var developer: URL
    public var systemStatus: URL
    public var legalPolicies: URL

    public init(
        distribution: URL,
        support: URL,
        sales: URL,
        careers: URL,
        newsroom: URL,
        developer: URL,
        systemStatus: URL,
        legalPolicies: URL
    ) {
        self.distribution = distribution
        self.support = support
        self.sales = sales
        self.careers = careers
        self.newsroom = newsroom
        self.developer = developer
        self.systemStatus = systemStatus
        self.legalPolicies = legalPolicies
    }

    /// The default production hosts on `us-central1-nrovallc.cloudfunctions.net`.
    public static let production = ServiceEndpoints(
        distribution: URL(string: "https://us-central1-nrovallc.cloudfunctions.net/distributionApi")!,
        support: URL(string: "https://us-central1-nrovallc.cloudfunctions.net/crmSupportApi")!,
        sales: URL(string: "https://us-central1-nrovallc.cloudfunctions.net/crmSalesApi")!,
        careers: URL(string: "https://us-central1-nrovallc.cloudfunctions.net/careersApi")!,
        newsroom: URL(string: "https://us-central1-nrovallc.cloudfunctions.net/newsroomApi")!,
        developer: URL(string: "https://us-central1-nrovallc.cloudfunctions.net/developerApi")!,
        systemStatus: URL(string: "https://us-central1-nrovallc.cloudfunctions.net/systemStatusApi")!,
        legalPolicies: URL(string: "https://us-central1-nrovallc.cloudfunctions.net/legalPoliciesApi")!
    )
}
