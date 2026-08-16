import CryptoKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Website sign-in for third-party apps (PKCE). Open ``authorizeURL`` in
/// `ASWebAuthenticationSession` (or a system browser), then ``exchange``.
///
/// Paths are on the NodeDa **website**, not `api.nodeda.com`.
public struct DrivePKCE: Sendable, Equatable {
    public var verifier: String
    public var challenge: String

    public init(verifier: String, challenge: String) {
        self.verifier = verifier
        self.challenge = challenge
    }
}

public struct DriveSignInTokens: Codable, Sendable, Equatable {
    public var tokenType: String
    public var idToken: String
    public var refreshToken: String
    public var expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

public enum DriveAuth: Sendable {
    public static let defaultSiteURL = URL(string: "https://vertex.nodeda.com")!

    /// 32 random bytes as base64url (~43 chars) + S256 challenge.
    public static func makePKCE() -> DrivePKCE {
        var bytes = [UInt8](repeating: 0, count: 32)
        bytes = bytes.map { _ in UInt8.random(in: 0...255) }
        let verifier = Data(bytes).base64URLEncodedString()
        let challenge = sha256Base64URL(verifier)
        return DrivePKCE(verifier: verifier, challenge: challenge)
    }

    public static func authorizeURL(
        clientId: String,
        redirectURI: URL,
        state: String,
        pkce: DrivePKCE,
        appName: String? = nil,
        siteURL: URL = defaultSiteURL
    ) -> URL {
        var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false) ?? URLComponents()
        let trimmed = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = trimmed.isEmpty ? "/connect" : "/\(trimmed)/connect"
        var items: [URLQueryItem] = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI.absoluteString),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        if let appName, !appName.isEmpty {
            items.append(URLQueryItem(name: "name", value: appName))
        }
        components.queryItems = items
        return components.url ?? siteURL.appendingPathComponent("connect")
    }

    public static func exchange(
        code: String,
        pkce: DrivePKCE,
        clientId: String,
        redirectURI: URL,
        siteURL: URL = defaultSiteURL,
        transport: NodeDaTransport = URLSession.shared
    ) async throws -> DriveSignInTokens {
        try await tokenRequest(
            DriveTokenBody(
                grantType: "authorization_code",
                clientId: clientId,
                redirectUri: redirectURI.absoluteString,
                code: code,
                codeVerifier: pkce.verifier,
                refreshToken: nil
            ),
            siteURL: siteURL,
            transport: transport
        )
    }

    public static func refresh(
        refreshToken: String,
        clientId: String,
        siteURL: URL = defaultSiteURL,
        transport: NodeDaTransport = URLSession.shared
    ) async throws -> DriveSignInTokens {
        try await tokenRequest(
            DriveTokenBody(
                grantType: "refresh_token",
                clientId: clientId,
                redirectUri: nil,
                code: nil,
                codeVerifier: nil,
                refreshToken: refreshToken
            ),
            siteURL: siteURL,
            transport: transport
        )
    }

    private static func tokenRequest(
        _ body: DriveTokenBody,
        siteURL: URL,
        transport: NodeDaTransport
    ) async throws -> DriveSignInTokens {
        let configuration = NodeDaConfiguration(apiKey: "")
        let http = HTTPClient(baseURL: siteURL, configuration: configuration, transport: transport, requiresAuth: false)
        return try await http.post("/api/connect/token", body: body, authenticated: false)
    }
}

private struct DriveTokenBody: Encodable {
    var grantType: String
    var clientId: String
    var redirectUri: String?
    var code: String?
    var codeVerifier: String?
    var refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case clientId = "client_id"
        case redirectUri = "redirect_uri"
        case code
        case codeVerifier = "code_verifier"
        case refreshToken = "refresh_token"
    }
}

private func sha256Base64URL(_ string: String) -> String {
    let digest = SHA256.hash(data: Data(string.utf8))
    return Data(digest).base64URLEncodedString()
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
