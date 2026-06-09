import Foundation

public struct FeatureFlag: Codable, Sendable, Equatable {
    public let id: String
    public let key: String
    public let name: String?
    public let description: String?
    public let enabled: Bool
    public let rolloutPercent: Double?
    public let countryMode: String?
    public let countryCodes: [String]?
    public let status: String?
    public let startsAt: String?
    public let endsAt: String?
}

public struct FeatureFlagsResponse: Codable, Sendable, Equatable {
    public let orgId: String
    public let generatedAt: String?
    public let flags: [FeatureFlag]
}

public struct EvaluateFlagsRequest: Codable, Sendable, Equatable {
    public var subjectId: String
    public var countryCode: String?
    public var flagKeys: [String]?

    public init(
        subjectId: String,
        countryCode: String? = nil,
        flagKeys: [String]? = nil
    ) {
        self.subjectId = subjectId
        self.countryCode = countryCode
        self.flagKeys = flagKeys
    }
}

public struct EvaluateFlagsResponse: Codable, Sendable, Equatable {
    public let orgId: String
    public let subjectId: String
    public let countryCode: String?
    public let evaluatedAt: String?
    public let results: [String: Bool]
}
