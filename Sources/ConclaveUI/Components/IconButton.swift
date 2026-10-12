import ConclaveCore
import SwiftUI

/// A square, monochrome toolbar button showing an SF Symbol.
struct IconButton: View {
    let systemName: String
    let label: L10n.Key
    var isActive = false
    var isEnabled = true
    let action: () -> Void

    @Environment(\.palette) private var palette
    @ViewState private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isActive ? palette.onAccent : palette.textPrimary)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8).fill(fill))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.3)
        .onHover { isHovering = $0 }
        .help(L10n.text(label))
        .accessibilityLabel(L10n.text(label))
    }

    private var fill: Color {
        if isActive { return palette.accent }
        return isHovering && isEnabled ? palette.field : .clear
    }
}
