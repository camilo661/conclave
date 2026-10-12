import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Decides whether a free-form phrase is a request to the browser.
public protocol IntentClassifier: Sendable {
    /// The browser command the phrase asks for, or `nil` if it is a search.
    func classify(_ utterance: String) async -> VoiceCommand?
}

public enum IntentClassifiers {
    /// The language model built into macOS, when this Mac has one ready.
    /// It is free, needs no account and runs entirely on the device.
    public static func onDevice() -> IntentClassifier? {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            return OnDeviceIntentClassifier()
        }
        #endif
        return nil
    }
}

#if canImport(FoundationModels)

/// Understands requests phrased in ways the fixed rules do not cover, such as
/// "ponme el navegador en colores oscuros" or "quiero navegar sin dejar rastro".
@available(macOS 26.0, *)
struct OnDeviceIntentClassifier: IntentClassifier {
    /// Longer than this and the user is describing a search, not giving an order.
    private static let maximumWords = 14
    private static let timeout: Duration = .seconds(4)

    func classify(_ utterance: String) async -> VoiceCommand? {
        let phrase = utterance.replacingOccurrences(of: "\"", with: "")
        guard phrase.split(separator: " ").count <= Self.maximumWords else { return nil }

        return await withTaskGroup(of: VoiceCommand?.self) { group in
            group.addTask {
                let session = LanguageModelSession(instructions: Self.instructions)
                let answer = try? await session.respond(
                    to: "\"\(phrase)\" ->",
                    options: GenerationOptions(samplingMode: .greedy)
                )
                return answer.flatMap { Self.command(forAnswer: $0.content) }
            }
            group.addTask {
                try? await Task.sleep(for: Self.timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    static func command(forAnswer answer: String) -> VoiceCommand? {
        let label = answer
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "es"))
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix { $0.isLetter || $0 == "_" }
        return commands[String(label)]
    }

    /// Only harmless, easily undone commands are entrusted to the model.
    /// Erasing data and security settings stay with the exact rules.
    private static let commands: [String: VoiceCommand] = [
        "TEMA_OSCURO": .setDarkTheme(true),
        "TEMA_CLARO": .setDarkTheme(false),
        "PESTANA_PRIVADA": .newPrivateTab,
        "NUEVA_PESTANA": .newTab,
        "CERRAR_PESTANA": .closeTab,
        "ATRAS": .goBack,
        "ADELANTE": .goForward,
        "RECARGAR": .reload,
        "ESCUDOS_ON": .setShields(true),
        "ESCUDOS_OFF": .setShields(false),
    ]

    private static let instructions = """
    Eres el asistente de voz del navegador web Conclave. Recibes una frase que el usuario dijo en voz alta y decides si es una ORDEN para el propio navegador o una BÚSQUEDA en internet.

    Responde únicamente con una de estas etiquetas, sin nada más:
    TEMA_OSCURO: poner el navegador en negro u oscuro.
    TEMA_CLARO: poner el navegador en blanco o claro.
    PESTANA_PRIVADA: abrir navegación privada o de incógnito.
    NUEVA_PESTANA: abrir una pestaña nueva normal.
    CERRAR_PESTANA: cerrar la pestaña actual.
    ATRAS: volver a la página anterior.
    ADELANTE: ir a la página siguiente.
    RECARGAR: volver a cargar la página actual.
    ESCUDOS_ON: activar el bloqueo de rastreadores y anuncios.
    ESCUDOS_OFF: desactivar el bloqueo de rastreadores y anuncios.
    BUSQUEDA: cualquier otra cosa.

    Reglas:
    - Elige una orden solo si el usuario le pide claramente al navegador que haga eso ahora mismo.
    - Si la frase es una pregunta, pide información, o menciona otra aplicación, sitio web, producto o tema, responde BUSQUEDA.
    - Si tienes dudas, responde BUSQUEDA.

    Ejemplos:
    "ponme el navegador en colores oscuros" -> TEMA_OSCURO
    "quiero que la pantalla se vea clara" -> TEMA_CLARO
    "quiero navegar sin dejar rastro" -> PESTANA_PRIVADA
    "deja de bloquear la publicidad" -> ESCUDOS_OFF
    "llévame a la página de antes" -> ATRAS
    "cómo poner el modo oscuro en WhatsApp" -> BUSQUEDA
    "tema de WordPress blanco" -> BUSQUEDA
    "cómo borrar las cookies en Chrome" -> BUSQUEDA
    "qué es la navegación privada" -> BUSQUEDA
    "el clima en Bogotá" -> BUSQUEDA
    """
}

#endif
