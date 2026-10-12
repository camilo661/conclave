import ConclaveCore
import Foundation

/// Builds the HTML of Conclave's results page.
///
/// Every piece of text that comes from the network is escaped, and the page
/// forbids scripts and remote resources, so a result can never run code here.
public enum SearchPageRenderer {
    public enum Content {
        case results([SearchResult])
        case failure
    }

    public static let contentSecurityPolicy = "default-src 'none'; style-src 'unsafe-inline'"

    public static func page(query: String, content: Content) -> String {
        let safeQuery = HTMLText.escape(query)
        return """
        <!doctype html>
        <html lang="es">
        <head>
        <meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="\(contentSecurityPolicy)">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <title>\(safeQuery) — Conclave</title>
        <style>\(styleSheet)</style>
        </head>
        <body>
        <header>
          <span class="brand">CONCLAVE</span>
          <form action="\(InternalPage.searchEndpoint)" method="get">
            <input type="search" name="q" value="\(safeQuery)" autocomplete="off" spellcheck="false"
                   aria-label="\(HTMLText.escape(L10n.text(.searchButton)))">
            <button type="submit">\(HTMLText.escape(L10n.text(.searchButton)))</button>
          </form>
        </header>
        <main>
        \(body(query: query, content: content))
        </main>
        </body>
        </html>
        """
    }

    private static func body(query: String, content: Content) -> String {
        switch content {
        case .failure:
            return message(L10n.text(.searchFailed))
        case .results(let results) where results.isEmpty:
            return message(L10n.text(.searchNoResults, query))
        case .results(let results):
            return "<ol>\n" + results.map(item).joined(separator: "\n") + "\n</ol>"
        }
    }

    private static func item(_ result: SearchResult) -> String {
        let link = HTMLText.escape(result.url.absoluteString)
        let snippet = result.snippet.isEmpty ? "" : "<p>\(HTMLText.escape(result.snippet))</p>"
        return """
        <li>
          <span class="site">\(HTMLText.escape(displayAddress(of: result.url)))</span>
          <a href="\(link)" rel="noreferrer noopener">\(HTMLText.escape(result.title))</a>
          \(snippet)
        </li>
        """
    }

    private static func message(_ text: String) -> String {
        "<p class=\"message\">\(HTMLText.escape(text))</p>"
    }

    /// `es.wikipedia.org › wiki › Gato`
    private static func displayAddress(of url: URL) -> String {
        let host = url.host ?? ""
        let path = url.pathComponents.filter { $0 != "/" }.prefix(3)
        return ([host] + path).joined(separator: " › ")
    }

    private static let styleSheet = """
    :root { --bg: #ffffff; --text: #000000; --muted: #5f5f5f; --field: #f0f0f0; --border: #d0d0d0; }
    @media (prefers-color-scheme: dark) {
      :root { --bg: #000000; --text: #ffffff; --muted: #9a9a9a; --field: #1e1e1e; --border: #2e2e2e; }
    }
    * { box-sizing: border-box; }
    body { margin: 0; background: var(--bg); color: var(--text);
           font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif; }
    header { display: flex; align-items: center; gap: 24px; padding: 20px 32px;
             border-bottom: 1px solid var(--border); }
    .brand { font-weight: 800; letter-spacing: 6px; font-size: 16px; }
    form { display: flex; flex: 1; max-width: 640px; gap: 8px; }
    input { flex: 1; min-width: 0; height: 40px; padding: 0 18px; border-radius: 20px;
            border: 1px solid var(--border); background: var(--field); color: var(--text);
            font: inherit; outline: none; }
    input:focus { border-color: var(--text); }
    button { height: 40px; padding: 0 20px; border-radius: 20px; border: none; cursor: pointer;
             background: var(--text); color: var(--bg); font: inherit; font-weight: 600; }
    main { max-width: 760px; padding: 12px 32px 64px; }
    ol { list-style: none; margin: 0; padding: 0; }
    li { padding: 18px 0; border-bottom: 1px solid var(--border); }
    li:last-child { border-bottom: none; }
    .site { display: block; font-size: 12px; color: var(--muted); overflow-wrap: anywhere; }
    a { display: inline-block; margin: 2px 0; font-size: 19px; font-weight: 600;
        color: var(--text); text-decoration: none; }
    a:hover, a:focus { text-decoration: underline; }
    li p { margin: 2px 0 0; color: var(--muted); }
    .message { margin-top: 48px; font-size: 16px; color: var(--muted); }
    """
}
