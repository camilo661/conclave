import ConclaveVoice

extension BrowserSession {
    /// Carries out a command the user gave by voice.
    public func perform(_ command: VoiceCommand) {
        switch command {
        case .open(let address):
            navigate(to: address)
        case .search(let query):
            search(for: query)
        case .newTab:
            openNewTab()
        case .newPrivateTab:
            openNewPrivateTab()
        case .closeTab:
            closeSelectedTab()
        case .goBack:
            goBack()
        case .goForward:
            goForward()
        case .reload:
            reload()
        case .setDarkTheme(let isDark):
            settings.theme = isDark ? .dark : .light
        case .toggleTheme:
            settings.theme = settings.theme.toggled
        case .setShields(let isOn):
            settings.shieldsEnabled = isOn
        case .setHTTPSOnly(let isOn):
            settings.httpsOnly = isOn
        case .setClearDataOnExit(let isOn):
            settings.clearDataOnExit = isOn
        case .setVoiceOnLaunch(let isOn):
            settings.voiceOnLaunch = isOn
        case .clearBrowsingData:
            Task { await clearBrowsingData() }
        case .showHistory:
            showHistory()
        case .clearHistory:
            history.removeAll()
        }
    }
}
