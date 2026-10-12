import Foundation

/// Builds the WebKit content-rule-list JSON used by `ContentBlocker`.
public enum ContentRuleBuilder {
    public static func trackerRules(domains: [String] = TrackerBlocklist.domains) -> [[String: Any]] {
        var rules: [[String: Any]] = domains.map { domain in
            [
                "trigger": [
                    "url-filter": urlFilter(forDomain: domain),
                    "load-type": ["third-party"],
                ],
                "action": ["type": "block"],
            ]
        }
        // No cookies for any third-party request, tracker or not.
        rules.append([
            "trigger": ["url-filter": ".*", "load-type": ["third-party"]],
            "action": ["type": "block-cookies"],
        ])
        return rules
    }

    public static func encode(_ rules: [[String: Any]]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: rules)
        return String(decoding: data, as: UTF8.self)
    }

    /// Matches the domain itself and any subdomain, on any scheme and port.
    static func urlFilter(forDomain domain: String) -> String {
        let escaped = domain.replacingOccurrences(of: ".", with: "\\.")
        return "^[^:]+://+([^:/]+\\.)?\(escaped)[:/]"
    }
}
