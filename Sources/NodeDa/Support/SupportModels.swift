import Foundation

public enum SupportPriority: String, Codable, Sendable, CaseIterable, Equatable {
    case low
    case medium
    case high
    case urgent
}

public enum SupportCategory: String, Codable, Sendable, CaseIterable, Equatable {
    case billing
    case technical
    case account
    case featureRequest = "feature_request"
    case general
    case other
}

public struct SupportTicket: Codable, Sendable, Equatable {
    public let id: String
    public let contactEmail: String
    public let applicationName: String?
    public let subject: String
    public let body: String?
    public let priority: String?
    public let category: String?
    public let status: String?
    public let channel: String?
    public let environment: String?
    public let deviceInfo: String?
    public let relatedUrl: String?
    public let requesterName: String?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct SupportComment: Codable, Sendable, Equatable {
    public let id: String
    public let ticketId: String?
    public let body: String
    public let authorDisplayName: String?
    public let authorEmail: String?
    public let isInternal: Bool?
    public let createdAt: String?
}

// MARK: - Request bodies

public struct CreateSupportTicketRequest: Codable, Sendable, Equatable {
    public var contactEmail: String
    public var applicationName: String
    public var subject: String
    public var body: String
    public var priority: SupportPriority?
    public var category: SupportCategory?
    public var channel: String?
    public var environment: String?
    public var deviceInfo: String?
    public var relatedUrl: String?
    public var requesterName: String?

    public init(
        contactEmail: String,
        applicationName: String,
        subject: String,
        body: String,
        priority: SupportPriority? = nil,
        category: SupportCategory? = nil,
        channel: String? = nil,
        environment: String? = nil,
        deviceInfo: String? = nil,
        relatedUrl: String? = nil,
        requesterName: String? = nil
    ) {
        self.contactEmail = contactEmail
        self.applicationName = applicationName
        self.subject = subject
        self.body = body
        self.priority = priority
        self.category = category
        self.channel = channel
        self.environment = environment
        self.deviceInfo = deviceInfo
        self.relatedUrl = relatedUrl
        self.requesterName = requesterName
    }
}

public struct CreateSupportCommentRequest: Codable, Sendable, Equatable {
    public var body: String
    public var authorDisplayName: String?
    public var authorEmail: String?
    public var isInternal: Bool?

    public init(
        body: String,
        authorDisplayName: String? = nil,
        authorEmail: String? = nil,
        isInternal: Bool? = nil
    ) {
        self.body = body
        self.authorDisplayName = authorDisplayName
        self.authorEmail = authorEmail
        self.isInternal = isInternal
    }
}

// MARK: - Response envelopes

public struct SupportTicketsResponse: Codable, Sendable, Equatable {
    public let tickets: [SupportTicket]
}

public struct SupportTicketResponse: Codable, Sendable, Equatable {
    public let ticket: SupportTicket
}

public struct SupportCommentsResponse: Codable, Sendable, Equatable {
    public let comments: [SupportComment]
}

public struct SupportCommentResponse: Codable, Sendable, Equatable {
    public let comment: SupportComment
}
