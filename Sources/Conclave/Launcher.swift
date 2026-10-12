import ConclaveVoice
import Foundation
import SwiftUI

@main
enum Launcher {
    /// Starts the browser.
    ///
    /// For diagnostics, `Conclave --interpret "frase"` prints how the voice
    /// assistant would understand a phrase and exits without opening a window.
    static func main() {
        let arguments = CommandLine.arguments
        if let flag = arguments.firstIndex(of: "--interpret"), arguments.indices.contains(flag + 1) {
            let phrase = arguments[flag + 1]
            Task {
                let command = await VoiceCommandInterpreter().interpret(phrase)
                print(command.map { String(describing: $0) } ?? "nil")
                exit(0)
            }
            dispatchMain()
        }
        ConclaveApp.main()
    }
}
