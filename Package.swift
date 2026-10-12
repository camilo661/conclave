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

        .testTarget(name: "ConclaveCoreTests", dependencies: ["ConclaveCore"]),
        .testTarget(name: "ConclavePrivacyTests", dependencies: ["ConclavePrivacy"]),
    ]
)
