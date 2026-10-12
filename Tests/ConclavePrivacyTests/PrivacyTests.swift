import Foundation
import Testing
@testable import ConclavePrivacy

@Suite struct TrackingParameterStripperTests {
    @Test func removesTrackingParametersAndKeepsTheRest() {
        let url = URL(string: "https://example.com/a?id=7&utm_source=x&fbclid=abc&UTM_Medium=y#top")!
        #expect(TrackingParameterStripper.strip(url).absoluteString == "https://example.com/a?id=7#top")
    }

    @Test func dropsTheQueryWhenOnlyTrackersWerePresent() {
        let url = URL(string: "https://example.com/a?gclid=1")!
        #expect(TrackingParameterStripper.strip(url).absoluteString == "https://example.com/a")
    }

    @Test func leavesCleanURLsUntouched() {
        let url = URL(string: "https://example.com/a?q=hola%20mundo")!
        #expect(TrackingParameterStripper.strip(url) == url)
    }
}

@Suite struct HTTPSUpgraderTests {
    @Test func upgradesPlainHTTP() {
        let upgraded = HTTPSUpgrader().upgradedURL(for: URL(string: "http://example.com:80/a?b=1")!)
        #expect(upgraded?.absoluteString == "https://example.com/a?b=1")
    }

    @Test func leavesSecureAndLocalAddressesAlone() {
        let upgrader = HTTPSUpgrader()
        #expect(upgrader.upgradedURL(for: URL(string: "https://example.com")!) == nil)
        #expect(upgrader.upgradedURL(for: URL(string: "http://localhost:8080")!) == nil)
        #expect(upgrader.upgradedURL(for: URL(string: "http://192.168.1.1")!) == nil)
    }

    @Test func respectsHostsTheUserAllowed() {
        var upgrader = HTTPSUpgrader()
        upgrader.allowInsecure(host: "Example.com")
        #expect(upgrader.upgradedURL(for: URL(string: "http://example.com/a")!) == nil)
        #expect(upgrader.upgradedURL(for: URL(string: "http://other.com/a")!) != nil)
    }
}

