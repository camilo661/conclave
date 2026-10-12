import ConclaveBrowser
import ConclaveCore
import SwiftUI

/// Privacy protections, in the style of Brave's Shields.
struct ShieldsPanel: View {
    @ObservedObject var session: BrowserSession
    @ObservedObject var settings: AppSettings

    @ViewState private var didClear = false

    var body: some View {
        let palette = settings.theme.palette

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: settings.shieldsEnabled ? "shield.lefthalf.filled" : "shield.slash")
                    .font(.system(size: 20, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text(.shieldsTitle))
                        .font(.system(size: 15, weight: .bold))
                    Text(L10n.text(settings.shieldsEnabled ? .shieldsOn : .shieldsOff))
                        .font(.system(size: 11))
                        .foregroundStyle(palette.textSecondary)
                }
            }
            .foregroundStyle(palette.textPrimary)

            palette.border.frame(height: 1)

            SettingToggleRow(
                title: .shieldsBlockTrackers,
                detail: .shieldsBlockTrackersDetail,
                isOn: $settings.shieldsEnabled
            )
            SettingToggleRow(
                title: .shieldsHTTPSOnly,
                detail: .shieldsHTTPSOnlyDetail,
                isOn: $settings.httpsOnly
            )
            SettingToggleRow(
                title: .shieldsClearOnExit,
                detail: .shieldsClearOnExitDetail,
                isOn: $settings.clearDataOnExit
            )

            Button {
                Task {
                    await session.clearBrowsingData()
                    didClear = true
                }
            } label: {
                Label(
                    L10n.text(didClear ? .shieldsCleared : .shieldsClearNow),
                    systemImage: didClear ? "checkmark" : "trash"
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(palette.accent))
            }
            .buttonStyle(.plain)
            .disabled(didClear)
        }
        .padding(18)
        .frame(width: 330)
        .background(palette.surface)
        .environment(\.palette, palette)
        .preferredColorScheme(settings.theme.colorScheme)
    }
}
