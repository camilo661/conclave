import WebKit

/// Erases everything sites have stored on this Mac through the browser.
@MainActor
public enum WebsiteDataCleaner {
    public static func clearAll() async {
        await WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        )
    }
}
