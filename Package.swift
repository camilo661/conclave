// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Conclave",
    platforms: [.macOS(.v14)],
    targets: [
        // Shared models, settings, localization and URL resolution. No UI, no WebKit.
        .target(name: "ConclaveCore"),

        // Tracker blocking, HTTPS upgrading, hardened web view configuration.
        .target(name: "ConclavePrivacy", dependencies: ["ConclaveCore"]),

        // Conclave's own results page and the index that feeds it.
        .target(name: "ConclaveSearch", dependencies: ["ConclaveCore"]),

        // Searches and visited pages, saved on this Mac.
        .target(name: "ConclaveHistory", dependencies: ["ConclaveCore"]),

        // Speech recognition and spoken-command interpretation.
        .target(name: "ConclaveVoice"),

        .testTarget(name: "ConclaveCoreTests", dependencies: ["ConclaveCore"]),
        .testTarget(name: "ConclaveHistoryTests", dependencies: ["ConclaveHistory", "ConclaveCore"]),
        .testTarget(name: "ConclavePrivacyTests", dependencies: ["ConclavePrivacy"]),
        .testTarget(name: "ConclaveSearchTests", dependencies: ["ConclaveSearch"]),
        .testTarget(name: "ConclaveVoiceTests", dependencies: ["ConclaveVoice"]),
    ]
)
