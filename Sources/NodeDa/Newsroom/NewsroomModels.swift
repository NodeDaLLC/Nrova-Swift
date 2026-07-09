import Foundation

public enum NewsroomStatus: String, Codable, Sendable, CaseIterable, Equatable {
    case draft
    case scheduled
    case published
}

public struct NewsroomCategory: Codable, Sendable, Equatable {
    public let id: String
    public let slug: String?
    public let label: String?
    public let color: String?
    public let sortOrder: Int?
    public let createdAt: String?
}

public struct NewsroomCategoriesResponse: Codable, Sendable, Equatable {
    public let categories: [NewsroomCategory]
}

public struct NewsroomPost: Codable, Sendable, Equatable {
    public let id: String
    public let slug: String
    public let title: String
    public let categoryId: String
    public let tags: [String]?
    public let excerpt: String?
    public let body: String?
    public let status: NewsroomStatus
    public let heroImageUrl: String?
    public let createdBy: String?
    public let publishedAt: String?
    public let scheduledFor: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let document: JSONValue?
}

public struct NewsroomPostsResponse: Codable, Sendable, Equatable {
    public let posts: [NewsroomPost]
}

public struct NewsroomPostResponse: Codable, Sendable, Equatable {
    public let post: NewsroomPost
}

// MARK: - Request bodies

public struct CreateNewsroomPostRequest: Codable, Sendable, Equatable {
    public var title: String
    public var categoryId: String
    public var slug: String?
    public var body: String?
    public var excerpt: String?
    public var tags: [String]?
    public var heroImageUrl: String?
    public var status: NewsroomStatus?
    public var scheduledFor: String?

    public init(
        title: String,
        categoryId: String,
        slug: String? = nil,
        body: String? = nil,
        excerpt: String? = nil,
        tags: [String]? = nil,
        heroImageUrl: String? = nil,
        status: NewsroomStatus? = nil,
        scheduledFor: String? = nil
    ) {
        self.title = title
        self.categoryId = categoryId
        self.slug = slug
        self.body = body
        self.excerpt = excerpt
        self.tags = tags
        self.heroImageUrl = heroImageUrl
        self.status = status
        self.scheduledFor = scheduledFor
    }
}

public struct UpdateNewsroomPostRequest: Codable, Sendable, Equatable {
    public var title: String?
    public var categoryId: String?
    public var slug: String?
    public var body: String?
    public var excerpt: String?
    public var tags: [String]?
    public var heroImageUrl: String?
    public var status: NewsroomStatus?
    public var scheduledFor: String?

    public init(
        title: String? = nil,
        categoryId: String? = nil,
        slug: String? = nil,
        body: String? = nil,
        excerpt: String? = nil,
        tags: [String]? = nil,
        heroImageUrl: String? = nil,
        status: NewsroomStatus? = nil,
        scheduledFor: String? = nil
    ) {
        self.title = title
        self.categoryId = categoryId
        self.slug = slug
        self.body = body
        self.excerpt = excerpt
        self.tags = tags
        self.heroImageUrl = heroImageUrl
        self.status = status
        self.scheduledFor = scheduledFor
    }
}
