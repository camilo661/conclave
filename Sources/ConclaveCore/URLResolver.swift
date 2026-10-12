import Foundation

/// Turns whatever the user typed or said into a URL that is safe to load:
/// either a web address or Conclave's own results page.
public enum URLResolver {
    /// Only these schemes may be loaded from user input. Anything else
    /// (`file:`, `javascript:`, `data:`…) is treated as a search query.
    public static let allowedSchemes: Set<String> = ["http", "https"]

    public static func resolve(_ input: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if let url = explicitURL(from: text) { return url }
        if looksLikeHost(text), let url = URL(string: "https://\(text)") { return url }
        return InternalPage.searchURL(for: text)
    }

    private static func explicitURL(from text: String) -> URL? {
        guard !text.contains(" "), let url = URL(string: text) else { return nil }
        if InternalPage.searchQuery(from: url) != nil { return url }

        guard let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme),
              url.host?.isEmpty == false
        else { return nil }
        return url
    }

    /// `example.com`, `example.com/path`, `localhost:3000`, `192.168.0.1`.
    static func looksLikeHost(_ text: String) -> Bool {
        guard !text.contains(" "), !text.contains("://") else { return false }
        let authority = text.prefix { $0 != "/" && $0 != "?" && $0 != "#" }
        let host = authority.split(separator: ":", maxSplits: 1).first.map(String.init) ?? ""
        guard !host.isEmpty else { return false }
        if host == "localhost" { return true }

        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2, let last = labels.last, last.count >= 2 else { return false }
        return labels.allSatisfy { label in
            !label.isEmpty && label.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" }
        }
    }
}
