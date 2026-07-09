import Foundation

extension NodeDaConfiguration {
    /// Well-known Info.plist keys read by ``NodeDaConfiguration/fromInfoPlist(bundle:keys:endpoints:defaultHeaders:timeout:)``.
    ///
    /// Apps add these keys to their target's `Info.plist` (or to a custom
    /// `.plist` shipped with the bundle) so that secrets and tenant ids
    /// are never compiled into source.
    public struct InfoPlistKeys: Sendable, Equatable {
        /// Plist key holding the API key. Defaults to `NodeDaAPIKey`.
        public var apiKey: String
        /// Plist key holding the organization id. Defaults to `NodeDaOrganizationId`.
        public var organizationId: String

        public init(
            apiKey: String = "NodeDaAPIKey",
            organizationId: String = "NodeDaOrganizationId"
        ) {
            self.apiKey = apiKey
            self.organizationId = organizationId
        }

        public static let `default` = InfoPlistKeys()
    }

    /// Paste-ready Info.plist snippet consumers must add before the client
    /// will start. The API-key value is a placeholder until they paste a
    /// real key from the NodeDa Vertex dashboard; the organization id is
    /// the NodeDa org (`C1IRXJbknvZSTKMBxLDQ`).
    public static func infoPlistSetupSnippet(
        keys: InfoPlistKeys = .default
    ) -> String {
        """
        <key>\(keys.apiKey)</key>
        <string>\(apiKeyPlaceholder)</string>
        <key>\(keys.organizationId)</key>
        <string>\(defaultOrganizationId)</string>
        """
    }

    /// Errors raised when the bundle's `Info.plist` is missing required
    /// NodeDa Vertex credentials, or still contains the unresolved API-key
    /// placeholder.
    public enum InfoPlistError: Error, LocalizedError, Equatable {
        /// The configured API-key entry is missing or empty.
        case missingAPIKey(keys: InfoPlistKeys, bundle: String?)
        /// The API-key entry is still the unresolved placeholder.
        case unresolvedAPIKeyPlaceholder(keys: InfoPlistKeys, placeholder: String, bundle: String?)
        /// The organization id entry is missing or empty.
        case missingOrganizationId(keys: InfoPlistKeys, bundle: String?)

        public var errorDescription: String? {
            switch self {
            case .missingAPIKey(let keys, let bundle):
                return Self.failureMessage(
                    reason: "missing API key (`\(keys.apiKey)`)",
                    bundle: bundle,
                    keys: keys
                )
            case .unresolvedAPIKeyPlaceholder(let keys, let placeholder, let bundle):
                return Self.failureMessage(
                    reason: "API key (`\(keys.apiKey)`) is still the placeholder `\(placeholder)` — replace it with a real key from the NodeDa Vertex dashboard (Developer → API keys)",
                    bundle: bundle,
                    keys: keys
                )
            case .missingOrganizationId(let keys, let bundle):
                return Self.failureMessage(
                    reason: "missing organization id (`\(keys.organizationId)`)",
                    bundle: bundle,
                    keys: keys
                )
            }
        }

        private static func failureMessage(
            reason: String,
            bundle: String?,
            keys: InfoPlistKeys
        ) -> String {
            let where_ = bundle.map { " in bundle \($0)" } ?? ""
            return """
            NodeDa: \(reason)\(where_). Add these keys to your target's Info.plist:

            \(NodeDaConfiguration.infoPlistSetupSnippet(keys: keys))

            Keep `\(NodeDaConfiguration.defaultOrganizationId)` as the organization id. Replace `\(NodeDaConfiguration.apiKeyPlaceholder)` with your API key.
            """
        }
    }

    /// Builds a configuration by reading credentials from the supplied
    /// bundle's `Info.plist`.
    ///
    /// Required:
    /// - `NodeDaAPIKey` (`String`) — replace ``apiKeyPlaceholder`` with a
    ///   key from the NodeDa Vertex dashboard (Developer → API keys).
    /// - `NodeDaOrganizationId` (`String`) — use
    ///   ``defaultOrganizationId`` (`C1IRXJbknvZSTKMBxLDQ`).
    ///
    /// Both keys can be renamed by passing a custom ``InfoPlistKeys``.
    /// Missing, empty, or unresolved-placeholder values throw
    /// ``InfoPlistError`` with a paste-ready snippet.
    ///
    /// ```swift
    /// // Most apps just do this once at launch:
    /// let configuration = try NodeDaConfiguration.fromInfoPlist()
    /// let client = NodeDaClient(configuration: configuration)
    /// ```
    ///
    /// - Throws: ``NodeDaConfiguration/InfoPlistError`` when the required
    ///   entries are missing or still placeholders.
    public static func fromInfoPlist(
        bundle: Bundle = .main,
        keys: InfoPlistKeys = .default,
        endpoints: ServiceEndpoints = .production,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30
    ) throws -> NodeDaConfiguration {
        let infoDictionary = bundle.infoDictionary ?? [:]
        return try fromInfoDictionary(
            infoDictionary,
            keys: keys,
            bundleIdentifier: bundle.bundleIdentifier,
            endpoints: endpoints,
            defaultHeaders: defaultHeaders,
            timeout: timeout
        )
    }

    /// Same shape as ``fromInfoPlist(bundle:keys:endpoints:defaultHeaders:timeout:)``
    /// but reads from an in-memory dictionary. Useful for unit tests or
    /// when you'd rather load credentials from a custom plist that isn't
    /// the bundle's `Info.plist`.
    public static func fromInfoDictionary(
        _ infoDictionary: [String: Any],
        keys: InfoPlistKeys = .default,
        bundleIdentifier: String? = nil,
        endpoints: ServiceEndpoints = .production,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30
    ) throws -> NodeDaConfiguration {
        let rawKey = infoDictionary[keys.apiKey] as? String
        guard let apiKey = rawKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw InfoPlistError.missingAPIKey(keys: keys, bundle: bundleIdentifier)
        }

        if isUnresolvedAPIKeyPlaceholder(apiKey) {
            throw InfoPlistError.unresolvedAPIKeyPlaceholder(
                keys: keys,
                placeholder: apiKeyPlaceholder,
                bundle: bundleIdentifier
            )
        }

        let rawOrg = infoDictionary[keys.organizationId] as? String
        guard let orgId = rawOrg?.trimmingCharacters(in: .whitespacesAndNewlines),
              !orgId.isEmpty else {
            throw InfoPlistError.missingOrganizationId(keys: keys, bundle: bundleIdentifier)
        }

        return NodeDaConfiguration(
            apiKey: apiKey,
            organizationId: orgId,
            endpoints: endpoints,
            defaultHeaders: defaultHeaders,
            timeout: timeout
        )
    }

    /// Returns `true` when `value` is still the documented API-key placeholder
    /// (or a common unresolved build-setting form of it).
    public static func isUnresolvedAPIKeyPlaceholder(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare(apiKeyPlaceholder) == .orderedSame {
            return true
        }
        // Unexpanded Xcode build settings / empty substitution leftovers.
        let unresolvedMarkers = [
            "$(NODEDA_API_KEY)",
            "${NODEDA_API_KEY}",
            "YOUR_API_KEY",
            "sk_live_replace_me",
            "sk_live_…",
            "sk_live_..."
        ]
        return unresolvedMarkers.contains { trimmed.caseInsensitiveCompare($0) == .orderedSame }
    }
}

extension NodeDaClient {
    /// Convenience initializer that pulls the API key and organization
    /// id from the supplied bundle's `Info.plist` — the recommended way
    /// to wire the client up inside an iOS / macOS app target.
    ///
    /// ```swift
    /// // SceneDelegate / App.init / @main
    /// let client = try NodeDaClient.fromInfoPlist()
    /// ```
    ///
    /// Add the keys to your `Info.plist` (API key is a placeholder until
    /// you paste a real one; organization id is the NodeDa org):
    ///
    /// ```xml
    /// <key>NodeDaAPIKey</key>
    /// <string>YOUR_NODEDA_API_KEY</string>
    /// <key>NodeDaOrganizationId</key>
    /// <string>C1IRXJbknvZSTKMBxLDQ</string>
    /// ```
    ///
    /// - Throws: ``NodeDaConfiguration/InfoPlistError`` when the required
    ///   entries are missing, empty, or still the API-key placeholder.
    public static func fromInfoPlist(
        bundle: Bundle = .main,
        keys: NodeDaConfiguration.InfoPlistKeys = .default,
        endpoints: ServiceEndpoints = .production,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30,
        transport: NodeDaTransport = URLSession.shared
    ) throws -> NodeDaClient {
        let configuration = try NodeDaConfiguration.fromInfoPlist(
            bundle: bundle,
            keys: keys,
            endpoints: endpoints,
            defaultHeaders: defaultHeaders,
            timeout: timeout
        )
        return NodeDaClient(configuration: configuration, transport: transport)
    }

    /// Same shape as ``fromInfoPlist(bundle:keys:endpoints:defaultHeaders:timeout:transport:)``
    /// but reads from an in-memory dictionary. Mirrors
    /// ``NodeDaConfiguration/fromInfoDictionary(_:keys:bundleIdentifier:endpoints:defaultHeaders:timeout:)``.
    public static func fromInfoDictionary(
        _ infoDictionary: [String: Any],
        keys: NodeDaConfiguration.InfoPlistKeys = .default,
        bundleIdentifier: String? = nil,
        endpoints: ServiceEndpoints = .production,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30,
        transport: NodeDaTransport = URLSession.shared
    ) throws -> NodeDaClient {
        let configuration = try NodeDaConfiguration.fromInfoDictionary(
            infoDictionary,
            keys: keys,
            bundleIdentifier: bundleIdentifier,
            endpoints: endpoints,
            defaultHeaders: defaultHeaders,
            timeout: timeout
        )
        return NodeDaClient(configuration: configuration, transport: transport)
    }
}
