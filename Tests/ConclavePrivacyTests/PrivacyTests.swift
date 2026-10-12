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

