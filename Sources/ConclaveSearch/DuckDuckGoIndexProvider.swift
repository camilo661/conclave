import Foundation

/// Reads results from DuckDuckGo's script-free HTML endpoint.
///
/// Requests carry no cookies and no identifiers, and the user never lands on
/// the provider's site: only the titles, links and snippets are kept.
public struct DuckDuckGoIndexProvider: SearchProvider {
    private static let endpoint = "https://html.duckduckgo.com/html/"
    private static let userAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"

    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 15
        session = URLSession(configuration: configuration)
    }

    public func results(for query: String) async throws -> [SearchResult] {
        var components = URLComponents(string: Self.endpoint)!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        if let region = Self.spanishRegionCode() {
            components.queryItems?.append(URLQueryItem(name: "kl", value: region))
        }

        var request = URLRequest(url: components.url!)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("es", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw SearchError.invalidResponse
        }
        return DuckDuckGoResultParser.parse(String(decoding: data, as: UTF8.self))
    }

    /// The provider's region code for Spanish-speaking locales, e.g. `co-es`.
    private static func spanishRegionCode() -> String? {
        let locale = Locale.current
        guard locale.language.languageCode == .spanish, let region = locale.region?.identifier else {
            return nil
        }
        return "\(region.lowercased())-es"
    }
}
