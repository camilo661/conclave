import Testing
@testable import ConclaveVoice

/// Stands in for the language model so tests are deterministic.
private struct StubClassifier: IntentClassifier {
    let answers: [String: VoiceCommand]

    func classify(_ utterance: String) async -> VoiceCommand? {
        answers[utterance]
    }
}

@Suite struct VoiceCommandInterpreterTests {
    private let interpreter = VoiceCommandInterpreter(classifier: nil)

    @Test func plainSpeechBecomesASearch() async {
        #expect(await interpreter.interpret("El clima en Bogotá mañana") == .search("El clima en Bogotá mañana"))
    }

    @Test func searchPrefixIsRemoved() async {
        #expect(await interpreter.interpret("Buscar recetas de arepas.") == .search("recetas de arepas"))
        #expect(await interpreter.interpret("búscame vuelos a Madrid") == .search("vuelos a Madrid"))
    }

    @Test func opensSpokenAddresses() async {
        #expect(await interpreter.interpret("Abrir wikipedia punto org") == .open("wikipedia.org"))
        #expect(await interpreter.interpret("ve a YouTube") == .open("youtube.com"))
        #expect(await interpreter.interpret("github.com") == .open("github.com"))
    }

    @Test func openWithAPhraseFallsBackToSearch() async {
        #expect(await interpreter.interpret("abre el periódico de hoy") == .search("el periódico de hoy"))
    }

    @Test func silenceProducesNoCommand() async {
        #expect(await interpreter.interpret("") == nil)
        #expect(await interpreter.interpret("  ") == nil)
    }

    @Test(arguments: [
        ("Cambia el tema del navegador a blanco", VoiceCommand.setDarkTheme(false)),
        ("modo claro", .setDarkTheme(false)),
        ("Pon el navegador en modo oscuro, por favor", .setDarkTheme(true)),
        ("Tema negro", .setDarkTheme(true)),
        ("quita el modo oscuro", .setDarkTheme(false)),
        ("cambia el tema", .toggleTheme),
        ("Abre navegación privada", .newPrivateTab),
        ("abre una ventana de navegación privada", .newPrivateTab),
        ("Nueva pestaña privada", .newPrivateTab),
        ("Modo incógnito.", .newPrivateTab),
        ("Nueva pestaña", .newTab),
        ("abre otra pestaña", .newTab),
        ("cerrar pestana", .closeTab),
        ("cierra la pestaña privada", .closeTab),
        ("Atrás.", .goBack),
        ("vuelve a la página anterior", .goBack),
        ("adelante", .goForward),
        ("Recargar página", .reload),
        ("activa los escudos", .setShields(true)),
        ("bloquea los rastreadores", .setShields(true)),
        ("desactiva el bloqueo de anuncios", .setShields(false)),
        ("usa siempre HTTPS", .setHTTPSOnly(true)),
        ("desactiva HTTPS", .setHTTPSOnly(false)),
        ("borra los datos de navegación", .clearBrowsingData),
        ("borra las cookies", .clearBrowsingData),
        ("activa borrar datos al salir", .setClearDataOnExit(true)),
        ("desactiva borrar los datos al salir", .setClearDataOnExit(false)),
        ("desactiva la búsqueda por voz al abrir", .setVoiceOnLaunch(false)),
        ("muéstrame el historial", .showHistory),
        ("abre el historial de búsquedas", .showHistory),
        ("borra el historial", .clearHistory),
        ("elimina todo el historial de navegación", .clearHistory),
    ])
    func recognisesRequestsToTheBrowser(phrase: String, expected: VoiceCommand) async {
        #expect(await interpreter.interpret(phrase) == expected)
    }

    /// Phrases that share words with commands but are really searches.
    @Test(arguments: [
        "tema de WordPress blanco",
        "cómo poner el modo oscuro en WhatsApp",
        "pantalla negra",
        "fondo blanco",
        "recargar celular Claro",
        "pestañas postizas precio",
        "cómo abrir una ventana de incógnito en Safari",
        "bloqueador de anuncios",
        "borrar cookies",
        "cómo borrar las cookies en Chrome",
        "volver al futuro",
        "historial de precios del dólar",
        "cómo borrar el historial de Chrome",
        "borrar historial",
        "cerrar cuenta de Instagram",
        "pintura blanca para pared",
    ])
    func leavesSearchesAlone(phrase: String) async {
        #expect(await interpreter.interpret(phrase) == .search(phrase))
    }

    @Test func asksTheModelOnlyWhenRulesDoNotDecide() async {
        let model = StubClassifier(answers: [
            "ponme el navegador en colores oscuros": .setDarkTheme(true),
            // A wrong answer the rules must pre-empt.
            "modo claro": .closeTab,
        ])
        let interpreter = VoiceCommandInterpreter(classifier: model)

        #expect(await interpreter.interpret("ponme el navegador en colores oscuros") == .setDarkTheme(true))
        #expect(await interpreter.interpret("modo claro") == .setDarkTheme(false))
        #expect(await interpreter.interpret("recetas de arepas") == .search("recetas de arepas"))
    }
}
