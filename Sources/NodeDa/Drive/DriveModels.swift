import Foundation

/// Which Drive the signed-in user is talking to.
/// Wire value is `personal` (My Drive) or `shared` (Organization Drive).
public enum DriveSpace: String, Codable, Sendable, CaseIterable, Equatable {
    case personal
    case shared

    public static var my: DriveSpace { .personal }
    public static var organization: DriveSpace { .shared }
}

public enum DriveItemKind: String, Codable, Sendable, Equatable {
    case folder
    case file
}

public enum DriveConnectedKind: String, Codable, Sendable, Equatable {
    case my
    case organization
}

public struct DriveConnectedDrive: Codable, Sendable, Equatable {
    public var kind: DriveConnectedKind
    public var space: DriveSpace
    public var name: String
}

/// A connected Drive account from `GET /v1/drive/session`.
/// `id` is an opaque account id from the session — not a Kit organization setting.
public struct DriveAccount: Codable, Sendable, Equatable {
    public var id: String
    public var name: String
    public var driveAccessible: Bool
    public var drives: [DriveConnectedDrive]
}

public struct DriveSessionUser: Codable, Sendable, Equatable {
    public var uid: String
    public var email: String?
}

public struct DriveSession: Codable, Sendable, Equatable {
    public var schema: String?
    public var user: DriveSessionUser
    public var accounts: [DriveAccount]
}

public struct DriveUsage: Codable, Sendable, Equatable {
    public var usedBytes: Int
    public var quotaBytes: Int
}

public struct DriveUserProfile: Codable, Sendable, Equatable {
    public var uid: String
    public var email: String?
    public var displayName: String?
}

public struct DriveUserResponse: Codable, Sendable, Equatable {
    public var schema: String?
    public var user: DriveUserProfile
    public var usage: DriveUsage
    public var drives: [DriveConnectedDrive]
}

public struct DriveItem: Codable, Sendable, Equatable {
    public var id: String
    public var kind: DriveItemKind
    public var name: String
    public var parentId: String?
    public var space: DriveSpace
    public var ownerUid: String?
    public var createdBy: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var appKey: String?
    public var mimeType: String?
    public var sizeBytes: Int?
    public var contentType: String?
}

public struct DriveFolderResponse: Codable, Sendable, Equatable {
    public var schema: String?
    public var created: Bool?
    public var folder: DriveItem
    public var user: DriveSessionUser?
}

public struct DriveItemsResponse: Codable, Sendable, Equatable {
    public var schema: String?
    public var parentId: String?
    public var space: DriveSpace?
    public var items: [DriveItem]
    public var user: DriveSessionUser?
}

public struct DriveItemResponse: Codable, Sendable, Equatable {
    public var schema: String?
    public var item: DriveItem
    public var user: DriveSessionUser?
}

public struct DriveTrashResponse: Codable, Sendable, Equatable {
    public var schema: String?
    public var trashed: Bool
    public var itemId: String
    public var user: DriveSessionUser?
}

public struct DriveCreateAppFolderRequest: Codable, Sendable, Equatable {
    public var appKey: String
    public var name: String?

    public init(appKey: String, name: String? = nil) {
        self.appKey = appKey
        self.name = name
    }
}

public struct DriveCreateFolderRequest: Codable, Sendable, Equatable {
    public var name: String
    public var parentId: String?
    public var space: DriveSpace?
    public var appKey: String?

    public init(name: String, parentId: String? = nil, space: DriveSpace? = nil, appKey: String? = nil) {
        self.name = name
        self.parentId = parentId
        self.space = space
        self.appKey = appKey
    }
}

public struct DriveInitUploadRequest: Codable, Sendable, Equatable {
    public var name: String
    public var mimeType: String
    public var sizeBytes: Int
    public var parentId: String?

    public init(name: String, mimeType: String, sizeBytes: Int, parentId: String? = nil) {
        self.name = name
        self.mimeType = mimeType
        self.sizeBytes = sizeBytes
        self.parentId = parentId
    }
}

public struct DriveInitUploadResponse: Codable, Sendable, Equatable {
    public var schema: String?
    public var fileId: String
    public var uploadUrl: String
    public var uploadMethod: String?
    public var storagePath: String
    public var expiresAt: String?
    public var user: DriveSessionUser?
}

public struct DriveFinalizeUploadRequest: Codable, Sendable, Equatable {
    public var name: String
    public var storagePath: String
    public var sizeBytes: Int
    public var mimeType: String
    public var parentId: String?

    public init(name: String, storagePath: String, sizeBytes: Int, mimeType: String, parentId: String? = nil) {
        self.name = name
        self.storagePath = storagePath
        self.sizeBytes = sizeBytes
        self.mimeType = mimeType
        self.parentId = parentId
    }
}

public struct DriveFileResponse: Codable, Sendable, Equatable {
    public var schema: String?
    public var file: DriveItem
    public var user: DriveSessionUser?
}

public struct DriveContentResponse: Codable, Sendable, Equatable {
    public var schema: String?
    public var downloadUrl: String
    public var expiresAt: String?
    public var item: DriveItem?
}
