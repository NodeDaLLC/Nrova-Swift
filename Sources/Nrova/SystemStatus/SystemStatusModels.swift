import Foundation

/// Rollup status returned by the system status API.
public enum SystemStatusLevel: String, Codable, Sendable, CaseIterable, Equatable {
    case operational
    case degraded
    case partialOutage = "partial_outage"
    case majorOutage = "major_outage"
    case maintenance
    case unknown
}

public struct SystemStatusComponent: Codable, Sendable, Equatable {
    public let id: String
    public let key: String?
    public let name: String?
    public let description: String?
    public let status: SystemStatusLevel?
    public let sortOrder: Int?
    public let updatedAt: String?
}

public struct SystemStatusRollup: Codable, Sendable, Equatable {
    public let status: SystemStatusLevel?
    public let updatedAt: String?
    public let components: [SystemStatusComponent]
}

public struct SystemStatusComponentResponse: Codable, Sendable, Equatable {
    public let component: SystemStatusComponent
}

public struct CreateStatusComponentRequest: Codable, Sendable, Equatable {
    public var key: String
    public var name: String
    public var description: String?
    public var status: SystemStatusLevel?
    public var sortOrder: Int?

    public init(
        key: String,
        name: String,
        description: String? = nil,
        status: SystemStatusLevel? = nil,
        sortOrder: Int? = nil
    ) {
        self.key = key
        self.name = name
        self.description = description
        self.status = status
        self.sortOrder = sortOrder
    }
}

public struct UpdateStatusComponentRequest: Codable, Sendable, Equatable {
    public var name: String?
    public var description: String?
    public var status: SystemStatusLevel?
    public var sortOrder: Int?

    public init(
        name: String? = nil,
        description: String? = nil,
        status: SystemStatusLevel? = nil,
        sortOrder: Int? = nil
    ) {
        self.name = name
        self.description = description
        self.status = status
        self.sortOrder = sortOrder
    }
}
