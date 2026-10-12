import Combine
import WebKit

/// One browser tab: a web view plus the state the interface shows for it.
@MainActor
public final class BrowserTab: ObservableObject, Identifiable {
    /// Something shown in place of the page.
    public enum Notice: Equatable {
        /// The site could not be reached over HTTPS; holds the original HTTP address.
        case insecureConnection(URL)
        case loadFailed(message: String, url: URL?)
    }

    public nonisolated let id = UUID()
    public let webView: WKWebView
    /// Private tabs keep nothing on disk and share no cookies with regular tabs.
    public let isPrivate: Bool

    @Published public private(set) var title = ""
    @Published public private(set) var url: URL?
    @Published public private(set) var isLoading = false
    @Published public private(set) var estimatedProgress = 0.0
    @Published public private(set) var canGoBack = false
    @Published public private(set) var canGoForward = false
    @Published public private(set) var hasOnlySecureContent = false
    /// True until the tab is asked to load its first page.
    @Published public private(set) var showsStartPage = true
    @Published public internal(set) var notice: Notice?

    /// The HTTP address being retried over HTTPS, while that attempt is in flight.
    var httpsUpgradeOrigin: URL?

    private var observations: [NSKeyValueObservation] = []

    init(webView: WKWebView, isPrivate: Bool) {
        self.webView = webView
        self.isPrivate = isPrivate
        observe(\.title) { $0.title = $1 ?? "" }
        observe(\.url) { $0.url = $1 }
        observe(\.isLoading) { $0.isLoading = $1 }
        observe(\.estimatedProgress) { $0.estimatedProgress = $1 }
        observe(\.canGoBack) { $0.canGoBack = $1 }
        observe(\.canGoForward) { $0.canGoForward = $1 }
        observe(\.hasOnlySecureContent) { $0.hasOnlySecureContent = $1 }
    }

    public func load(_ url: URL) {
        showsStartPage = false
        notice = nil
        webView.load(URLRequest(url: url))
    }

    public func goBack() {
        notice = nil
        webView.goBack()
    }

    public func goForward() {
        notice = nil
        webView.goForward()
    }

    public func reload() {
        if case .loadFailed(_, let failedURL?) = notice {
            load(failedURL)
        } else {
            webView.reload()
        }
    }

    public func stopLoading() {
        webView.stopLoading()
    }

    private func observe<Value>(
        _ keyPath: KeyPath<WKWebView, Value> & Sendable,
        update: @escaping @MainActor (BrowserTab, Value) -> Void
    ) {
        let observation = webView.observe(keyPath, options: [.initial, .new]) { [weak self] webView, _ in
            // WebKit publishes these properties on the main thread.
            MainActor.assumeIsolated {
                guard let self else { return }
                update(self, webView[keyPath: keyPath])
            }
        }
        observations.append(observation)
    }
}
