import ConclaveBrowser
import ConclaveCore
import ConclaveVoice
import SwiftUI

/// Menu-bar commands and their keyboard shortcuts.
public struct BrowserCommands: Commands {
    private let session: BrowserSession
    private let voice: VoiceSearchController

    public init(session: BrowserSession, voice: VoiceSearchController) {
        self.session = session
        self.voice = voice
    }

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(L10n.text(.tabNew)) { session.openNewTab() }
                .keyboardShortcut("t")
            Button(L10n.text(.tabNewPrivate)) { session.openNewPrivateTab() }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            Button(L10n.text(.tabClose)) { session.closeSelectedTab() }
                .keyboardShortcut("w")
        }

        CommandMenu(L10n.text(.menuNavigation)) {
            Button(L10n.text(.toolbarBack)) { session.goBack() }
                .keyboardShortcut("[")
            Button(L10n.text(.toolbarForward)) { session.goForward() }
                .keyboardShortcut("]")
            Button(L10n.text(.toolbarReload)) { session.reload() }
                .keyboardShortcut("r")
            Divider()
            Button(L10n.text(.menuFocusAddress)) { session.focusAddressBar() }
                .keyboardShortcut("l")
            Button(L10n.text(.menuShowHistory)) { session.showHistory() }
                .keyboardShortcut("y")
            Button(L10n.text(.menuVoiceSearch)) { voice.toggle() }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            Button(L10n.text(.toolbarTheme)) {
                session.settings.theme = session.settings.theme.toggled
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
        }
    }
}
