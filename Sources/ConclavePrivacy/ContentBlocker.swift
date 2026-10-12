import WebKit

/// Compiles the tracker rules once and installs them on web views.
@MainActor
public final class ContentBlocker {
    private static let identifier = "conclave.trackers.v1"

    private var ruleList: WKContentRuleList?

    public init() {}

    /// Compiles the rule list. Call before creating the first web view so that
    /// blocking is already active for the very first request.
    public func prepare() async {
        guard ruleList == nil, let store = WKContentRuleListStore.default() else { return }
        let json = ContentRuleBuilder.encode(ContentRuleBuilder.trackerRules())
        do {
            ruleList = try await store.compileContentRuleList(
                forIdentifier: Self.identifier,
                encodedContentRuleList: json
            )
        } catch {
            NSLog("Conclave: failed to compile tracker rules: \(error.localizedDescription)")
        }
    }

    public func install(on controller: WKUserContentController, enabled: Bool) {
        controller.removeAllContentRuleLists()
        if enabled, let ruleList {
            controller.add(ruleList)
        }
    }
}
