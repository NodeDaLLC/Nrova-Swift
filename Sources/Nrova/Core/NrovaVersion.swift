import Foundation

/// Public version metadata for the Nrova Swift package.
///
/// Pinned in code so callers can verify what they're running against
/// (handy when filing bug reports or logging boot-time diagnostics):
///
/// ```swift
/// print("Nrova SDK", Nrova.version)
/// ```
public enum Nrova {
    /// Semantic version of the published SDK. Bumped in lockstep with
    /// the `Package.swift` tag.
    public static let version = "1.0.0"
}
