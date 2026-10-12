import ConclaveCore
import Foundation

/// One search or page visit.
public struct HistoryEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let url: URL
    public var title: String
    public var visitedAt: Date

    public init(id: UUID = UUID(), url: URL, title: String, visitedAt: Date) {
        self.id = id
        self.url = url
        self.title = title
        self.visitedAt = visitedAt
    }

    /// The query, when this entry is a search made in Conclave.
    public var searchQuery: String? {
        InternalPage.searchQuery(from: url)
    }

    /// What to show as the entry's name: the query, the page title, or the address.
    public var displayTitle: String {
        if let searchQuery { return searchQuery }
        return title.isEmpty ? url.absoluteString : title
    }
}
