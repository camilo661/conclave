import Foundation

/// Removes click identifiers and campaign tags that let sites follow a user
/// from one page to the next.
public enum TrackingParameterStripper {
    static let exactNames: Set<String> = [
        "fbclid", "gclid", "gclsrc", "dclid", "gbraid", "wbraid", "msclkid",
        "twclid", "ttclid", "yclid", "igshid", "mc_cid", "mc_eid", "_hsenc",
        "_hsmi", "mkt_tok", "oly_anon_id", "oly_enc_id", "vero_id", "s_cid",
    ]
    static let prefixes = ["utm_"]

    /// Returns the cleaned URL, or the original one if nothing had to be removed.
    public static func strip(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems, !items.isEmpty
        else { return url }

        let kept = items.filter { !isTracking($0.name) }
        guard kept.count != items.count else { return url }

        components.queryItems = kept.isEmpty ? nil : kept
        return components.url ?? url
    }

    static func isTracking(_ name: String) -> Bool {
        let lowered = name.lowercased()
        return exactNames.contains(lowered) || prefixes.contains { lowered.hasPrefix($0) }
    }
}
