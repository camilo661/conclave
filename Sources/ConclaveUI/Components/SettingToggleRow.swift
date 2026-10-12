import ConclaveCore
import SwiftUI

/// A titled on/off setting with a one-line explanation.
struct SettingToggleRow: View {
    let title: L10n.Key
    let detail: L10n.Key
    @Binding var isOn: Bool

    @Environment(\.palette) private var palette

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text(title))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.textPrimary)
                Text(L10n.text(detail))
                    .font(.system(size: 11))
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(MonochromeToggleStyle())
    }
}

/// A switch drawn only with the theme's black, white and greys.
struct MonochromeToggleStyle: ToggleStyle {
    @Environment(\.palette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 12) {
            configuration.label
            Spacer(minLength: 8)
            Capsule()
                .fill(configuration.isOn ? palette.accent : palette.field)
                .overlay(Capsule().strokeBorder(palette.border))
                .frame(width: 38, height: 22)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(configuration.isOn ? palette.onAccent : palette.textSecondary)
                        .padding(3)
                }
                .animation(.easeOut(duration: 0.15), value: configuration.isOn)
        }
        .contentShape(Rectangle())
        .onTapGesture { configuration.isOn.toggle() }
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(configuration.isOn ? "1" : "0")
    }
}
