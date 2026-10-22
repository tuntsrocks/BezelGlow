import XCTest
@testable import BezelGlow

final class GlowEnvelopeTests: XCTestCase {
    func testAttackRisesTowardTarget() {
        let next = GlowEnvelope.step(current: 0, target: 1, deltaTime: 0.18, attack: 0.18, release: 0.6)
        XCTAssertGreaterThan(next, 0.5)
        XCTAssertLessThan(next, 1)
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
