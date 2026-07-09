import Foundation

/// Public version metadata for the NodeDa Vertex package.
///
/// Pinned in code so callers can verify what they're running against
/// (handy when filing bug reports or logging boot-time diagnostics):
///
/// ```swift
/// print("NodeDa Vertex SDK", NodeDa.version)
/// ```
public enum NodeDa {
    /// Semantic version of the published SDK. Bumped in lockstep with
    /// the `Package.swift` tag.
    public static let version = "1.1.0"
}
