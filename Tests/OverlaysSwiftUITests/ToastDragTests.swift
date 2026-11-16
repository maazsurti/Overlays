import Testing
@testable import OverlaysSwiftUI

struct ToastDragTests {

    @Test func aLongDragDismissesEitherWay() {
        #expect(ToastDrag.outcome(offset: 40, velocity: 0) == .dismiss(direction: 1))
        #expect(ToastDrag.outcome(offset: -40, velocity: 0) == .dismiss(direction: -1))
    }

    @Test func aFlickDismissesUnderTheThreshold() {
        #expect(ToastDrag.outcome(offset: 12, velocity: 900) == .dismiss(direction: 1))
        #expect(ToastDrag.outcome(offset: -12, velocity: -900) == .dismiss(direction: -1))
    }

    @Test func aSlowShortDragSpringsBack() {
        #expect(ToastDrag.outcome(offset: 20, velocity: 0) == .springBack)
        #expect(ToastDrag.outcome(offset: -12, velocity: 200) == .springBack)
    }
}
