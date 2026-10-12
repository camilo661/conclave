import Foundation

/// Recognises requests addressed to the browser itself ("cambia el tema a
/// blanco", "abre navegación privada") without any model, instantly.
///
/// A phrase is a command only when every meaningful word in it belongs to the
/// vocabulary of one request. One foreign word ("tema de WordPress blanco")
/// and the phrase is left alone, so real searches are never swallowed.
struct CommandRules: Sendable {
    /// - Parameter text: The utterance, lowercased and without accents.
    func match(_ text: String) -> VoiceCommand? {
        let words = Set(text.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        let meaningful = words.subtracting(Vocabulary.filler)
        guard !meaningful.isEmpty else { return nil }
        return Self.rules.first { $0.matches(words: words, meaningful: meaningful) }?.command
    }

    private struct Rule: Sendable {
        let command: VoiceCommand
        /// The phrase must contain at least one word from each group.
        let required: [Set<String>]
        /// Other words the phrase may contain.
        let optional: Set<String>

        init(_ command: VoiceCommand, required: [Set<String>], optional: Set<String> = []) {
            self.command = command
            self.required = required
            self.optional = optional
        }

        func matches(words: Set<String>, meaningful: Set<String>) -> Bool {
            guard required.allSatisfy({ !$0.isDisjoint(with: words) }) else { return false }
            let known = required.reduce(optional) { $0.union($1) }
            return meaningful.isSubset(of: known)
        }
    }

    /// Ordered from most to least specific: the first match wins.
    private static let rules: [Rule] = {
        typealias V = Vocabulary
        return [
            Rule(.closeTab, required: [V.tab, V.close], optional: V.privateMode),

            Rule(.clearHistory, required: [V.eraseNow, V.history], optional: V.historyExtras),
            Rule(.showHistory, required: [V.history, V.show], optional: V.historyExtras),

            Rule(.setClearDataOnExit(false), required: [V.erase, V.onExit, V.disable], optional: V.data),
            Rule(.setClearDataOnExit(true), required: [V.erase, V.onExit],
                 optional: V.data.union(V.enable).union(["siempre", "automaticamente"])),
            // Erasing data is irreversible, so only a direct order triggers it.
            Rule(.clearBrowsingData, required: [V.eraseNow, V.data], optional: ["todos", "todo", "mis"]),

            Rule(.setVoiceOnLaunch(false), required: [V.voice, V.onLaunch, V.disable], optional: V.voiceExtras),
            Rule(.setVoiceOnLaunch(true), required: [V.voice, V.onLaunch, V.enable], optional: V.voiceExtras),

            Rule(.setDarkTheme(false), required: [V.dark, V.disable], optional: V.themeExtras),
            Rule(.setDarkTheme(true), required: [V.light, V.disable], optional: V.themeExtras),
            Rule(.setDarkTheme(true), required: [V.dark, V.theme.union(V.set)], optional: V.themeExtras),
            Rule(.setDarkTheme(false), required: [V.light, V.theme.union(V.set)], optional: V.themeExtras),
            Rule(.toggleTheme, required: [["tema", "apariencia", "aspecto"], V.swap], optional: ["color", "colores"]),

            Rule(.newPrivateTab, required: [V.privateMode, V.privateContext], optional: V.privateContext),
            Rule(.newPrivateTab, required: [["incognito"]]),
            Rule(.newTab, required: [V.tab, V.open]),

            Rule(.setShields(false), required: [V.shields, V.disable.union(["permite", "permitir", "desbloquea"])]),
            Rule(.setShields(true), required: [V.shields, V.enable.union(["bloquea", "bloquear"])]),

            Rule(.setHTTPSOnly(false), required: [["https"], V.disable], optional: V.httpsExtras),
            Rule(.setHTTPSOnly(true), required: [["https"], V.enable.union(["usa", "usar", "siempre"])],
                 optional: V.httpsExtras),

            Rule(.goBack, required: [V.back], optional: V.pageExtras),
            Rule(.goForward, required: [V.forward], optional: V.pageExtras),
            Rule(.reload, required: [V.reload], optional: V.pageExtras),
        ]
    }()
}

/// Spanish word lists, written without accents.
private enum Vocabulary {
    /// Words that carry no intent and are ignored everywhere.
    static let filler: Set<String> = [
        "el", "la", "los", "las", "un", "una", "lo", "de", "del", "a", "al", "en", "con", "para",
        "por", "favor", "porfa", "que", "me", "mi", "mis", "tu", "se", "te", "y", "este", "esta",
        "actual", "ahora", "ya", "mismo", "oye", "hey", "quiero", "quisiera", "necesito",
        "puedes", "podrias", "navegador", "conclave", "modo",
    ]

    static let enable: Set<String> = [
        "activa", "activar", "activame", "enciende", "encender", "habilita", "habilitar",
        "prende", "prender", "pon", "poner",
    ]
    static let disable: Set<String> = [
        "desactiva", "desactivar", "desactivame", "apaga", "apagar", "quita", "quitar",
        "deshabilita", "deshabilitar",
    ]
    static let set: Set<String> = [
        "cambia", "cambiar", "cambiame", "cambialo", "pon", "poner", "ponme", "ponlo",
        "activa", "activar", "usa", "usar", "coloca", "pasa", "pasar", "deja", "dejalo",
    ]
    static let swap: Set<String> = [
        "cambia", "cambiar", "cambiame", "alterna", "alternar", "invierte", "invertir",
    ]

    static let dark: Set<String> = ["negro", "negra", "oscuro", "oscura", "oscuros", "nocturno", "dark"]
    static let light: Set<String> = ["blanco", "blanca", "claro", "clara", "claros", "light"]
    static let theme: Set<String> = ["tema", "modo", "apariencia", "aspecto"]
    static let themeExtras: Set<String> = theme.union(set).union(["color", "colores", "fondo", "pantalla"])

    static let tab: Set<String> = ["pestana", "ventana"]
    static let open: Set<String> = [
        "abre", "abrir", "abreme", "nueva", "nuevo", "otra", "crea", "crear", "agrega", "agregar",
    ]
    static let close: Set<String> = ["cierra", "cerrar", "cierrame", "cierrala", "quita", "quitar"]

    static let privateMode: Set<String> = ["privada", "privado", "incognito", "incognita"]
    static let privateContext: Set<String> = tab.union(open).union([
        "navegacion", "navegar", "modo", "sesion", "inicia", "iniciar", "entra", "entrar",
        "activa", "activar", "pon",
    ])

    static let shields: Set<String> = [
        "escudo", "escudos", "proteccion", "rastreadores", "rastreo", "anuncios", "publicidad",
        "bloqueo", "bloqueador",
    ]
    static let httpsExtras: Set<String> = ["siempre", "usa", "usar", "solo", "conexion", "segura"]

    static let eraseNow: Set<String> = ["borra", "borrame", "elimina", "limpia"]
    static let erase: Set<String> = eraseNow.union(["borrar", "eliminar", "limpiar", "borrado"])
    static let data: Set<String> = ["datos", "cookies", "cache", "navegacion", "almacenamiento"]
    static let onExit: Set<String> = ["salir", "cerrar", "cierre", "salida", "salga"]

    static let history: Set<String> = ["historial"]
    static let show: Set<String> = [
        "abre", "abrir", "abreme", "muestra", "mostrar", "muestrame", "ver", "ensename", "ensena",
    ]
    static let historyExtras: Set<String> = ["busquedas", "busqueda", "navegacion", "todo", "paginas"]

    static let voice: Set<String> = ["voz", "microfono", "escucha", "escuchar"]
    static let onLaunch: Set<String> = ["abrir", "abrirse", "abra", "inicio", "iniciar", "arrancar", "arranque"]
    static let voiceExtras: Set<String> = ["busqueda", "buscar", "automatica"]

    static let back: Set<String> = [
        "atras", "anterior", "volver", "vuelve", "regresa", "regresar", "retrocede", "retroceder",
    ]
    static let forward: Set<String> = ["adelante", "siguiente", "avanza", "avanzar"]
    static let reload: Set<String> = [
        "recarga", "recargar", "recargala", "actualiza", "actualizar", "refresca", "refrescar",
    ]
    static let pageExtras: Set<String> = ["pagina", "sitio", "ir", "ve", "hacia"]
}
