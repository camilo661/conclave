import Foundation

/// The two monochrome appearances the browser supports.
public enum ThemeMode: String, CaseIterable, Identifiable, Sendable {
    case dark
    case light

    public var id: String { rawValue }

    public var toggled: ThemeMode {
        self == .dark ? .light : .dark
    }
}
