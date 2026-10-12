import ConclaveCore
import SwiftUI

/// General preferences: theme and voice search on launch.
struct SettingsPanel: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        let palette = settings.theme.palette

        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text(.settingsTitle))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.textPrimary)

            palette.border.frame(height: 1)

            section(.settingsTheme, palette: palette) {
                ChoiceChip(title: L10n.text(.settingsThemeDark), isSelected: settings.theme == .dark) {
                    settings.theme = .dark
                }
                ChoiceChip(title: L10n.text(.settingsThemeLight), isSelected: settings.theme == .light) {
                    settings.theme = .light
                }
            }

            SettingToggleRow(
                title: .settingsVoiceOnLaunch,
                detail: .settingsVoiceOnLaunchDetail,
                isOn: $settings.voiceOnLaunch
            )
        }
        .padding(18)
        .frame(width: 330)
        .background(palette.surface)
        .environment(\.palette, palette)
        .preferredColorScheme(settings.theme.colorScheme)
    }

    private func section(
        _ title: L10n.Key,
        palette: Palette,
        @ViewBuilder choices: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text(title))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.textPrimary)
            HStack(spacing: 6) { choices() }
        }
    }
}

/// One option in a single-choice row.
private struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? palette.onAccent : palette.textPrimary)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(Capsule().fill(isSelected ? palette.accent : palette.field))
                .overlay(Capsule().strokeBorder(isSelected ? .clear : palette.border))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
