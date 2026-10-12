import Combine
import Foundation

/// The user's searches and visited pages, newest first, kept in a file on this Mac.
@MainActor
public final class HistoryStore: ObservableObject {
    @Published public private(set) var entries: [HistoryEntry] = []

    /// Older entries are dropped beyond this many.
    private static let capacity = 5_000
    /// Reloading or revisiting the same address this soon updates the last entry instead of adding one.
    private static let repeatWindow: TimeInterval = 30 * 60

    private let fileURL: URL?
    private let writer = DispatchQueue(label: "com.conclave.browser.history", qos: .utility)

    /// - Parameter fileURL: Where the history is saved; `nil` keeps it in memory only.
    public init(fileURL: URL?) {
        self.fileURL = fileURL
        if let fileURL, let data = try? Data(contentsOf: fileURL),
           let saved = try? Self.decoder.decode([HistoryEntry].self, from: data) {
            entries = saved
        }
    }

    /// `Application Support/Conclave/history.json` inside the app's sandbox.
    public static var defaultFileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Conclave", isDirectory: true)
            .appendingPathComponent("history.json")
    }

    // MARK: - Recording

    public func record(url: URL, title: String, at date: Date = Date()) {
        if let latest = entries.first, latest.url == url,
           date.timeIntervalSince(latest.visitedAt) < Self.repeatWindow {
            entries[0].visitedAt = date
            if !title.isEmpty { entries[0].title = title }
        } else {
            entries.insert(HistoryEntry(url: url, title: title, visitedAt: date), at: 0)
            if entries.count > Self.capacity {
                entries.removeLast(entries.count - Self.capacity)
            }
        }
        save()
    }

    public func remove(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    public func removeAll() {
        entries.removeAll()
        save()
    }

    // MARK: - Reading

    /// Entries whose query, title or address contains `text`, ignoring case and accents.
    public func entries(matching text: String) -> [HistoryEntry] {
        let needle = Self.normalize(text)
        guard !needle.isEmpty else { return entries }
        return entries.filter {
            Self.normalize($0.displayTitle).contains(needle)
                || Self.normalize($0.url.absoluteString).contains(needle)
        }
    }

    /// The latest distinct searches, newest first.
    public func recentSearches(limit: Int) -> [String] {
        var seen: Set<String> = []
        var queries: [String] = []
        for entry in entries {
            guard let query = entry.searchQuery, seen.insert(Self.normalize(query)).inserted else { continue }
            queries.append(query)
            if queries.count == limit { break }
        }
        return queries
    }

    /// Blocks until every pending save has reached the disk.
    func waitForPendingSaves() {
        writer.sync {}
    }

    // MARK: - Private

    private func save() {
        guard let fileURL, let data = try? Self.encoder.encode(entries) else { return }
        writer.async {
            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
