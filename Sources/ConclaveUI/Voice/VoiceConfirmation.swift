import ConclaveCore
import ConclaveVoice

/// The sentence shown after the browser carries out a spoken request.
enum VoiceConfirmation {
    static func message(for command: VoiceCommand) -> L10n.Key {
        switch command {
        case .setDarkTheme(true): return .doneThemeDark
        case .setDarkTheme(false): return .doneThemeLight
        case .toggleTheme: return .doneThemeToggled
        case .newTab: return .doneNewTab
        case .newPrivateTab: return .donePrivateTab
        case .closeTab: return .doneCloseTab
        case .goBack: return .doneBack
        case .goForward: return .doneForward
        case .reload: return .doneReload
        case .setShields(true): return .doneShieldsOn
        case .setShields(false): return .doneShieldsOff
        case .setHTTPSOnly(true): return .doneHTTPSOn
        case .setHTTPSOnly(false): return .doneHTTPSOff
        case .setClearDataOnExit(true): return .doneClearOnExitOn
        case .setClearDataOnExit(false): return .doneClearOnExitOff
        case .setVoiceOnLaunch(true): return .doneVoiceOnLaunchOn
        case .setVoiceOnLaunch(false): return .doneVoiceOnLaunchOff
        case .clearBrowsingData: return .doneDataCleared
        case .showHistory: return .doneHistoryShown
        case .clearHistory: return .doneHistoryCleared
        // Navigation is its own confirmation: the page appears.
        case .open, .search: return .voiceListening
        }
    }
}
