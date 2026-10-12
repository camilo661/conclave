import ConclaveCore
import ConclavePrivacy
import WebKit

/// Applies the browser's security policy to every navigation and reports
/// load failures back to the owning tab.
@MainActor
final class NavigationHandler: NSObject, WKNavigationDelegate, WKUIDelegate {
    private weak var session: BrowserSession?

    init(session: BrowserSession) {
        self.session = session
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let session, let tab = session.tab(for: webView),
              let url = navigationAction.request.url
        else { return .cancel }

        // A nil target frame is a request for a new window, which becomes a new tab.
        let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
        guard Self.isLoadable(url, inMainFrame: isMainFrame) else { return .cancel }
        guard navigationAction.targetFrame?.isMainFrame == true else { return .allow }

        if session.settings.httpsOnly, let secureURL = session.httpsUpgrader.upgradedURL(for: url) {
            tab.load(secureURL)
            tab.httpsUpgradeOrigin = url
            return .cancel
        }

        let method = navigationAction.request.httpMethod ?? "GET"
        if session.settings.shieldsEnabled, method == "GET" {
            let cleanURL = TrackingParameterStripper.strip(url)
            if cleanURL != url {
                tab.load(cleanURL)
                return .cancel
            }
        }
        return .allow
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        // Files the browser cannot display are not downloaded.
        navigationResponse.canShowMIMEType ? .allow : .cancel
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let tab = session?.tab(for: webView) else { return }
        tab.httpsUpgradeOrigin = nil
        tab.notice = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Private tabs leave no trace in the history.
        guard let session, let tab = session.tab(for: webView), !tab.isPrivate,
              let url = webView.url, Self.belongsInHistory(url)
        else { return }
        session.history.record(url: url, title: webView.title ?? "")
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        handleFailure(error, in: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleFailure(error, in: webView)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    // MARK: - WKUIDelegate

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url, Self.isLoadable(url, inMainFrame: true) {
            let isPrivate = session?.tab(for: webView)?.isPrivate ?? false
            session?.openNewTab(loading: url, isPrivate: isPrivate)
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        // Never grant camera or microphone silently; the user decides per site.
        .prompt
    }

    // MARK: - Private

    private func handleFailure(_ error: Error, in webView: WKWebView) {
        let error = error as NSError
        guard !Self.isBenign(error), let tab = session?.tab(for: webView) else { return }
        let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL

        if let origin = tab.httpsUpgradeOrigin,
           failingURL?.scheme == "https", failingURL?.host == origin.host {
            tab.httpsUpgradeOrigin = nil
            tab.notice = .insecureConnection(origin)
        } else {
            tab.notice = .loadFailed(message: error.localizedDescription, url: failingURL)
        }
    }

    private static func isLoadable(_ url: URL, inMainFrame: Bool) -> Bool {
        if InternalPage.searchQuery(from: url) != nil { return inMainFrame }
        guard let scheme = url.scheme?.lowercased() else { return false }
        let allowed: Set<String> = inMainFrame
            ? ["http", "https", "about", "blob"]
            : ["http", "https", "about", "blob", "data"]
        return allowed.contains(scheme)
    }

    private static func belongsInHistory(_ url: URL) -> Bool {
        if InternalPage.searchQuery(from: url) != nil { return true }
        let scheme = url.scheme?.lowercased()
        return scheme == "http" || scheme == "https"
    }

    /// Failures caused by the browser itself replacing or stopping a load.
    private static func isBenign(_ error: NSError) -> Bool {
        let frameLoadInterruptedByPolicyChange = 102
        return (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled)
            || (error.domain == "WebKitErrorDomain" && error.code == frameLoadInterruptedByPolicyChange)
    }
}
