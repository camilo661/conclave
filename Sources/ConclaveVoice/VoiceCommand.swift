import Foundation

/// What the user asked the browser to do by voice.
public enum VoiceCommand: Equatable, Sendable {
    // Navigation
    /// Go to a web address, e.g. `wikipedia.org`.
    case open(String)
    /// Search the web for a phrase.
    case search(String)
    case goBack
    case goForward
    case reload

    // Tabs
    case newTab
    case newPrivateTab
    case closeTab

    // Settings
    case setDarkTheme(Bool)
    case toggleTheme
    case setShields(Bool)
    case setHTTPSOnly(Bool)
    case setClearDataOnExit(Bool)
    case setVoiceOnLaunch(Bool)
    case clearBrowsingData

    // History
    case showHistory
    case clearHistory

    /// True for commands that take the user to a page, as opposed to changing
    /// the browser itself.
    public var isNavigation: Bool {
        switch self {
        case .open, .search: return true
        default: return false
        }
    }
}
