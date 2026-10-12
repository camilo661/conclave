import Foundation
import Testing
@testable import ConclaveSearch

@Suite struct DuckDuckGoResultParserTests {
    private let markup = """
    <div class="result results_links web-result ">
      <h2 class="result__title">
        <a rel="nofollow" class="result__a" href="https://example.com/clima?a=1&amp;b=2">Clima en <b>Bogot&aacute;</b> &amp; m&#225;s</a>
      </h2>
      <a class="result__snippet" href="https://example.com/clima">Previsión del <b>clima</b>
         hoy &#x2014; detalle por horas.</a>
    </div>
    <div class="result results_links web-result ">
      <a rel="nofollow" class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fes.wikipedia.org%2Fwiki%2FBogot%25C3%25A1&amp;rut=abc">Bogotá - Wikipedia</a>
    </div>
    <div class="result result--ad">
      <a rel="nofollow" class="result__a" href="https://duckduckgo.com/y.js?ad_provider=x">Anuncio</a>
      <a class="result__snippet" href="#">Compra ya</a>
    </div>
    <div class="result">
      <a rel="nofollow" class="result__a" href="javascript:alert(1)">Malicioso</a>
    </div>
    """

    @Test func extractsTitleLinkAndSnippet() throws {
        let first = try #require(DuckDuckGoResultParser.parse(markup).first)
        #expect(first.title == "Clima en Bogotá & más")
        #expect(first.url.absoluteString == "https://example.com/clima?a=1&b=2")
        #expect(first.snippet == "Previsión del clima hoy — detalle por horas.")
    }

    @Test func resolvesRedirectLinksAndLeavesMissingSnippetsEmpty() throws {
        let results = DuckDuckGoResultParser.parse(markup)
        try #require(results.count == 2)
        #expect(results[1].url.absoluteString == "https://es.wikipedia.org/wiki/Bogot%C3%A1")
        #expect(results[1].snippet == "")
    }

    @Test func dropsSponsoredAndNonWebLinks() {
        let titles = DuckDuckGoResultParser.parse(markup).map(\.title)
        #expect(!titles.contains("Anuncio"))
        #expect(!titles.contains("Malicioso"))
    }

    @Test func unrelatedMarkupYieldsNothing() {
        #expect(DuckDuckGoResultParser.parse("<html><body>captcha</body></html>").isEmpty)
    }
}

@Suite struct SearchPageRendererTests {
    @Test func escapesEverythingThatComesFromOutside() {
        let hostile = SearchResult(
            title: "<script>alert(1)</script>",
            url: URL(string: "https://example.com/?x=%22%3E%3Cscript%3E")!,
            snippet: "\"><img src=x onerror=alert(1)>"
        )
        let page = SearchPageRenderer.page(query: "</title><script>x</script>", content: .results([hostile]))

        #expect(!page.contains("<script"))
        #expect(!page.contains("<img"))
        #expect(page.contains("&lt;script&gt;alert(1)&lt;/script&gt;"))
    }

    @Test func forbidsScriptsAndRemoteContent() {
        let page = SearchPageRenderer.page(query: "a", content: .results([]))
        #expect(page.contains("default-src 'none'"))
    }

    @Test func linksPointStraightAtTheDestination() {
        let result = SearchResult(title: "Ejemplo", url: URL(string: "https://example.com/a")!, snippet: "")
        let page = SearchPageRenderer.page(query: "a", content: .results([result]))
        #expect(page.contains("<a href=\"https://example.com/a\""))
    }
}
