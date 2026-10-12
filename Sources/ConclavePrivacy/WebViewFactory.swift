import WebKit

/// Creates web views with the browser's hardened defaults.
@MainActor
public struct WebViewFactory {
    public init() {}

    /// - Parameters:
    ///   - schemeHandlers: Handlers for the browser's own URL schemes, keyed by scheme.
    ///   - dataStore: Where sites keep cookies and storage; `nil` uses the regular persistent store.
    public func makeWebView(
        schemeHandlers: [String: WKURLSchemeHandler] = [:],
        dataStore: WKWebsiteDataStore? = nil
    ) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        for (scheme, handler) in schemeHandlers {
            configuration.setURLSchemeHandler(handler, forURLScheme: scheme)
        }
        configuration.websiteDataStore = dataStore ?? .default()
        configuration.upgradeKnownHostsToHTTPS = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.applicationNameForUserAgent = "Version/18.0 Safari/605.1.15"
        configuration.preferences.isFraudulentWebsiteWarningEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.userContentController.addUserScript(Self.globalPrivacyControlScript)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = false
        return webView
    }

    /// Signals the Global Privacy Control opt-out to every page.
    private static let globalPrivacyControlScript = WKUserScript(
        source: """
        Object.defineProperty(Navigator.prototype, 'globalPrivacyControl', {
            get: function () { return true; },
            configurable: true
        });
        """,
        injectionTime: .atDocumentStart,
        forMainFrameOnly: false
    )
}
