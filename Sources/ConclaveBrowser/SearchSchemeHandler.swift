import ConclaveCore
import ConclaveSearch
import WebKit

/// Serves Conclave's own results page for `conclave://search?q=…`.
///
/// Because the page is a real navigation inside the web view, history, reload
/// and the address bar work for searches exactly as they do for websites.
@MainActor
final class SearchSchemeHandler: NSObject, WKURLSchemeHandler {
    private let provider: SearchProvider
    private var running: [ObjectIdentifier: Task<Void, Never>] = [:]

    init(provider: SearchProvider) {
        self.provider = provider
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url, let query = InternalPage.searchQuery(from: url) else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        let id = ObjectIdentifier(urlSchemeTask)
        running[id] = Task { [provider] in
            let content: SearchPageRenderer.Content
            do {
                content = .results(try await provider.results(for: query))
            } catch {
                content = .failure
            }
            // WebKit forbids touching a task after it has been stopped.
            guard running.removeValue(forKey: id) != nil else { return }
            Self.respond(to: urlSchemeTask, url: url, html: SearchPageRenderer.page(query: query, content: content))
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        running.removeValue(forKey: ObjectIdentifier(urlSchemeTask))?.cancel()
    }

    private static func respond(to task: WKURLSchemeTask, url: URL, html: String) {
        let data = Data(html.utf8)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": "text/html; charset=utf-8",
                "Content-Length": String(data.count),
                "Content-Security-Policy": SearchPageRenderer.contentSecurityPolicy,
                "Cache-Control": "no-store",
            ]
        )!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }
}
