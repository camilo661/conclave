import ConclaveCore
import ConclaveVoice
import SwiftUI

/// Floating panel that shows what is being heard during a voice search.
struct VoiceOverlayView: View {
    @ObservedObject var voice: VoiceSearchController

    @Environment(\.palette) private var palette

    var body: some View {
        Group {
            switch voice.state {
            case .idle:
                EmptyView()
            case .listening:
                panel {
                    ListeningIndicator(color: palette.onAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.text(.voiceListening))
                            .font(.system(size: 11, weight: .semibold))
                            .opacity(0.65)
                        Text(voice.transcript.isEmpty ? L10n.text(.voiceSpeakNow) : voice.transcript)
                            .font(.system(size: 15, weight: .medium))
                            .lineLimit(2)
                    }
                    Spacer(minLength: 12)
                    Button(L10n.text(.voiceCancel), action: voice.cancel)
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .overlay(Capsule().strokeBorder(palette.onAccent.opacity(0.4)))
                        .keyboardShortcut(.cancelAction)
                }
            case .understanding:
                panel {
                    ListeningIndicator(color: palette.onAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.text(.voiceUnderstanding))
                            .font(.system(size: 11, weight: .semibold))
                            .opacity(0.65)
                        Text(voice.transcript)
                            .font(.system(size: 15, weight: .medium))
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
            case .confirmed(let command):
                panel {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text(L10n.text(VoiceConfirmation.message(for: command)))
                        .font(.system(size: 14, weight: .semibold))
                    Spacer(minLength: 0)
                }
            case .failed(let failure):
                panel {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(L10n.text(Self.message(for: failure)))
                        .font(.system(size: 13, weight: .medium))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.bottom, 28)
        .padding(.horizontal, 24)
        .animation(.easeOut(duration: 0.2), value: voice.state)
    }

    private func panel(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 14, content: content)
            .foregroundStyle(palette.onAccent)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: 560)
            .background(RoundedRectangle(cornerRadius: 22).fill(palette.accent))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private static func message(for failure: VoiceSearchController.Failure) -> L10n.Key {
        switch failure {
        case .permissionDenied: return .voicePermissionDenied
        case .unavailable: return .voiceUnavailable
        case .nothingHeard: return .voiceNothingHeard
        }
    }
}

/// Animated bars signalling that the microphone is open.
private struct ListeningIndicator: View {
    let color: Color

    private static let barCount = 4

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 3) {
                ForEach(0..<Self.barCount, id: \.self) { index in
                    let phase = time * 6 + Double(index) * 0.9
                    Capsule()
                        .fill(color)
                        .frame(width: 4, height: 10 + 12 * abs(sin(phase)))
                }
            }
            .frame(width: 28, height: 24)
        }
        .accessibilityHidden(true)
    }
}
