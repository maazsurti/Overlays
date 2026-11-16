import CoreGraphics
import Testing
@testable import Overlays

@MainActor
struct ToastCapsuleTests {

    @Test func aShortToastFitsItsMessage() {
        let capsule = ToastCapsule(toast: Toast(message: "Profile saved")) {}

        let size = capsule.fittingSize(maxWidth: 320)

        #expect(size.width < 320)
        #expect(size.height >= 44)
    }

    @Test func aLongToastWrapsInsideTheWidth() {
        let capsule = ToastCapsule(toast: Toast(message: String(repeating: "long message ", count: 12))) {}

        let size = capsule.fittingSize(maxWidth: 320)

        #expect(size.width <= 320)
        #expect(size.height > 44)
    }
}
