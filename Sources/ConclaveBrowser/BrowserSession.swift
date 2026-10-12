import Combine
import ConclaveCore
import ConclaveHistory
import ConclavePrivacy
import ConclaveSearch
import WebKit

/// The open tabs and every action the user can take on them.
@MainActor
public final class BrowserSession: ObservableObject {
    @Published public private(set) var tabs: [BrowserTab] = []
    @Published public private(set) var selectedTabID: BrowserTab.ID?
    /// Becomes true once protections are compiled and the first tab exists.
    @Published public private(set) var isReady = false
    /// Incremented each time the address bar should take keyboard focus.
    @Published public private(set) var addressFocusRequests = 0
    /// Incremented each time the history panel should open.
    @Published public private(set) var historyRequests = 0

    public let settings: AppSettings
    public let history: HistoryStore

    var httpsUpgrader = HTTPSUpgrader()

    /// In-memory storage shared by the open private tabs. It is discarded,
    /// with everything sites stored in it, when the last private tab closes.
    private var privateDataStore: WKWebsiteDataStore?

    private let webViewFactory = WebViewFactory()
    private let searchPages = SearchSchemeHandler(provider: DuckDuckGoIndexProvider())
    private let contentBlocker = ContentBlocker()
    private lazy var navigationHandler = NavigationHandler(session: self)
    private var cancellables: Set<AnyCancellable> = []

    public init(settings: AppSettings, history: HistoryStore) {
        self.settings = settings
        self.history = history
        settings.$shieldsEnabled
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] enabled in self?.applyShields(enabled: enabled) }
            .store(in: &cancellables)
    }

    /// Prepares tracker blocking and opens the first tab.
    public func start() async {
        guard !isReady else { return }
        await contentBlocker.prepare()
        openNewTab()
        isReady = true
    }

    // MARK: - Tabs

    public var selectedTab: BrowserTab? {
        tabs.first { $0.id == selectedTabID }
    }

    @discardableResult
    public func openNewTab(loading url: URL? = nil, isPrivate: Bool = false) -> BrowserTab {
        let webView = webViewFactory.makeWebView(
            schemeHandlers: [InternalPage.scheme: searchPages],
            dataStore: isPrivate ? sharedPrivateDataStore() : nil
        )
        webView.navigationDelegate = navigationHandler
        webView.uiDelegate = navigationHandler
        contentBlocker.install(
            on: webView.configuration.userContentController,
            enabled: settings.shieldsEnabled
        )

        let tab = BrowserTab(webView: webView, isPrivate: isPrivate)
        tabs.append(tab)
        selectedTabID = tab.id
        if let url { tab.load(url) }
        return tab
    }

    @discardableResult
    public func openNewPrivateTab() -> BrowserTab {
        openNewTab(isPrivate: true)
    }

    public func select(_ tab: BrowserTab) {
        selectedTabID = tab.id
    }

    public func close(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        tab.stopLoading()
        tabs.remove(at: index)
        if !tabs.contains(where: \.isPrivate) {
            privateDataStore = nil
        }

        if tabs.isEmpty {
            openNewTab()
        } else if selectedTabID == tab.id {
            selectedTabID = tabs[min(index, tabs.count - 1)].id
        }
    }

    public func closeSelectedTab() {
        if let selectedTab { close(selectedTab) }
    }

    func tab(for webView: WKWebView) -> BrowserTab? {
        tabs.first { $0.webView === webView }
    }

    // MARK: - Navigation

    /// Loads an address, or shows Conclave's results page if the text is not one.
    public func navigate(to input: String) {
        guard let url = URLResolver.resolve(input) else { return }
        (selectedTab ?? openNewTab()).load(url)
    }

    public func search(for query: String) {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        (selectedTab ?? openNewTab()).load(InternalPage.searchURL(for: text))
    }

    public func goBack() { selectedTab?.goBack() }
    public func goForward() { selectedTab?.goForward() }
    public func reload() { selectedTab?.reload() }

    public func focusAddressBar() {
        addressFocusRequests += 1
    }

    // MARK: - History

    public func showHistory() {
        historyRequests += 1
    }

    /// Reopens a past search or page in the current tab.
    public func open(_ entry: HistoryEntry) {
        (selectedTab ?? openNewTab()).load(entry.url)
    }

    // MARK: - Privacy

    /// Loads the page over plain HTTP after the user accepted the warning.
    public func continueInsecurely(in tab: BrowserTab) {
        guard case .insecureConnection(let url) = tab.notice, let host = url.host else { return }
        httpsUpgrader.allowInsecure(host: host)
        tab.load(url)
    }

    /// Erases site data and the history.
    public func clearBrowsingData() async {
        history.removeAll()
        await WebsiteDataCleaner.clearAll()
    }

    private func sharedPrivateDataStore() -> WKWebsiteDataStore {
        if let privateDataStore { return privateDataStore }
        let store = WKWebsiteDataStore.nonPersistent()
        privateDataStore = store
        return store
    }

    private func applyShields(enabled: Bool) {
        for tab in tabs {
            contentBlocker.install(on: tab.webView.configuration.userContentController, enabled: enabled)
        }
    }
}
