import Foundation

/// Client for the **NodeDa Drive HTTP API** (`nrova.drive.v1`).
///
/// Paths live under `/v1/drive/…` — not `/v1/organizations/{orgId}/…`.
/// Auth is a **Firebase ID token** for the signed-in NodeDa user (no developer
/// API key, no `NodeDaOrganizationId`). One login connects **My Drive** and
/// **Organization Drive**. If the user has more than one connected account,
/// pass `accountId` from ``session(idToken:)``.
///
/// ```swift
/// let session = try await client.drive.session(idToken: idToken)
/// let folder = try await client.drive.createAppFolder(
///     idToken: idToken,
///     appKey: "com.example.notes"
/// )
/// ```
public struct DriveService: Sendable {
    let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    private func idHeaders(_ idToken: String, accountId: String?) -> [String: String] {
        var headers = [
            "Authorization": "Bearer \(idToken)",
            "X-Firebase-Id-Token": idToken,
        ]
        if let accountId, !accountId.isEmpty {
            headers["X-NodeDa-Account"] = accountId
        }
        return headers
    }

    private func accountQuery(_ accountId: String?) -> [String: String?] {
        ["accountId": accountId]
    }

    /// `GET /health` — no token.
    public func health() async throws -> HealthResponse {
        try await http.get("/health", authenticated: false)
    }

    /// `GET /v1/drive/session` — signed-in user + connected Drive accounts.
    public func session(idToken: String) async throws -> DriveSession {
        try await http.get(
            "/v1/drive/session",
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: nil)
        )
    }

    /// `GET /v1/drive/user` — quota for this signed-in user.
    public func user(idToken: String, accountId: String? = nil) async throws -> DriveUserResponse {
        try await http.get(
            "/v1/drive/user",
            query: accountQuery(accountId),
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: accountId)
        )
    }

    /// Idempotent app folder in **My Drive**.
    @discardableResult
    public func createAppFolder(
        idToken: String,
        appKey: String,
        name: String? = nil,
        accountId: String? = nil
    ) async throws -> DriveFolderResponse {
        try await http.post(
            "/v1/drive/app-folders",
            query: accountQuery(accountId),
            body: DriveCreateAppFolderRequest(appKey: appKey, name: name),
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: accountId)
        )
    }

    @discardableResult
    public func createFolder(
        idToken: String,
        name: String,
        parentId: String? = nil,
        space: DriveSpace? = nil,
        accountId: String? = nil
    ) async throws -> DriveFolderResponse {
        try await http.post(
            "/v1/drive/folders",
            query: accountQuery(accountId),
            body: DriveCreateFolderRequest(name: name, parentId: parentId, space: space),
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: accountId)
        )
    }

    public func listItems(
        idToken: String,
        parentId: String? = nil,
        space: DriveSpace = .my,
        limit: Int? = nil,
        accountId: String? = nil
    ) async throws -> DriveItemsResponse {
        var query: [String: String?] = accountQuery(accountId)
        query["parentId"] = parentId
        query["space"] = space.rawValue
        if let limit { query["limit"] = String(limit) }
        return try await http.get(
            "/v1/drive/items",
            query: query,
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: accountId)
        )
    }

    public func getItem(
        idToken: String,
        itemId: String,
        accountId: String? = nil
    ) async throws -> DriveItemResponse {
        try await http.get(
            "/v1/drive/items/\(itemId)",
            query: accountQuery(accountId),
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: accountId)
        )
    }

    public func trashItem(
        idToken: String,
        itemId: String,
        accountId: String? = nil
    ) async throws {
        try await http.delete(
            "/v1/drive/items/\(itemId)",
            query: accountQuery(accountId),
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: accountId)
        )
    }

    public func initiateUpload(
        idToken: String,
        name: String,
        mimeType: String,
        sizeBytes: Int,
        parentId: String? = nil,
        accountId: String? = nil
    ) async throws -> DriveInitUploadResponse {
        try await http.post(
            "/v1/drive/files",
            query: accountQuery(accountId),
            body: DriveInitUploadRequest(name: name, mimeType: mimeType, sizeBytes: sizeBytes, parentId: parentId),
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: accountId)
        )
    }

    @discardableResult
    public func finalizeUpload(
        idToken: String,
        fileId: String,
        name: String,
        storagePath: String,
        sizeBytes: Int,
        mimeType: String,
        parentId: String? = nil,
        accountId: String? = nil
    ) async throws -> DriveFileResponse {
        try await http.post(
            "/v1/drive/files/\(fileId)/finalize",
            query: accountQuery(accountId),
            body: DriveFinalizeUploadRequest(
                name: name,
                storagePath: storagePath,
                sizeBytes: sizeBytes,
                mimeType: mimeType,
                parentId: parentId
            ),
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: accountId)
        )
    }

    public func content(
        idToken: String,
        fileId: String,
        accountId: String? = nil
    ) async throws -> DriveContentResponse {
        try await http.get(
            "/v1/drive/files/\(fileId)/content",
            query: accountQuery(accountId),
            authenticated: false,
            extraHeaders: idHeaders(idToken, accountId: accountId)
        )
    }
}
