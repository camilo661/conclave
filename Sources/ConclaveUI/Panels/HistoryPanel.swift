import ConclaveCore
import ConclaveHistory
import SwiftUI

/// The list of past searches and visited pages, grouped by day.
struct HistoryPanel: View {
    @ObservedObject var history: HistoryStore
    @ObservedObject var settings: AppSettings
    let onOpen: (HistoryEntry) -> Void

    @ViewState private var filter = ""

    var body: some View {
        let palette = settings.theme.palette
        let days = HistoryDay.group(history.entries(matching: filter))

        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text(.historyTitle))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.textPrimary)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                TextField(L10n.text(.historyFilterPlaceholder), text: $filter)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textPrimary)
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(Capsule().fill(palette.field))

            if days.isEmpty {
                Text(L10n.text(history.entries.isEmpty ? .historyEmpty : .historyNoMatches))
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2, pinnedViews: .sectionHeaders) {
                        ForEach(days) { day in
                            Section {
                                ForEach(day.entries) { entry in
                                    HistoryRow(
                                        entry: entry,
                                        onOpen: { onOpen(entry) },
                                        onRemove: { history.remove(entry) }
                                    )
                                }
                            } header: {
                                Text(day.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(palette.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 6)
                                    .background(palette.surface)
                            }
                        }
                    }
                }
            }

            palette.border.frame(height: 1)

            HStack {
                Text(L10n.text(.historyPrivateNote))
                    .font(.system(size: 11))
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                Button(action: history.removeAll) {
                    Label(L10n.text(.historyClearAll), systemImage: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.onAccent)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Capsule().fill(palette.accent))
                }
                .buttonStyle(.plain)
                .disabled(history.entries.isEmpty)
                .opacity(history.entries.isEmpty ? 0.3 : 1)
            }
        }
        .padding(18)
        .frame(width: 440, height: 540)
        .background(palette.surface)
        .environment(\.palette, palette)
        .preferredColorScheme(settings.theme.colorScheme)
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry
    let onOpen: () -> Void
    let onRemove: () -> Void

    @Environment(\.palette) private var palette
    @ViewState private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.searchQuery == nil ? "globe" : "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.displayTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)

            if isHovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(palette.textSecondary)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(L10n.text(.historyRemove))
                .accessibilityLabel(L10n.text(.historyRemove))
            } else {
                Text(entry.visitedAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .background(RoundedRectangle(cornerRadius: 8).fill(isHovering ? palette.field : .clear))
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(.isButton)
    }

    private var subtitle: String {
        entry.searchQuery == nil ? (entry.url.host ?? entry.url.absoluteString) : L10n.text(.historySearchLabel)
    }
}

/// The entries of one calendar day.
private struct HistoryDay: Identifiable {
    let id: Date
    let entries: [HistoryEntry]

    var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(id) { return L10n.text(.historyToday) }
        if calendar.isDateInYesterday(id) { return L10n.text(.historyYesterday) }
        return Self.formatter.string(from: id).capitalized(with: Self.spanish)
    }

    /// Splits entries, already sorted newest first, into consecutive days.
    static func group(_ entries: [HistoryEntry]) -> [HistoryDay] {
        let calendar = Calendar.current
        var days: [HistoryDay] = []
        for entry in entries {
            let day = calendar.startOfDay(for: entry.visitedAt)
            if let last = days.last, last.id == day {
                days[days.count - 1] = HistoryDay(id: day, entries: last.entries + [entry])
            } else {
                days.append(HistoryDay(id: day, entries: [entry]))
            }
        }
        return days
    }

    private static let spanish = Locale(identifier: "es")

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = spanish
        formatter.dateFormat = "EEEE d 'de' MMMM"
        return formatter
    }()
}
