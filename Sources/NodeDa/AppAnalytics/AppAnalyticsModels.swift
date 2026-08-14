import Foundation

/// Schema id for the App Analytics ingest HTTP API.
public enum AppAnalyticsSchema {
    public static let v1 = "nrova.app-analytics.v1"
}

/// Scopes required on Developer API keys for App Analytics.
///
/// Ingest requires ``write``. ``read`` cannot ingest.
public enum AppAnalyticsScope {
    public static let write = "app-analytics:write"
    public static let read = "app-analytics:read"
}

/// Foreground seconds before an install counts as an active user.
public enum AppAnalyticsActiveUserThreshold {
    public static let `default` = 120
    public static let minimum = 30
    public static let maximum = 3600
}

/// Wire `platform` for `POST …/app-analytics/events`.
public enum AppAnalyticsPlatform: String, Codable, Sendable, CaseIterable, Equatable {
    case ios
    case android
    case macos
    case windows
    case linux
    case other

    /// Compile-time platform of the current Apple OS.
    public static var current: AppAnalyticsPlatform {
        #if os(iOS)
        return .ios
        #elseif os(macOS)
        return .macos
        #else
        return .other
        #endif
    }
}

/// Wire `sdk` for `POST …/app-analytics/events`.
public enum AppAnalyticsSDK: String, Codable, Sendable, CaseIterable, Equatable {
    case flutter
    case android
    case ios
    case macos
    case reactNative = "react-native"
    case unity
    case other

    /// SDK identifier for this Apple package.
    public static var current: AppAnalyticsSDK {
        #if os(macOS)
        return .macos
        #elseif os(iOS)
        return .ios
        #else
        return .other
        #endif
    }
}

/// Event types accepted in an ingest batch (1–50 items).
public enum AppAnalyticsEventType: String, Codable, Sendable, CaseIterable, Equatable {
    case sessionStart = "session_start"
    case heartbeat
    case screen
    case sessionEnd = "session_end"
}

/// One event in an App Analytics ingest batch.
///
/// `screen` events require ``screen``. Heartbeat / `session_end` may include
/// ``foregroundDurationMs`` (cumulative foreground time for the session).
/// Omit ``ts`` to let the server stamp the receive time. Never send a raw IP
/// or user identity — country and region are resolved server-side.
public struct AppAnalyticsEvent: Codable, Sendable, Equatable {
    public var type: AppAnalyticsEventType
    public var ts: Int?
    public var screen: String?
    public var foregroundDurationMs: Int?

    public init(
        type: AppAnalyticsEventType,
        ts: Int? = nil,
        screen: String? = nil,
        foregroundDurationMs: Int? = nil
    ) {
        self.type = type
        self.ts = ts
        self.screen = screen
        self.foregroundDurationMs = foregroundDurationMs
    }

    public static func sessionStart(ts: Int? = nil) -> AppAnalyticsEvent {
        AppAnalyticsEvent(type: .sessionStart, ts: ts)
    }

    public static func heartbeat(
        ts: Int? = nil,
        foregroundDurationMs: Int? = nil
    ) -> AppAnalyticsEvent {
        AppAnalyticsEvent(type: .heartbeat, ts: ts, foregroundDurationMs: foregroundDurationMs)
    }

    /// Developer-facing screen name (max 80 chars on the server).
    public static func screen(_ name: String, ts: Int? = nil) -> AppAnalyticsEvent {
        AppAnalyticsEvent(type: .screen, ts: ts, screen: name)
    }

    public static func sessionEnd(
        ts: Int? = nil,
        foregroundDurationMs: Int? = nil
    ) -> AppAnalyticsEvent {
        AppAnalyticsEvent(type: .sessionEnd, ts: ts, foregroundDurationMs: foregroundDurationMs)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(ts, forKey: .ts)
        try container.encodeIfPresent(screen, forKey: .screen)
        try container.encodeIfPresent(foregroundDurationMs, forKey: .foregroundDurationMs)
    }
}

/// Request body for `POST …/app-analytics/events`.
///
/// Apps auto-register from ``bundleId``. JSON body limit is ~64 KB.
/// Rate limit is ~120 requests / minute / org+app+install.
public struct AppAnalyticsIngestRequest: Codable, Sendable, Equatable {
    public var bundleId: String
    public var platform: AppAnalyticsPlatform
    public var installId: String
    public var sessionId: String
    public var events: [AppAnalyticsEvent]
    public var sdk: AppAnalyticsSDK?
    public var appVersion: String?
    public var osVersion: String?
    public var activeUserThresholdSeconds: Int?

    public init(
        bundleId: String,
        platform: AppAnalyticsPlatform,
        installId: String,
        sessionId: String,
        events: [AppAnalyticsEvent],
        sdk: AppAnalyticsSDK? = nil,
        appVersion: String? = nil,
        osVersion: String? = nil,
        activeUserThresholdSeconds: Int? = nil
    ) {
        self.bundleId = bundleId
        self.platform = platform
        self.installId = installId
        self.sessionId = sessionId
        self.events = events
        self.sdk = sdk
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.activeUserThresholdSeconds = activeUserThresholdSeconds
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bundleId, forKey: .bundleId)
        try container.encode(platform, forKey: .platform)
        try container.encode(installId, forKey: .installId)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(events, forKey: .events)
        try container.encodeIfPresent(sdk, forKey: .sdk)
        try container.encodeIfPresent(appVersion, forKey: .appVersion)
        try container.encodeIfPresent(osVersion, forKey: .osVersion)
        try container.encodeIfPresent(activeUserThresholdSeconds, forKey: .activeUserThresholdSeconds)
    }
}

/// Success body for `POST …/app-analytics/events` (`200`).
public struct AppAnalyticsIngestResponse: Codable, Sendable, Equatable {
    public let ok: Bool
    public let schema: String?
    public let appId: String?
    public let bundleId: String?
    public let qualifiedActive: Bool?
    public let activeUserThresholdSeconds: Int?
}

/// Opaque install / session ids: 8–64 letters, digits, `_` or `-`.
/// Persist ``installId`` on device; mint a new ``sessionId`` each foreground.
public enum AppAnalyticsOpaqueId {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-")
    private static let pattern = try! NSRegularExpression(pattern: "^[A-Za-z0-9_-]{8,64}$")

    public static func generate(length: Int = 22) -> String {
        let n = min(max(length, 8), 64)
        return String((0..<n).map { _ in alphabet.randomElement()! })
    }

    public static func isValid(_ value: String) -> Bool {
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return pattern.firstMatch(in: value, options: [], range: range) != nil
    }
}
