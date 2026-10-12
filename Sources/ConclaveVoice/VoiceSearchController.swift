import Combine
import Foundation

/// Drives a voice request from the moment the microphone opens until a command
/// is handed to the browser.
@MainActor
public final class VoiceSearchController: ObservableObject {
    public enum Failure: Equatable, Sendable {
        case permissionDenied
        case unavailable
        case nothingHeard
    }

    public enum State: Equatable, Sendable {
        case idle
        case listening
        /// The user stopped speaking and the phrase is being understood.
        case understanding
        /// A request to the browser itself was carried out.
        case confirmed(VoiceCommand)
        case failed(Failure)
    }

    @Published public private(set) var state: State = .idle
    /// Live text of what has been heard so far.
    @Published public private(set) var transcript = ""

    /// Receives the interpreted command once the user stops speaking.
    public var onCommand: ((VoiceCommand) -> Void)?

    private static let failureDisplayTime: Duration = .seconds(5)
    private static let confirmationDisplayTime: Duration = .milliseconds(2500)

    private let transcriber = SpeechTranscriber()
    private let interpreter = VoiceCommandInterpreter()
    private var dismissTask: Task<Void, Never>?
    private var interpretTask: Task<Void, Never>?

    public init() {
        transcriber.onPartialTranscript = { [weak self] text in
            self?.transcript = text
        }
        transcriber.onFinish = { [weak self] text in
            self?.understand(text)
        }
    }

    public var isListening: Bool { state == .listening }

    /// True while a request is being heard or understood.
    public var isBusy: Bool { state == .listening || state == .understanding }

    public func toggle() {
        isBusy ? cancel() : start()
    }

    public func start() {
        guard !isBusy else { return }
        dismissTask?.cancel()
        transcript = ""
        state = .listening

        Task {
            do {
                try await transcriber.start()
                // The user may have cancelled while the permission prompt was up.
                if !isListening { transcriber.cancel() }
            } catch TranscriptionError.permissionDenied {
                fail(.permissionDenied)
            } catch {
                fail(.unavailable)
            }
        }
    }

    public func cancel() {
        dismissTask?.cancel()
        interpretTask?.cancel()
        transcriber.cancel()
        state = .idle
    }

    // MARK: - Private

    private func understand(_ text: String) {
        guard isListening else { return }
        state = .understanding

        interpretTask = Task { [interpreter] in
            let command = await interpreter.interpret(text)
            guard !Task.isCancelled, state == .understanding else { return }
            guard let command else {
                fail(.nothingHeard)
                return
            }
            onCommand?(command)
            if command.isNavigation {
                state = .idle
            } else {
                show(.confirmed(command), for: Self.confirmationDisplayTime)
            }
        }
    }

    private func fail(_ failure: Failure) {
        guard isBusy else { return }
        show(.failed(failure), for: Self.failureDisplayTime)
    }

    /// Shows a transient state, then returns to idle.
    private func show(_ transient: State, for duration: Duration) {
        state = transient
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.state = .idle
        }
    }
}
