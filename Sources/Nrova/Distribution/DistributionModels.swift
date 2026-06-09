import Foundation

// MARK: - Enums

/// Platforms supported by the Distribution API.
public enum DistributionPlatform: String, Codable, Sendable, CaseIterable, Equatable {
    case macos
    case windows
}

/// Release channels.
public enum DistributionChannel: String, Codable, Sendable, CaseIterable, Equatable {
    case stable
    case beta
    case dev
}

/// Distinguishes auto-update payloads (typically `.zip`) from user-facing
/// installers (typically `.dmg`). The API treats missing as `update`.
public enum DistributionArtifactPurpose: String, Codable, Sendable, CaseIterable, Equatable {
    case install
    case update
}

/// Architectures the Distribution API reports for an artifact.
public enum DistributionArchitecture: String, Codable, Sendable, CaseIterable, Equatable {
    case x64
    case arm64
    case universal
    case x86
}

// MARK: - Application

/// A distribution application — typically maps to one product line shipping
/// both a macOS and Windows binary.
public struct DistributionApplication: Codable, Sendable, Equatable {
    public let id: String
    public let slug: String
    public let name: String
    public let platforms: [DistributionPlatform]
    public let bundleId: String?
    public let description: String?
    public let homepageUrl: String?
    public let iconUrl: String?
    public let iconStoragePath: String?
    public let isPublic: Bool?
    public let latest: [String: [String: DistributionLatestPointer]]?
    public let createdAt: String?
    public let updatedAt: String?

    public init(
        id: String,
        slug: String,
        name: String,
        platforms: [DistributionPlatform],
        bundleId: String? = nil,
        description: String? = nil,
        homepageUrl: String? = nil,
        iconUrl: String? = nil,
        iconStoragePath: String? = nil,
        isPublic: Bool? = nil,
        latest: [String: [String: DistributionLatestPointer]]? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.platforms = platforms
        self.bundleId = bundleId
        self.description = description
        self.homepageUrl = homepageUrl
        self.iconUrl = iconUrl
        self.iconStoragePath = iconStoragePath
        self.isPublic = isPublic
        self.latest = latest
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Pointer to the most recent release for a platform/channel pair.
public struct DistributionLatestPointer: Codable, Sendable, Equatable {
    public let releaseId: String
    public let version: String
    public let updatedAt: String?
}

// MARK: - Releases & artifacts

public struct DistributionRelease: Codable, Sendable, Equatable {
    public let id: String
    public let version: String
    public let channel: DistributionChannel
    public let buildNumber: String?
    public let notes: String?
    public let isYanked: Bool
    public let releasedAt: String?
    public let updatedAt: String?
    public let artifacts: [DistributionArtifact]
}

public struct DistributionArtifact: Codable, Sendable, Equatable {
    public let platform: DistributionPlatform
    public let fileName: String
    public let downloadUrl: String
    public let sizeBytes: Int
    public let contentType: String
    public let sha256: String?
    public let version: String?
    public let buildNumber: String?
    public let minOsVersion: String?
    public let architecture: DistributionArchitecture?
    public let installPurpose: DistributionArtifactPurpose?
    public let metadataAutoDetected: Bool?

    public init(
        platform: DistributionPlatform,
        fileName: String,
        downloadUrl: String,
        sizeBytes: Int,
        contentType: String,
        sha256: String? = nil,
        version: String? = nil,
        buildNumber: String? = nil,
        minOsVersion: String? = nil,
        architecture: DistributionArchitecture? = nil,
        installPurpose: DistributionArtifactPurpose? = nil,
        metadataAutoDetected: Bool? = nil
    ) {
        self.platform = platform
        self.fileName = fileName
        self.downloadUrl = downloadUrl
        self.sizeBytes = sizeBytes
        self.contentType = contentType
        self.sha256 = sha256
        self.version = version
        self.buildNumber = buildNumber
        self.minOsVersion = minOsVersion
        self.architecture = architecture
        self.installPurpose = installPurpose
        self.metadataAutoDetected = metadataAutoDetected
    }
}

// MARK: - Response envelopes

public struct DistributionApplicationsResponse: Codable, Sendable, Equatable {
    public let schema: String?
    public let orgId: String?
    public let applications: [DistributionApplication]
}

public struct DistributionApplicationResponse: Codable, Sendable, Equatable {
    public let schema: String?
    public let application: DistributionApplication
}

public struct DistributionReleasesResponse: Codable, Sendable, Equatable {
    public let schema: String?
    public let appId: String?
    public let releases: [DistributionRelease]
}

public struct DistributionReleaseResponse: Codable, Sendable, Equatable {
    public let schema: String?
    public let release: DistributionRelease
}

public struct DistributionLatestResponse: Codable, Sendable, Equatable {
    public let schema: String?
    public let appId: String
    public let channel: DistributionChannel
    public let platform: DistributionPlatform
    public let release: DistributionRelease
    public let artifact: DistributionArtifact
}

public struct DistributionIconResponse: Codable, Sendable, Equatable {
    public let schema: String?
    public let appId: String?
    public let iconUrl: String
    public let iconStoragePath: String?
}

// MARK: - Request bodies

public struct PublishReleaseRequest: Codable, Sendable, Equatable {
    public var version: String
    public var channel: DistributionChannel
    public var buildNumber: String?
    public var notes: String?
    public var artifacts: [DistributionArtifact]

    public init(
        version: String,
        channel: DistributionChannel,
        buildNumber: String? = nil,
        notes: String? = nil,
        artifacts: [DistributionArtifact]
    ) {
        self.version = version
        self.channel = channel
        self.buildNumber = buildNumber
        self.notes = notes
        self.artifacts = artifacts
    }
}

public struct UpdateReleaseRequest: Codable, Sendable, Equatable {
    public var notes: String?
    public var isYanked: Bool?

    public init(notes: String? = nil, isYanked: Bool? = nil) {
        self.notes = notes
        self.isYanked = isYanked
    }
}
