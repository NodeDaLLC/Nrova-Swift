import Foundation

/// A job posting returned from `GET …/careers/postings`.
public struct CareerPosting: Codable, Sendable, Equatable {
    public let requisitionNodeId: String
    public let title: String?
    public let location: String?
    public let department: String?
    public let employmentType: String?
    public let description: String?
    public let publishedAt: String?
    public let updatedAt: String?
    public let isOpen: Bool?
}

public struct CareerPostingsResponse: Codable, Sendable, Equatable {
    public let postings: [CareerPosting]
}

public struct CareerPostingResponse: Codable, Sendable, Equatable {
    public let posting: CareerPosting
}

/// Application form definition. Sections + fields are returned verbatim so
/// the client can render dynamic forms.
public struct CareerApplicationTemplate: Codable, Sendable, Equatable {
    public let templateVersion: String
    public let sections: [CareerTemplateSection]
}

public struct CareerTemplateSection: Codable, Sendable, Equatable {
    public let id: String
    public let title: String?
    public let description: String?
    public let fields: [CareerTemplateField]
}

public struct CareerTemplateField: Codable, Sendable, Equatable {
    public let id: String
    public let type: String
    public let label: String?
    public let required: Bool?
    public let options: [String]?
    public let helpText: String?
}

public struct CareerApplicationTemplateResponse: Codable, Sendable, Equatable {
    public let template: CareerApplicationTemplate
}

/// One submitted application.
public struct CareerApplication: Codable, Sendable, Equatable {
    public let id: String
    public let requisitionNodeId: String?
    public let applicantEmail: String?
    public let contactEmail: String?
    public let templateVersion: String?
    public let status: String?
    public let answers: [String: JSONValue]?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct CareerApplicationsResponse: Codable, Sendable, Equatable {
    public let applications: [CareerApplication]
}

public struct CareerApplicationResponse: Codable, Sendable, Equatable {
    public let application: CareerApplication
}

// MARK: - Submission body

public struct SubmitCareerApplicationRequest: Codable, Sendable, Equatable {
    public var requisitionNodeId: String
    public var templateVersion: String
    public var applicantEmail: String
    public var answers: [String: JSONValue]

    public init(
        requisitionNodeId: String,
        templateVersion: String,
        applicantEmail: String,
        answers: [String: JSONValue]
    ) {
        self.requisitionNodeId = requisitionNodeId
        self.templateVersion = templateVersion
        self.applicantEmail = applicantEmail
        self.answers = answers
    }
}
