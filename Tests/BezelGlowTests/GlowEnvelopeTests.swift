import XCTest
@testable import BezelGlow

final class GlowEnvelopeTests: XCTestCase {
    func testAttackRisesTowardTarget() {
        var next = 0.0
        // The follower caps each frame at 0.05 seconds. Simulate 0.18 seconds
        // of normal frames rather than treating it as one stalled frame.
        for _ in 0..<18 {
            next = GlowEnvelope.step(current: next, target: 1, deltaTime: 0.01, attack: 0.18, release: 0.6)
        }
        XCTAssertGreaterThan(next, 0.5)
        XCTAssertLessThan(next, 1)
    }

    func testStalledFrameIsCapped() {
        let normal = GlowEnvelope.step(current: 0, target: 1, deltaTime: 0.05)
        let stalled = GlowEnvelope.step(current: 0, target: 1, deltaTime: 10)
        XCTAssertEqual(stalled, normal, accuracy: 0.000_001)
        XCTAssertEqual(stalled, 1 - exp(-0.05 / 0.18), accuracy: 0.000_001)
    }

    func testNonpositiveDeltaTimeDoesNotAdvance() {
        for deltaTime in [0.0, -1.0] {
            let next = GlowEnvelope.step(current: 0.4, target: 1, deltaTime: deltaTime)
            XCTAssertEqual(next, 0.4)
        }
    }

    func testReleaseFallsSlowerThanAttack() {
        let up = GlowEnvelope.step(current: 0, target: 1, deltaTime: 0.2, attack: 0.18, release: 0.8)
        let down = GlowEnvelope.step(current: 1, target: 0, deltaTime: 0.2, attack: 0.18, release: 0.8)
        XCTAssertGreaterThan(up, 1 - down)
    }

    func testClamps() {
        let hi = GlowEnvelope.step(current: 0.9, target: 4, deltaTime: 1, attack: 0.01, release: 0.01)
        let lo = GlowEnvelope.step(current: 0.1, target: -2, deltaTime: 1, attack: 0.01, release: 0.01)
        XCTAssertEqual(hi, 1, accuracy: 0.001)
        XCTAssertEqual(lo, 0, accuracy: 0.001)
    }

    func testRegions() {
        XCTAssertTrue(GlowRegion.all.isFullPerimeter)
        XCTAssertTrue(GlowRegion.bottom.isSingleEdge)
        XCTAssertFalse(GlowRegion.voiceFrame.isSingleEdge)
        XCTAssertEqual(GlowRegion.voiceFrame.edgeCount, 3)
        XCTAssertTrue(GlowRegion.screen.contains(.top))
        XCTAssertFalse(GlowRegion.horizontal.contains(.bottom))
    }
}
