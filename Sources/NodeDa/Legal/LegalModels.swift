import Foundation

public enum LegalPolicyStatus: String, Codable, Sendable, CaseIterable, Equatable {
    case draft
    case published
    case archived
}

public struct LegalPolicy: Codable, Sendable, Equatable {
    public let id: String
    public let key: String
    public let title: String
    public let description: String?
    public let status: LegalPolicyStatus?
    public let sectionCount: Int?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct LegalPolicySection: Codable, Sendable, Equatable {
    public let id: String
    public let title: String?
    public let body: String
    public let sortOrder: Int?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct LegalPoliciesResponse: Codable, Sendable, Equatable {
    public let orgId: String?
    public let policies: [LegalPolicy]
    public let generatedAt: String?
}

public struct LegalPolicyResponse: Codable, Sendable, Equatable {
    public let orgId: String?
    public let policy: LegalPolicy
    public let sections: [LegalPolicySection]
    public let generatedAt: String?
}

public struct LegalPolicySectionResponse: Codable, Sendable, Equatable {
    public let section: LegalPolicySection
}

// MARK: - Request bodies

public struct CreateLegalPolicyRequest: Codable, Sendable, Equatable {
    public var key: String
    public var title: String
    public var description: String?
    public var status: LegalPolicyStatus?

    public init(
        key: String,
        title: String,
        description: String? = nil,
        status: LegalPolicyStatus? = nil
    ) {
        self.key = key
        self.title = title
        self.description = description
        self.status = status
    }
}

public struct UpdateLegalPolicyRequest: Codable, Sendable, Equatable {
    public var title: String?
    public var description: String?
    public var status: LegalPolicyStatus?

    public init(
        title: String? = nil,
        description: String? = nil,
        status: LegalPolicyStatus? = nil
    ) {
        self.title = title
        self.description = description
        self.status = status
    }
}

public struct CreateLegalSectionRequest: Codable, Sendable, Equatable {
    public var title: String?
    public var body: String
    public var sortOrder: Int?

    public init(title: String? = nil, body: String, sortOrder: Int? = nil) {
        self.title = title
        self.body = body
        self.sortOrder = sortOrder
    }
}

public struct UpdateLegalSectionRequest: Codable, Sendable, Equatable {
    public var title: String?
    public var body: String?
    public var sortOrder: Int?

    public init(title: String? = nil, body: String? = nil, sortOrder: Int? = nil) {
        self.title = title
        self.body = body
        self.sortOrder = sortOrder
    }
}

/// Stable policy keys present in the live NodeDa Vertex organization.
public enum LegalPolicyKey {
    public static let privacy = "privacy"
    public static let privacyChoices = "privacy_choices"
    public static let terms = "terms"
}
