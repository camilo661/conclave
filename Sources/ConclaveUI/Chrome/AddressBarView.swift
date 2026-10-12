import ConclaveBrowser
import ConclaveCore
import SwiftUI

/// The combined address and search field for one tab.
struct AddressBarView: View {
    @ObservedObject var tab: BrowserTab
    /// Changes whenever the field should take keyboard focus.
    let focusRequests: Int
    let onSubmit: (String) -> Void

    @Environment(\.palette) private var palette
    @ViewState private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: security.symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
                .help(security.help.map(L10n.text) ?? "")

            TextField(L10n.text(.addressPlaceholder), text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(palette.textPrimary)
                .focused($isFocused)
                .onSubmit {
                    onSubmit(text)
                    isFocused = false
                }
        }
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(Capsule().fill(palette.field))
        .overlay(Capsule().strokeBorder(isFocused ? palette.accent : .clear, lineWidth: 1.5))
        .onAppear(perform: showCurrentAddress)
        .onChange(of: tab.url) {
            if !isFocused { showCurrentAddress() }
        }
        .onChange(of: isFocused) {
            if !isFocused { showCurrentAddress() }
        }
        .onChange(of: focusRequests) {
            isFocused = true
        }
    }

    private func showCurrentAddress() {
        if tab.showsStartPage {
            text = ""
        } else if let url = tab.url {
            text = InternalPage.searchQuery(from: url) ?? url.absoluteString
        } else {
            text = ""
        }
    }

    private var security: (symbol: String, help: L10n.Key?) {
        guard !tab.showsStartPage, let url = tab.url, let scheme = url.scheme,
              InternalPage.searchQuery(from: url) == nil
        else {
            return ("magnifyingglass", nil)
        }
        if scheme == "https", tab.hasOnlySecureContent {
            return ("lock.fill", .addressSecure)
        }
        return ("exclamationmark.triangle.fill", .addressInsecure)
    }
}
