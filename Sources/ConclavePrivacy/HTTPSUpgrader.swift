import Foundation

/// Decides when a plain-HTTP navigation should be retried over HTTPS, and
/// remembers the hosts the user explicitly agreed to visit without encryption.
public struct HTTPSUpgrader {
    private var allowedInsecureHosts: Set<String> = []

    public init() {}

    /// The HTTPS equivalent of `url`, or `nil` when no upgrade applies.
    public func upgradedURL(for url: URL) -> URL? {
        guard url.scheme?.lowercased() == "http",
              let host = url.host?.lowercased(),
              !Self.isLocal(host),
              !allowedInsecureHosts.contains(host),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }

        components.scheme = "https"
        if components.port == 80 { components.port = nil }
        return components.url
    }

    /// Allows HTTP for this host until the app quits.
    public mutating func allowInsecure(host: String) {
        allowedInsecureHosts.insert(host.lowercased())
    }

    static func isLocal(_ host: String) -> Bool {
        if host == "localhost" || host.hasSuffix(".localhost") || host.hasSuffix(".local") { return true }
        if host.contains(":") { return true } // IPv6 literal
        let parts = host.split(separator: ".")
        return parts.count == 4 && parts.allSatisfy { UInt8($0) != nil } // IPv4 literal
    }
}
