import ConclaveBrowser
import ConclaveCore
import SwiftUI

/// The strip of open tabs at the top of the window.
struct TabBarView: View {
    @ObservedObject var session: BrowserSession

    @Environment(\.palette) private var palette

    /// Room for the window's close, minimise and zoom buttons.
    private static let trafficLightInset: CGFloat = 78

    var body: some View {
        HStack(spacing: 4) {
            ForEach(session.tabs) { tab in
                TabItemView(
                    tab: tab,
                    isSelected: tab.id == session.selectedTabID,
                    onSelect: { session.select(tab) },
                    onClose: { session.close(tab) }
                )
            }
            IconButton(systemName: "plus", label: .tabNew) {
                session.openNewTab()
            }
            IconButton(systemName: PrivateBrowsing.symbol, label: .tabNewPrivate) {
                session.openNewPrivateTab()
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, Self.trafficLightInset)
        .padding(.trailing, 8)
        .frame(height: 40)
        .background(palette.surface)
    }
}

private struct TabItemView: View {
    @ObservedObject var tab: BrowserTab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @Environment(\.palette) private var palette
    @ViewState private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            if tab.isPrivate {
                Image(systemName: PrivateBrowsing.symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(titleColor)
                    .accessibilityLabel(L10n.text(.privateBadge))
            }
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(titleColor)
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isSelected || isHovering ? 1 : 0)
            .help(L10n.text(.tabClose))
            .accessibilityLabel(L10n.text(.tabClose))
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .frame(minWidth: 70, maxWidth: 210)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected && !tab.isPrivate ? palette.border : .clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// A selected private tab is drawn inverted so it cannot be mistaken for a regular one.
    private var fill: Color {
        if isSelected { return tab.isPrivate ? palette.accent : palette.background }
        return isHovering ? palette.field : .clear
    }

    private var titleColor: Color {
        guard isSelected else { return palette.textSecondary }
        return tab.isPrivate ? palette.onAccent : palette.textPrimary
    }

    private var title: String {
        if tab.showsStartPage { return L10n.text(tab.isPrivate ? .tabPrivateUntitled : .tabUntitled) }
        if !tab.title.isEmpty { return tab.title }
        return tab.url?.host ?? L10n.text(.tabUntitled)
    }
}
