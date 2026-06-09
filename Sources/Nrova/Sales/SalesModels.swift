import Foundation

public enum SalesLeadStatus: String, Codable, Sendable, CaseIterable, Equatable {
    case new
    case working
    case qualified
    case unqualified
    case converted
}

public struct SalesSubmission: Codable, Sendable, Equatable {
    public let id: String
    public let contactEmail: String
    public let formName: String?
    public let firstName: String?
    public let lastName: String?
    public let message: String?
    public let details: String?
    public let leadStatus: String?
    public let leadSource: String?
    public let company: String?
    public let companySize: String?
    public let companyWebsite: String?
    public let address: String?
    public let phone: String?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct SalesComment: Codable, Sendable, Equatable {
    public let id: String
    public let body: String
    public let authorDisplayName: String?
    public let authorEmail: String?
    public let createdAt: String?
}

// MARK: - Request bodies

public struct CreateSalesSubmissionRequest: Codable, Sendable, Equatable {
    public var contactEmail: String
    public var formName: String
    public var firstName: String
    public var lastName: String
    public var message: String?
    public var details: String?
    public var leadStatus: SalesLeadStatus?
    public var leadSource: String?
    public var company: String?
    public var companySize: String?
    public var companyWebsite: String?
    public var address: String?
    public var phone: String?

    public init(
        contactEmail: String,
        formName: String,
        firstName: String,
        lastName: String,
        message: String? = nil,
        details: String? = nil,
        leadStatus: SalesLeadStatus? = nil,
        leadSource: String? = nil,
        company: String? = nil,
        companySize: String? = nil,
        companyWebsite: String? = nil,
        address: String? = nil,
        phone: String? = nil
    ) {
        self.contactEmail = contactEmail
        self.formName = formName
        self.firstName = firstName
        self.lastName = lastName
        self.message = message
        self.details = details
        self.leadStatus = leadStatus
        self.leadSource = leadSource
        self.company = company
        self.companySize = companySize
        self.companyWebsite = companyWebsite
        self.address = address
        self.phone = phone
    }
}

public struct CreateSalesCommentRequest: Codable, Sendable, Equatable {
    public var body: String
    public var authorDisplayName: String?
    public var authorEmail: String?

    public init(
        body: String,
        authorDisplayName: String? = nil,
        authorEmail: String? = nil
    ) {
        self.body = body
        self.authorDisplayName = authorDisplayName
        self.authorEmail = authorEmail
    }
}

// MARK: - Response envelopes

public struct SalesSubmissionsResponse: Codable, Sendable, Equatable {
    public let submissions: [SalesSubmission]
}

public struct SalesSubmissionResponse: Codable, Sendable, Equatable {
    public let submission: SalesSubmission
}

public struct SalesCommentsResponse: Codable, Sendable, Equatable {
    public let comments: [SalesComment]
}

public struct SalesCommentResponse: Codable, Sendable, Equatable {
    public let comment: SalesComment
}
