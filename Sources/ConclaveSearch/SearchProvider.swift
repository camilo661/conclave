import Foundation

/// One entry on the results page.
public struct SearchResult: Equatable, Sendable {
    public let title: String
    public let url: URL
    public let snippet: String

    public init(title: String, url: URL, snippet: String) {
        self.title = title
        self.url = url
        self.snippet = snippet
    }
}

public enum SearchError: Error, Equatable {
    case invalidResponse
}

/// A source of web results. Conclave renders the results itself, so the index
/// behind it can be replaced without touching the rest of the browser.
public protocol SearchProvider: Sendable {
    func results(for query: String) async throws -> [SearchResult]
}
