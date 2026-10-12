import ConclaveBrowser
import ConclaveCore
import SwiftUI

/// Shown instead of a page that was blocked for security or failed to load.
struct PageNoticeView: View {
    let notice: BrowserTab.Notice
    let canGoBack: Bool
    let onContinueInsecurely: () -> Void
    let onRetry: () -> Void
    let onGoBack: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(palette.textPrimary)
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(palette.textPrimary)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)

            HStack(spacing: 10) {
                switch notice {
                case .insecureConnection:
                    if canGoBack {
                        noticeButton(.noticeGoBack, isPrimary: true, action: onGoBack)
                    }
                    noticeButton(.noticeInsecureContinue, isPrimary: false, action: onContinueInsecurely)
                case .loadFailed:
                    noticeButton(.noticeRetry, isPrimary: true, action: onRetry)
                }
            }
            .padding(.top, 6)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }

    private var symbol: String {
        switch notice {
        case .insecureConnection: return "lock.slash.fill"
        case .loadFailed: return "wifi.exclamationmark"
        }
    }

    private var title: String {
        switch notice {
        case .insecureConnection: return L10n.text(.noticeInsecureTitle)
        case .loadFailed: return L10n.text(.noticeErrorTitle)
        }
    }

    private var message: String {
        switch notice {
        case .insecureConnection(let url):
            return L10n.text(.noticeInsecureMessage, url.host ?? url.absoluteString)
        case .loadFailed(let message, _):
            return message
        }
    }

    private func noticeButton(_ label: L10n.Key, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(L10n.text(label))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isPrimary ? palette.onAccent : palette.textPrimary)
                .padding(.horizontal, 16)
                .frame(height: 34)
                .background(Capsule().fill(isPrimary ? palette.accent : .clear))
                .overlay(Capsule().strokeBorder(isPrimary ? .clear : palette.border))
        }
        .buttonStyle(.plain)
    }
}
