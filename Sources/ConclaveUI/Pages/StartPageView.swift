import ConclaveCore
import ConclaveVoice
import SwiftUI

/// What a new tab shows: the logo, a search field and the voice-search entry point.
struct StartPageView: View {
    @ObservedObject var voice: VoiceSearchController
    let isPrivate: Bool
    let recentSearches: [String]
    let onSubmit: (String) -> Void
    /// Repeats one of the recent searches.
    let onSearch: (String) -> Void

    @Environment(\.palette) private var palette
    @ViewState private var query = ""

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            BrandLogo(size: 132)
            VStack(spacing: 8) {
                Text(Brand.name)
                    .font(.system(size: 34, weight: .heavy))
                    .tracking(10)
                    .foregroundStyle(palette.textPrimary)
                Text(L10n.text(.startTagline))
                    .font(.system(size: 14))
                    .foregroundStyle(palette.textSecondary)
            }

            searchField
                .padding(.top, 8)

            if isPrivate {
                privateNotice
            } else if !recentSearches.isEmpty {
                recentSearchChips
            }

            VStack(spacing: 6) {
                Text(L10n.text(.startVoiceHint))
                    .font(.system(size: 12, weight: .medium))
                Text(L10n.text(.startVoiceExamples))
                    .font(.system(size: 11))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(palette.textSecondary)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }

    private var recentSearchChips: some View {
        VStack(spacing: 8) {
            Text(L10n.text(.startRecentSearches))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
            HStack(spacing: 6) {
                ForEach(recentSearches, id: \.self) { query in
                    Button { onSearch(query) } label: {
                        Label(query, systemImage: "clock.arrow.circlepath")
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .foregroundStyle(palette.textPrimary)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: 170)
                            .frame(height: 28)
                            .background(Capsule().fill(palette.field))
                            .overlay(Capsule().strokeBorder(palette.border))
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }
            }
        }
        .frame(maxWidth: 760)
    }

    /// Explains what a private tab does and does not protect against.
    private var privateNotice: some View {
        VStack(spacing: 6) {
            Label(L10n.text(.privateTitle), systemImage: PrivateBrowsing.symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(palette.textPrimary)
            Text(L10n.text(.privateDetail))
                .foregroundStyle(palette.textPrimary)
            Text(L10n.text(.privateCaveat))
                .foregroundStyle(palette.textSecondary)
        }
        .font(.system(size: 12))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .frame(maxWidth: 600)
        .background(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.border))
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.textSecondary)

            TextField(L10n.text(.startSearchPlaceholder), text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(palette.textPrimary)
                .onSubmit { onSubmit(query) }

            Button(action: voice.toggle) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.onAccent)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(palette.accent))
            }
            .buttonStyle(.plain)
            .help(L10n.text(.toolbarVoice))
            .accessibilityLabel(L10n.text(.toolbarVoice))
        }
        .padding(.leading, 18)
        .padding(.trailing, 7)
        .frame(height: 48)
        .frame(maxWidth: 600)
        .background(Capsule().fill(palette.field))
        .overlay(Capsule().strokeBorder(palette.border))
    }
}
