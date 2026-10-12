import Foundation

/// Typed access to the user-facing strings in `Resources/es.lproj/Localizable.strings`.
/// The interface is always Spanish, regardless of the system language.
public enum L10n {
    public enum Key: String, CaseIterable {
        // Tabs
        case tabNew = "tab.new"
        case tabClose = "tab.close"
        case tabUntitled = "tab.untitled"
        case tabNewPrivate = "tab.newPrivate"
        case tabPrivateUntitled = "tab.privateUntitled"

        // Private browsing
        case privateBadge = "private.badge"
        case privateTitle = "private.title"
        case privateDetail = "private.detail"
        case privateCaveat = "private.caveat"

        // Toolbar
        case toolbarBack = "toolbar.back"
        case toolbarForward = "toolbar.forward"
        case toolbarReload = "toolbar.reload"
        case toolbarStop = "toolbar.stop"
        case toolbarHistory = "toolbar.history"
        case toolbarShields = "toolbar.shields"
        case toolbarVoice = "toolbar.voice"
        case toolbarTheme = "toolbar.theme"
        case toolbarSettings = "toolbar.settings"
        case addressPlaceholder = "address.placeholder"
        case addressSecure = "address.secure"
        case addressInsecure = "address.insecure"

        // Start page
        case startTagline = "start.tagline"
        case startSearchPlaceholder = "start.searchPlaceholder"
        case startVoiceHint = "start.voiceHint"
        case startVoiceExamples = "start.voiceExamples"
        case startRecentSearches = "start.recentSearches"

        // History
        case historyTitle = "history.title"
        case historyFilterPlaceholder = "history.filterPlaceholder"
        case historyEmpty = "history.empty"
        case historyNoMatches = "history.noMatches"
        case historyToday = "history.today"
        case historyYesterday = "history.yesterday"
        case historySearchLabel = "history.searchLabel"
        case historyRemove = "history.remove"
        case historyClearAll = "history.clearAll"
        case historyPrivateNote = "history.privateNote"

        // Voice
        case voiceListening = "voice.listening"
        case voiceSpeakNow = "voice.speakNow"
        case voiceCancel = "voice.cancel"
        case voicePermissionDenied = "voice.permissionDenied"
        case voiceUnavailable = "voice.unavailable"
        case voiceNothingHeard = "voice.nothingHeard"

        case voiceUnderstanding = "voice.understanding"

        // Voice confirmations
        case doneThemeDark = "done.themeDark"
        case doneThemeLight = "done.themeLight"
        case doneThemeToggled = "done.themeToggled"
        case doneNewTab = "done.newTab"
        case donePrivateTab = "done.privateTab"
        case doneCloseTab = "done.closeTab"
        case doneBack = "done.back"
        case doneForward = "done.forward"
        case doneReload = "done.reload"
        case doneShieldsOn = "done.shieldsOn"
        case doneShieldsOff = "done.shieldsOff"
        case doneHTTPSOn = "done.httpsOn"
        case doneHTTPSOff = "done.httpsOff"
        case doneClearOnExitOn = "done.clearOnExitOn"
        case doneClearOnExitOff = "done.clearOnExitOff"
        case doneVoiceOnLaunchOn = "done.voiceOnLaunchOn"
        case doneVoiceOnLaunchOff = "done.voiceOnLaunchOff"
        case doneDataCleared = "done.dataCleared"
        case doneHistoryShown = "done.historyShown"
        case doneHistoryCleared = "done.historyCleared"

        // Shields
        case shieldsTitle = "shields.title"
        case shieldsOn = "shields.on"
        case shieldsOff = "shields.off"
        case shieldsBlockTrackers = "shields.blockTrackers"
        case shieldsBlockTrackersDetail = "shields.blockTrackersDetail"
        case shieldsHTTPSOnly = "shields.httpsOnly"
        case shieldsHTTPSOnlyDetail = "shields.httpsOnlyDetail"
        case shieldsClearOnExit = "shields.clearOnExit"
        case shieldsClearOnExitDetail = "shields.clearOnExitDetail"
        case shieldsClearNow = "shields.clearNow"
        case shieldsCleared = "shields.cleared"

        // Settings
        case settingsTitle = "settings.title"
        case settingsTheme = "settings.theme"
        case settingsThemeDark = "settings.themeDark"
        case settingsThemeLight = "settings.themeLight"
        case settingsVoiceOnLaunch = "settings.voiceOnLaunch"
        case settingsVoiceOnLaunchDetail = "settings.voiceOnLaunchDetail"

        // Search results page
        case searchButton = "search.button"
        case searchNoResults = "search.noResults"
        case searchFailed = "search.failed"

        // Page notices
        case noticeInsecureTitle = "notice.insecureTitle"
        case noticeInsecureMessage = "notice.insecureMessage"
        case noticeInsecureContinue = "notice.insecureContinue"
        case noticeGoBack = "notice.goBack"
        case noticeErrorTitle = "notice.errorTitle"
        case noticeRetry = "notice.retry"

        // Menu
        case menuNavigation = "menu.navigation"
        case menuFocusAddress = "menu.focusAddress"
        case menuVoiceSearch = "menu.voiceSearch"
        case menuShowHistory = "menu.showHistory"
    }

    public static func text(_ key: Key) -> String {
        bundle.localizedString(forKey: key.rawValue, value: nil, table: nil)
    }

    public static func text(_ key: Key, _ arguments: CVarArg...) -> String {
        String(format: text(key), arguments: arguments)
    }

    private static let bundle: Bundle = {
        guard let path = Bundle.main.path(forResource: "es", ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }()
}
