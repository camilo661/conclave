import Foundation

/// Addresses of the pages the browser generates itself, served under the
/// private `conclave:` scheme.
public enum InternalPage {
    public static let scheme = "conclave"

    private static let searchHost = "search"
    private static let queryName = "q"

    /// Where the results page's own search form submits its `q` field.
    public static let searchEndpoint = "\(scheme)://\(searchHost)"

    /// The address of Conclave's own results page for `query`.
    public static func searchURL(for query: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = searchHost
        components.queryItems = [URLQueryItem(name: queryName, value: query)]
        return components.url!
    }

    /// The query of a results-page address, or `nil` for any other URL.
    public static func searchQuery(from url: URL) -> String? {
        guard url.scheme?.lowercased() == scheme, url.host?.lowercased() == searchHost,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let query = items.first(where: { $0.name == queryName })?.value?
                  .trimmingCharacters(in: .whitespacesAndNewlines),
              !query.isEmpty
        else { return nil }
        return query
    }
}
