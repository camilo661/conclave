import ConclaveCore
import SwiftUI

/// The colours of one monochrome theme.
public struct Palette {
    /// Page-level background.
    public let background: Color
    /// Tab bar, toolbar and panels.
    public let surface: Color
    /// Text fields and hovered controls.
    public let field: Color
    public let border: Color
    public let textPrimary: Color
    public let textSecondary: Color
    /// Selected and primary controls.
    public let accent: Color
    /// Content drawn on top of `accent`.
    public let onAccent: Color

    public static let dark = Palette(
        background: Color(hex: 0x000000),
        surface: Color(hex: 0x0D0D0D),
        field: Color(hex: 0x1E1E1E),
        border: Color(hex: 0x2E2E2E),
        textPrimary: Color(hex: 0xFFFFFF),
        textSecondary: Color(hex: 0x9A9A9A),
        accent: Color(hex: 0xFFFFFF),
        onAccent: Color(hex: 0x000000)
    )

    public static let light = Palette(
        background: Color(hex: 0xFFFFFF),
        surface: Color(hex: 0xF3F3F3),
        field: Color(hex: 0xE6E6E6),
        border: Color(hex: 0xD0D0D0),
        textPrimary: Color(hex: 0x000000),
        textSecondary: Color(hex: 0x5F5F5F),
        accent: Color(hex: 0x000000),
        onAccent: Color(hex: 0xFFFFFF)
    )
}

extension ThemeMode {
    public var palette: Palette {
        self == .dark ? .dark : .light
    }

    public var colorScheme: ColorScheme {
        self == .dark ? .dark : .light
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette.dark
}

extension EnvironmentValues {
    public var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
