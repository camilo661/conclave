# Conclave

Navegador web privado para macOS, con búsqueda y órdenes por voz.

Conclave es una aplicación nativa (Swift, SwiftUI y WebKit) que toma a Brave como referencia en privacidad y añade un asistente de voz: al abrirse empieza a escuchar, y el usuario puede buscar o darle órdenes al navegador hablando.

## Funcionalidades

- **Asistente de voz.** Escucha al abrir, transcribe en vivo y distingue una búsqueda («el clima en Bogotá») de una orden («cambia el tema a blanco», «abre navegación privada»).
- **IA gratuita en el dispositivo.** Usa el reconocimiento de voz de Apple y el modelo de lenguaje de Apple Intelligence; no depende de servicios de pago ni en la nube.
- **Búsqueda propia.** Los resultados se muestran en una página de Conclave (`conclave://search`), sin llevar al usuario al sitio de ningún buscador.
- **Privacidad.** Bloqueo de rastreadores y anuncios, cookies de terceros bloqueadas, enlaces sin parámetros de rastreo, HTTPS siempre y app en sandbox.
- **Navegación privada.** Pestañas que no guardan historial, cookies ni caché.
- **Historial.** Búsquedas y páginas visitadas, agrupadas por día, con filtro y borrado.
- **Tema blanco o negro.**

La interfaz está en español; el código, en inglés.

## Requisitos

- macOS 14 o superior (Apple Silicon o Intel).
- Herramientas de línea de comandos de Apple (`xcode-select --install`). No hace falta Xcode.
- El modelo de lenguaje para entender órdenes libres requiere un Mac con Apple Intelligence (macOS 26 o superior). Sin él, las órdenes funcionan con reglas fijas.

## Compilar y ejecutar

```bash
Scripts/build_app.sh --run   # compila y abre dist/Conclave.app
Scripts/test.sh              # ejecuta las pruebas
Scripts/package.sh           # genera la imagen de disco y el zip en dist/
```

Para ver cómo entiende el asistente una frase sin usar el micrófono:

```bash
dist/Conclave.app/Contents/MacOS/Conclave --interpret "cambia el tema a blanco"
```

## Estructura

| Módulo | Responsabilidad |
|---|---|
| `ConclaveCore` | Ajustes, resolución de direcciones, direcciones internas y textos |
| `ConclavePrivacy` | Bloqueo de rastreadores, HTTPS y configuración segura del visor web |
| `ConclaveSearch` | Fuente de resultados y página de resultados propia |
| `ConclaveVoice` | Micrófono, transcripción e interpretación de órdenes |
| `ConclaveHistory` | Historial de búsquedas y páginas |
| `ConclaveBrowser` | Pestañas, sesión y política de navegación |
| `ConclaveUI` | Vistas, temas y menús |
| `Conclave` | Punto de entrada |

La documentación completa está en [docs/Conclave-Documentacion.pdf](docs/Conclave-Documentacion.pdf).

## Limitaciones conocidas

- Los resultados de búsqueda se leen de la página HTML pública de DuckDuckGo; si cambia, la búsqueda puede dejar de funcionar.
- La app no está firmada con un certificado de Apple: en otro Mac hay que autorizarla en Ajustes del Sistema › Privacidad y seguridad.
- No hay descargas ni marcadores.
- El historial se guarda sin cifrar dentro del espacio aislado de la app.
