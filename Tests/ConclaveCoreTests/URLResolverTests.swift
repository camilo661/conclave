import Foundation
import Testing
@testable import ConclaveCore

@Suite struct URLResolverTests {
    @Test func keepsExplicitWebAddresses() {
        let url = URLResolver.resolve("https://example.com/path?q=1")
        #expect(url?.absoluteString == "https://example.com/path?q=1")
    }

    @Test func addsHTTPSToBareHosts() {
        #expect(URLResolver.resolve("example.com")?.absoluteString == "https://example.com")
        #expect(URLResolver.resolve("localhost:3000")?.absoluteString == "https://localhost:3000")
        #expect(URLResolver.resolve(" es.wikipedia.org/wiki/Gato ")?.absoluteString
            == "https://es.wikipedia.org/wiki/Gato")
    }

    @Test func plainTextGoesToConclavesOwnResultsPage() throws {
        let url = try #require(URLResolver.resolve("clima en Bogotá"))
        #expect(url.scheme == "conclave")
        #expect(InternalPage.searchQuery(from: url) == "clima en Bogotá")
    }

    @Test func neverLoadsDangerousSchemes() throws {
        for input in ["javascript:alert(1)", "file:///etc/passwd", "data:text/html,<script>1</script>"] {
            let url = try #require(URLResolver.resolve(input))
            #expect(InternalPage.searchQuery(from: url) == input, "\(input) must become a search")
        }
    }

    @Test func ignoresEmptyInput() {
        #expect(URLResolver.resolve("   ") == nil)
    }

    @Test func doesNotTreatSentencesWithDotsAsHosts() throws {
        for input in ["hola.", "3.5"] {
            let url = try #require(URLResolver.resolve(input))
            #expect(InternalPage.searchQuery(from: url) == input)
        }
    }
}

