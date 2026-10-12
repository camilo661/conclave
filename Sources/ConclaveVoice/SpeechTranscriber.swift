import AVFoundation
import Speech

public enum TranscriptionError: Error, Equatable {
    case permissionDenied
    case recognizerUnavailable
    case audioInputUnavailable
}

/// Captures the microphone and turns a single spoken phrase into text.
///
/// Recognition runs on the Mac itself whenever the system supports it for
/// Spanish, so the audio does not leave the device.
@MainActor
public final class SpeechTranscriber {
    /// Called every time the recognised text changes while the user speaks.
    public var onPartialTranscript: ((String) -> Void)?
    /// Called once with the final text (empty if nothing was heard).
    public var onFinish: ((String) -> Void)?

    /// How long to wait for the user to start speaking.
    private static let initialTimeout: TimeInterval = 8
    /// How long a pause marks the end of the phrase.
    private static let pauseTimeout: TimeInterval = 1.6

    private let recognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var transcript = ""
    private var isRunning = false
    /// Distinguishes the current session from callbacks of a previous one.
    private var generation = 0

    public init() {
        recognizer = Self.makeSpanishRecognizer()
    }

    public func start() async throws {
        guard !isRunning else { return }
        guard await SpeechPermissions.request() else { throw TranscriptionError.permissionDenied }
        guard !isRunning else { return }
        guard let recognizer, recognizer.isAvailable else { throw TranscriptionError.recognizerUnavailable }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw TranscriptionError.audioInputUnavailable
        }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format, block: Self.tapBlock(feeding: request))
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw TranscriptionError.audioInputUnavailable
        }

        self.request = request
        transcript = ""
        isRunning = true
        task = recognizer.recognitionTask(
            with: request,
            resultHandler: Self.resultHandler(for: self, generation: generation)
        )
        scheduleSilenceTimer(after: Self.initialTimeout)
    }

    /// Stops listening without reporting a result.
    public func cancel() {
        guard isRunning else { return }
        tearDown()
    }

    // MARK: - Private

    private func handle(text: String?, ended: Bool, generation: Int) {
        guard isRunning, generation == self.generation else { return }
        if let text, !text.isEmpty {
            transcript = text
            onPartialTranscript?(text)
            scheduleSilenceTimer(after: Self.pauseTimeout)
        }
        if ended { finish() }
    }

    private func finish() {
        guard isRunning else { return }
        let result = transcript
        tearDown()
        onFinish?(result)
    }

    private func tearDown() {
        isRunning = false
        generation += 1
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }

    private func scheduleSilenceTimer(after interval: TimeInterval) {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.finish() }
        }
    }

    private static func makeSpanishRecognizer() -> SFSpeechRecognizer? {
        var candidates: [Locale] = []
        if Locale.current.language.languageCode == .spanish {
            candidates.append(Locale.current)
        }
        candidates += ["es-ES", "es-MX", "es-US"].map(Locale.init(identifier:))
        return candidates.lazy.compactMap(SFSpeechRecognizer.init(locale:)).first
    }

    // These closures run on audio and recognition queues, so they are built
    // outside the main actor.

    nonisolated private static func tapBlock(
        feeding request: SFSpeechAudioBufferRecognitionRequest
    ) -> AVAudioNodeTapBlock {
        { buffer, _ in request.append(buffer) }
    }

    nonisolated private static func resultHandler(
        for transcriber: SpeechTranscriber,
        generation: Int
    ) -> (SFSpeechRecognitionResult?, Error?) -> Void {
        { [weak transcriber] result, error in
            let text = result?.bestTranscription.formattedString
            let ended = (result?.isFinal ?? false) || error != nil
            Task { @MainActor in
                transcriber?.handle(text: text, ended: ended, generation: generation)
            }
        }
    }
}

/// Asks for microphone and speech-recognition access.
enum SpeechPermissions {
    static func request() async -> Bool {
        guard await AVCaptureDevice.requestAccess(for: .audio) else { return false }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
