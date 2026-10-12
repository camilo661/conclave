import ConclaveBrowser
import ConclaveCore
import ConclaveVoice
import SwiftUI

/// Navigation buttons, address bar and the privacy, voice and theme controls.
struct ToolbarView: View {
    @ObservedObject var session: BrowserSession
    @ObservedObject var settings: AppSettings
    @ObservedObject var voice: VoiceSearchController
    @ObservedObject var tab: BrowserTab

    @Environment(\.palette) private var palette
    @ViewState private var showsHistory = false
    @ViewState private var showsShields = false
    @ViewState private var showsSettings = false

    var body: some View {
        HStack(spacing: 6) {
            IconButton(systemName: "chevron.left", label: .toolbarBack, isEnabled: tab.canGoBack) {
                tab.goBack()
            }
            IconButton(systemName: "chevron.right", label: .toolbarForward, isEnabled: tab.canGoForward) {
                tab.goForward()
            }
            if tab.isLoading {
                IconButton(systemName: "xmark", label: .toolbarStop) { tab.stopLoading() }
            } else {
                IconButton(
                    systemName: "arrow.clockwise",
                    label: .toolbarReload,
                    isEnabled: !tab.showsStartPage
                ) { tab.reload() }
            }

            AddressBarView(tab: tab, focusRequests: session.addressFocusRequests) {
                session.navigate(to: $0)
            }
            .id(tab.id)

            if tab.isPrivate {
                Label(L10n.text(.privateBadge), systemImage: PrivateBrowsing.symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(palette.onAccent)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(Capsule().fill(palette.accent))
                    .help(L10n.text(.privateDetail))
            }

            IconButton(systemName: "clock.arrow.circlepath", label: .toolbarHistory) {
                showsHistory.toggle()
            }
            .popover(isPresented: $showsHistory, arrowEdge: .bottom) {
                HistoryPanel(history: session.history, settings: settings) { entry in
                    showsHistory = false
                    session.open(entry)
                }
            }
            .onChange(of: session.historyRequests) {
                showsHistory = true
            }

            IconButton(
                systemName: settings.shieldsEnabled ? "shield.lefthalf.filled" : "shield.slash",
                label: .toolbarShields
            ) { showsShields.toggle() }
                .popover(isPresented: $showsShields, arrowEdge: .bottom) {
                    ShieldsPanel(session: session, settings: settings)
                }

            IconButton(systemName: "mic.fill", label: .toolbarVoice, isActive: voice.isBusy) {
                voice.toggle()
            }

            IconButton(
                systemName: settings.theme == .dark ? "sun.max.fill" : "moon.fill",
                label: .toolbarTheme
            ) { settings.theme = settings.theme.toggled }

            IconButton(systemName: "gearshape.fill", label: .toolbarSettings) {
                showsSettings.toggle()
            }
            .popover(isPresented: $showsSettings, arrowEdge: .bottom) {
                SettingsPanel(settings: settings)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(palette.surface)
        .overlay(alignment: .bottom) { progressLine }
    }

    /// A hairline under the toolbar that doubles as the loading indicator.
    private var progressLine: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                palette.border.frame(height: 1)
                if tab.isLoading {
                    palette.accent
                        .frame(width: geometry.size.width * tab.estimatedProgress, height: 2)
                        .animation(.easeOut(duration: 0.2), value: tab.estimatedProgress)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 2)
        .allowsHitTesting(false)
    }
}
