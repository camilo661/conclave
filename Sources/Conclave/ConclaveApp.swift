import ConclaveUI
import SwiftUI

struct ConclaveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        let environment = appDelegate.environment

        Window("Conclave", id: "main") {
            BrowserWindowView(session: environment.session, voice: environment.voice)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 820)
        .commands {
            BrowserCommands(session: environment.session, voice: environment.voice)
        }
    }
}
