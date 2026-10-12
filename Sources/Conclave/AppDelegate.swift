import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let environment = AppEnvironment()

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard environment.settings.clearDataOnExit else { return .terminateNow }
        Task {
            await environment.session.clearBrowsingData()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
