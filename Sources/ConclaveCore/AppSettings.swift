import Combine
import Foundation

/// User preferences, persisted in `UserDefaults`.
@MainActor
public final class AppSettings: ObservableObject {
    @Published public var theme: ThemeMode {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }

    /// Blocks known trackers and ads, third-party cookies and tracking URL parameters.
    @Published public var shieldsEnabled: Bool {
        didSet { defaults.set(shieldsEnabled, forKey: Key.shieldsEnabled) }
    }

    /// Upgrades every connection to HTTPS and warns before falling back to HTTP.
    @Published public var httpsOnly: Bool {
        didSet { defaults.set(httpsOnly, forKey: Key.httpsOnly) }
    }

    /// Wipes cookies, cache and site storage when the app quits.
    @Published public var clearDataOnExit: Bool {
        didSet { defaults.set(clearDataOnExit, forKey: Key.clearDataOnExit) }
    }

    /// Starts listening for a spoken search as soon as the browser opens.
    @Published public var voiceOnLaunch: Bool {
        didSet { defaults.set(voiceOnLaunch, forKey: Key.voiceOnLaunch) }
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.shieldsEnabled: true,
            Key.httpsOnly: true,
            Key.clearDataOnExit: false,
            Key.voiceOnLaunch: true,
        ])
        theme = defaults.string(forKey: Key.theme).flatMap(ThemeMode.init) ?? .dark
        shieldsEnabled = defaults.bool(forKey: Key.shieldsEnabled)
        httpsOnly = defaults.bool(forKey: Key.httpsOnly)
        clearDataOnExit = defaults.bool(forKey: Key.clearDataOnExit)
        voiceOnLaunch = defaults.bool(forKey: Key.voiceOnLaunch)
    }

    private enum Key {
        static let theme = "settings.theme"
        static let shieldsEnabled = "settings.shieldsEnabled"
        static let httpsOnly = "settings.httpsOnly"
        static let clearDataOnExit = "settings.clearDataOnExit"
        static let voiceOnLaunch = "settings.voiceOnLaunch"
    }
}
