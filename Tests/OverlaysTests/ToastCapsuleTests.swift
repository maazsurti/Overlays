import CoreGraphics
import UIKit
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

    @Test func aTwoLineToastIsTwoLinesTall() {
        let previous = OverlayTheme.current
        defer { OverlayTheme.current = previous }
        OverlayTheme.current = OverlayTheme(
            toastShowsGlyph: false,
            toastHorizontalMargin: 16,
            toastFillsWidth: true,
            toastLineHeight: 22.5,
            toastContentInsets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
            toastFontSize: 15,
            toastFontWeight: .regular
        )
        let message = String(repeating: "wrapped message ", count: 4)
        let capsule = ToastCapsule(toast: Toast(message: message)) {}

        let size = capsule.fittingSize(maxWidth: 362)

        #expect(size.width == 362)
        #expect(size.height >= 2 * 22.5 + 24 - 3)
        #expect(size.height <= 2 * 22.5 + 24 + 6)
    }

    @Test func aTwoLineToastWithAGlyphKeepsBothLines() {
        let previous = OverlayTheme.current
        defer { OverlayTheme.current = previous }
        OverlayTheme.current = OverlayTheme(
            toastShowsGlyph: true,
            toastHorizontalMargin: 16,
            toastFillsWidth: true,
            toastLineHeightMultiple: 1.25,
            toastContentInsets: UIEdgeInsets(top: 20, left: 16, bottom: 15, right: 16),
            toastGlyphTint: .white,
            toastFontSize: 15,
            toastFontWeight: .regular
        )
        let capsule = ToastCapsule(toast: Toast(message: String(repeating: "wrapped message ", count: 3))) {}

        let size = capsule.fittingSize(maxWidth: 362)

        #expect(size.width == 362)
        #expect(size.height >= 2 * 22.5 + 35 - 3)
    }

    @Test func aLongToastWrapsInsideTheWidth() {
        let capsule = ToastCapsule(toast: Toast(message: String(repeating: "long message ", count: 12))) {}

        let size = capsule.fittingSize(maxWidth: 320)

        #expect(size.width <= 320)
        #expect(size.height > 44)
    }
}
