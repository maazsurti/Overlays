import CoreGraphics
import Testing
@testable import Overlays

struct ToastMotionTests {

    @Test func topToastsLeaveTheWayTheyArrived() {
        #expect(ToastMotion.entryOffset(for: .top) == -ToastMotion.travel)
        #expect(ToastMotion.exitOffset(for: .top) == ToastMotion.entryOffset(for: .top))
    }

    @Test func bottomToastsLeaveTheWayTheyArrived() {
        #expect(ToastMotion.entryOffset(for: .bottom) == ToastMotion.travel)
        #expect(ToastMotion.exitOffset(for: .bottom) == ToastMotion.entryOffset(for: .bottom))
    }

    @Test func aDismissedDragLeavesInTheDraggedDirection() {
        #expect(ToastMotion.exitOffset(for: .top, dragDirection: 1) == ToastMotion.travel)
        #expect(ToastMotion.exitOffset(for: .bottom, dragDirection: -1) == -ToastMotion.travel)
    }

    @Test func aSlowShortDragSpringsBack() {
        #expect(ToastDrag.outcome(offset: 20, velocity: 0) == .springBack)
        #expect(ToastDrag.outcome(offset: -39, velocity: 120) == .springBack)
    }

    @Test(arguments: [CGFloat(40), 60, 120])
    func aLongDragDismissesEitherWay(offset: CGFloat) {
        #expect(ToastDrag.outcome(offset: offset, velocity: 0) == .dismiss(direction: 1))
        #expect(ToastDrag.outcome(offset: -offset, velocity: 0) == .dismiss(direction: -1))
    }

    @Test func aFlickDismissesUnderTheThreshold() {
        #expect(ToastDrag.outcome(offset: 12, velocity: 900) == .dismiss(direction: 1))
        #expect(ToastDrag.outcome(offset: -12, velocity: -900) == .dismiss(direction: -1))
    }

    @Test func aFlickAgainstTheDragDoesNotDismiss() {
        #expect(ToastDrag.outcome(offset: 12, velocity: -900) == .springBack)
        #expect(ToastDrag.outcome(offset: -12, velocity: 900) == .springBack)
    }

    @Test func aFlickWithoutTravelDismissesThatWay() {
        #expect(ToastDrag.outcome(offset: 0, velocity: 700) == .dismiss(direction: 1))
        #expect(ToastDrag.outcome(offset: 0, velocity: -700) == .dismiss(direction: -1))
        #expect(ToastDrag.outcome(offset: 0, velocity: 0) == .springBack)
    }
}
