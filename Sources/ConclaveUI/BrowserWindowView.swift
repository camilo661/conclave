import ConclaveBrowser
import ConclaveCore
import ConclaveHistory
import ConclaveVoice
import SwiftUI

/// The whole browser window: tab bar, toolbar, page and voice overlay.
public struct BrowserWindowView: View {
    @ObservedObject private var session: BrowserSession
    @ObservedObject private var settings: AppSettings
    @ObservedObject private var voice: VoiceSearchController

    @ViewState private var didLaunch = false

    public init(session: BrowserSession, voice: VoiceSearchController) {
        self.session = session
        self.settings = session.settings
        self.voice = voice
    }

    public var body: some View {
        let palette = settings.theme.palette

        VStack(spacing: 0) {
            TabBarView(session: session)
            if let tab = session.selectedTab {
                ToolbarView(session: session, settings: settings, voice: voice, tab: tab)
                TabContentView(tab: tab, history: session.history, session: session, voice: voice)
            } else {
                palette.background
            }
        }
        .overlay(alignment: .bottom) {
            VoiceOverlayView(voice: voice)
        }
        .background(palette.background)
        .ignoresSafeArea(edges: .top)
        .frame(minWidth: 860, minHeight: 580)
        .environment(\.palette, palette)
        .preferredColorScheme(settings.theme.colorScheme)
        .task {
            guard !didLaunch else { return }
            didLaunch = true
            await session.start()
            // The browser's signature behaviour: it is ready to hear a search on launch.
            if settings.voiceOnLaunch {
                voice.start()
            }
        }
    }
}

/// The area below the toolbar for one tab.
private struct TabContentView: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject var history: HistoryStore
    let session: BrowserSession
    let voice: VoiceSearchController

    var body: some View {
        if tab.showsStartPage {
            StartPageView(
                voice: voice,
                isPrivate: tab.isPrivate,
                recentSearches: tab.isPrivate ? [] : history.recentSearches(limit: 5),
                onSubmit: { session.navigate(to: $0) },
                onSearch: { session.search(for: $0) }
            )
        } else if let notice = tab.notice {
            PageNoticeView(
                notice: notice,
                canGoBack: tab.canGoBack,
                onContinueInsecurely: { session.continueInsecurely(in: tab) },
                onRetry: tab.reload,
                onGoBack: tab.goBack
            )
        } else {
            WebContentView(webView: tab.webView)
        }
    }
}
