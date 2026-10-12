import ConclaveBrowser
import ConclaveCore
import ConclaveHistory
import ConclaveVoice

/// Composition root: creates the app's long-lived objects and connects them.
@MainActor
final class AppEnvironment {
    let settings: AppSettings
    let session: BrowserSession
    let voice: VoiceSearchController

    init() {
        let settings = AppSettings()
        let history = HistoryStore(fileURL: HistoryStore.defaultFileURL)
        let session = BrowserSession(settings: settings, history: history)
        let voice = VoiceSearchController()
        voice.onCommand = { [weak session] command in
            session?.perform(command)
        }

        self.settings = settings
        self.session = session
        self.voice = voice
    }
}
