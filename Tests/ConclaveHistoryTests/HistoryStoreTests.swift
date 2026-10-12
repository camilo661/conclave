import ConclaveCore
import Foundation
import Testing
@testable import ConclaveHistory

@MainActor
@Suite struct HistoryStoreTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private let page = URL(string: "https://example.com/a")!

    @Test func keepsNewestFirst() {
        let store = HistoryStore(fileURL: nil)
        store.record(url: page, title: "A", at: start)
        store.record(url: InternalPage.searchURL(for: "clima en Bogotá"), title: "", at: start.addingTimeInterval(60))

        #expect(store.entries.map(\.displayTitle) == ["clima en Bogotá", "A"])
        #expect(store.entries[0].searchQuery == "clima en Bogotá")
        #expect(store.entries[1].searchQuery == nil)
    }

    @Test func reloadingAPageDoesNotDuplicateIt() {
        let store = HistoryStore(fileURL: nil)
        store.record(url: page, title: "", at: start)
        store.record(url: page, title: "Título", at: start.addingTimeInterval(120))
        #expect(store.entries.count == 1)
        #expect(store.entries[0].title == "Título")

        store.record(url: page, title: "Título", at: start.addingTimeInterval(3 * 3600))
        #expect(store.entries.count == 2)
    }

    @Test func findsEntriesIgnoringCaseAndAccents() {
        let store = HistoryStore(fileURL: nil)
        store.record(url: page, title: "Recetas de Arepas", at: start)
        store.record(url: InternalPage.searchURL(for: "clima en Bogotá"), title: "", at: start.addingTimeInterval(60))

        #expect(store.entries(matching: "bogota").count == 1)
        #expect(store.entries(matching: "AREPAS").count == 1)
        #expect(store.entries(matching: "example.com").count == 1)
        #expect(store.entries(matching: "  ").count == 2)
        #expect(store.entries(matching: "nada").isEmpty)
    }

    @Test func listsRecentDistinctSearches() {
        let store = HistoryStore(fileURL: nil)
        for (offset, query) in ["uno", "dos", "Uno", "tres"].enumerated() {
            store.record(url: InternalPage.searchURL(for: query), title: "", at: start.addingTimeInterval(Double(offset) * 3600))
        }
        store.record(url: page, title: "A", at: start.addingTimeInterval(5 * 3600))

        #expect(store.recentSearches(limit: 5) == ["tres", "Uno", "dos"])
        #expect(store.recentSearches(limit: 1) == ["tres"])
    }

    @Test func removesOneOrAll() {
        let store = HistoryStore(fileURL: nil)
        store.record(url: page, title: "A", at: start)
        store.record(url: URL(string: "https://example.com/b")!, title: "B", at: start.addingTimeInterval(60))

        store.remove(store.entries[0])
        #expect(store.entries.map(\.title) == ["A"])
        store.removeAll()
        #expect(store.entries.isEmpty)
    }

    @Test func survivesARestart() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("conclave-tests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("history.json")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }

        let first = HistoryStore(fileURL: file)
        first.record(url: page, title: "A", at: start)
        first.waitForPendingSaves()
        #expect(HistoryStore(fileURL: file).entries == first.entries)

        first.removeAll()
        first.waitForPendingSaves()
        #expect(HistoryStore(fileURL: file).entries.isEmpty)
    }
}
