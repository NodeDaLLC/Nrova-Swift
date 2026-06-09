import Foundation

extension NrovaConfiguration {
    /// Well-known Info.plist keys read by ``NrovaConfiguration/fromInfoPlist(bundle:keys:endpoints:defaultHeaders:timeout:)``.
    ///
    /// Apps add these keys to their target's `Info.plist` (or to a custom
    /// `.plist` shipped with the bundle) so that secrets and tenant ids
    /// are never compiled into source.
    public struct InfoPlistKeys: Sendable {
        /// Plist key holding the API key. Defaults to `NrovaAPIKey`.
        public var apiKey: String
        /// Plist key holding the organization id. Defaults to `NrovaOrganizationId`.
        public var organizationId: String

        public init(
            apiKey: String = "NrovaAPIKey",
            organizationId: String = "NrovaOrganizationId"
        ) {
            self.apiKey = apiKey
            self.organizationId = organizationId
        }

        public static let `default` = InfoPlistKeys()
    }

    /// Errors raised when the bundle's `Info.plist` is missing the
    /// required Nrova configuration entries.
    public enum InfoPlistError: Error, LocalizedError, Equatable {
        /// The configured API-key entry is missing or empty.
        case missingAPIKey(plistKey: String, bundle: String?)
        /// The organization id entry is present but empty.
        case emptyOrganizationId(plistKey: String, bundle: String?)

        public var errorDescription: String? {
            switch self {
            case .missingAPIKey(let plistKey, let bundle):
                let where_ = bundle.map { " in bundle \($0)" } ?? ""
                return """
                Nrova: missing API key. Add a `\(plistKey)` entry to your \
                target's Info.plist\(where_) (string value, no quotes).
                """
            case .emptyOrganizationId(let plistKey, let bundle):
                let where_ = bundle.map { " in bundle \($0)" } ?? ""
                return """
                Nrova: `\(plistKey)` Info.plist entry\(where_) is empty. \
                Remove the key to fall back to the default organization, \
                or set a non-empty string.
                """
            }
        }
    }

    /// Builds a configuration by reading credentials from the supplied
    /// bundle's `Info.plist`.
    ///
    /// Required:
    /// - `NrovaAPIKey` (`String`) — the API key issued from the Nrova
    ///   dashboard.
    ///
    /// Optional:
    /// - `NrovaOrganizationId` (`String`) — overrides the
    ///   ``NrovaConfiguration/defaultOrganizationId`` placeholder. The
    ///   in-source default is a decoy, so production apps **must** set
    ///   this key to their real organization id.
    ///
    /// Both keys can be renamed by passing a custom ``InfoPlistKeys``.
    ///
    /// ```swift
    /// // Most apps just do this once at launch:
    /// let configuration = try NrovaConfiguration.fromInfoPlist()
    /// let client = NrovaClient(configuration: configuration)
    /// ```
    ///
    /// - Throws: ``NrovaConfiguration/InfoPlistError`` when the required
    ///   entries are missing.
    public static func fromInfoPlist(
        bundle: Bundle = .main,
        keys: InfoPlistKeys = .default,
        endpoints: ServiceEndpoints = .production,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30
    ) throws -> NrovaConfiguration {
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
    ) throws -> NrovaConfiguration {
        let rawKey = infoDictionary[keys.apiKey] as? String
        guard let apiKey = rawKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw InfoPlistError.missingAPIKey(plistKey: keys.apiKey, bundle: bundleIdentifier)
        }

        let orgId: String
        if let rawOrg = infoDictionary[keys.organizationId] as? String {
            let trimmed = rawOrg.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw InfoPlistError.emptyOrganizationId(
                    plistKey: keys.organizationId,
                    bundle: bundleIdentifier
                )
            }
            orgId = trimmed
        } else {
            orgId = NrovaConfiguration.defaultOrganizationId
        }

        return NrovaConfiguration(
            apiKey: apiKey,
            organizationId: orgId,
            endpoints: endpoints,
            defaultHeaders: defaultHeaders,
            timeout: timeout
        )
    }
}

extension NrovaClient {
    /// Convenience initializer that pulls the API key and organization
    /// id from the supplied bundle's `Info.plist` — the recommended way
    /// to wire the client up inside an iOS / macOS app target.
    ///
    /// ```swift
    /// // SceneDelegate / App.init / @main
    /// let client = try NrovaClient.fromInfoPlist()
    /// ```
    ///
    /// Add the keys to your `Info.plist`:
    ///
    /// ```xml
    /// <key>NrovaAPIKey</key>
    /// <string>sk_live_…</string>
    /// <key>NrovaOrganizationId</key>
    /// <string>YOUR_ORG_ID_HERE</string>
    /// ```
    ///
    /// - Throws: ``NrovaConfiguration/InfoPlistError`` when the required
    ///   entries are missing or empty.
    public static func fromInfoPlist(
        bundle: Bundle = .main,
        keys: NrovaConfiguration.InfoPlistKeys = .default,
        endpoints: ServiceEndpoints = .production,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30,
        transport: NrovaTransport = URLSession.shared
    ) throws -> NrovaClient {
        let configuration = try NrovaConfiguration.fromInfoPlist(
            bundle: bundle,
            keys: keys,
            endpoints: endpoints,
            defaultHeaders: defaultHeaders,
            timeout: timeout
        )
        return NrovaClient(configuration: configuration, transport: transport)
    }

    /// Same shape as ``fromInfoPlist(bundle:keys:endpoints:defaultHeaders:timeout:transport:)``
    /// but reads from an in-memory dictionary. Mirrors
    /// ``NrovaConfiguration/fromInfoDictionary(_:keys:bundleIdentifier:endpoints:defaultHeaders:timeout:)``.
    public static func fromInfoDictionary(
        _ infoDictionary: [String: Any],
        keys: NrovaConfiguration.InfoPlistKeys = .default,
        bundleIdentifier: String? = nil,
        endpoints: ServiceEndpoints = .production,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30,
        transport: NrovaTransport = URLSession.shared
    ) throws -> NrovaClient {
        let configuration = try NrovaConfiguration.fromInfoDictionary(
            infoDictionary,
            keys: keys,
            bundleIdentifier: bundleIdentifier,
            endpoints: endpoints,
            defaultHeaders: defaultHeaders,
            timeout: timeout
        )
        return NrovaClient(configuration: configuration, transport: transport)
    }
}
