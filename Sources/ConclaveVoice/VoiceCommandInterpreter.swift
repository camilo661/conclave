import Foundation

/// Maps a Spanish transcript to a `VoiceCommand`.
///
/// It first decides whether the user is talking *to the browser* — changing a
/// setting, managing tabs — or simply saying what they are looking for:
///
/// 1. `CommandRules` catch clearly worded requests instantly.
/// 2. Explicit "buscar…" and "abrir…" phrases, and spoken web addresses, are
///    taken literally.
/// 3. Anything else goes to the on-device language model, when there is one,
///    which recognises requests however they are phrased.
/// 4. What remains is a search.
public struct VoiceCommandInterpreter: Sendable {
    private let rules = CommandRules()
    private let classifier: IntentClassifier?

    /// Uses the Mac's built-in language model if it is available.
    public init() {
        self.init(classifier: IntentClassifiers.onDevice())
    }

    public init(classifier: IntentClassifier?) {
        self.classifier = classifier
    }

    public func interpret(_ transcript: String) async -> VoiceCommand? {
        let text = Self.clean(transcript)
        guard !text.isEmpty else { return nil }
        let folded = Self.fold(text)

        if let command = rules.match(folded) {
            return command
        }
        if let target = Self.remainder(of: text, folded: folded, afterAnyOf: Self.openPrefixes) {
            if let address = Self.address(from: target, assumeDotCom: true) {
                return .open(address)
            }
            return .search(target)
        }
        if let query = Self.remainder(of: text, folded: folded, afterAnyOf: Self.searchPrefixes) {
            return .search(query)
        }
        if let address = Self.address(from: text, assumeDotCom: false) {
            return .open(address)
        }
        if let command = await classifier?.classify(text) {
            return command
        }
        return .search(text)
    }

    // MARK: - Vocabulary (matched without accents or capitals)

    private static let openPrefixes = [
        "abrir ", "abre ", "abreme ", "ir a ", "ve a ", "vamos a ",
        "visitar ", "visita ", "entrar a ", "entra a ", "navegar a ", "navega a ",
    ]

    private static let searchPrefixes = [
        "buscar ", "busca ", "buscame ", "busqueda de ", "investigar ", "investiga ",
    ]

    // MARK: - Text handling

    private static let trimmed = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet(charactersIn: ".,;:!?¡¿"))

    static func clean(_ transcript: String) -> String {
        transcript.trimmingCharacters(in: trimmed)
    }

    static func fold(_ text: String) -> String {
        text.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "es"))
    }

    /// The part of `text` that follows the first matching prefix, keeping the
    /// user's original accents and capitals.
    private static func remainder(of text: String, folded: String, afterAnyOf prefixes: [String]) -> String? {
        guard let prefix = prefixes.first(where: { folded.hasPrefix($0) }) else { return nil }
        let source = text.count == folded.count ? text : folded
        let rest = clean(String(source.dropFirst(prefix.count)))
        return rest.isEmpty ? nil : rest
    }

    /// Recognises spoken addresses such as "wikipedia punto org". With
    /// `assumeDotCom`, a single bare word ("youtube") becomes "youtube.com".
    static func address(from phrase: String, assumeDotCom: Bool) -> String? {
        let spoken = fold(phrase)
            .replacingOccurrences(of: " punto ", with: ".")
            .replacingOccurrences(of: " barra ", with: "/")

        if spoken.contains(".") {
            let candidate = spoken.replacingOccurrences(of: " ", with: "")
            let addressPattern = #/[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}(/[^\s]*)?/#
            return candidate.wholeMatch(of: addressPattern) != nil ? candidate : nil
        }
        if assumeDotCom, spoken.wholeMatch(of: #/[a-z0-9-]+/#) != nil {
            return spoken + ".com"
        }
        return nil
    }
}
