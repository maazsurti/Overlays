import CoreGraphics
import UIKit
import Testing
@testable import Overlays

@MainActor
struct LoadingViewTests {

    // The card says the message and, under it, the caption.
    @Test func captionRendersUnderTheMessage() {
        let card = LoadingView(message: "Saving…", caption: "Just a moment")

        let labels = textLabels(in: card)

        #expect(labels.map(\.text) == ["Saving…", "Just a moment"])
        let titleSize = labels.first?.font.pointSize ?? 0
        let captionSize = labels.last?.font.pointSize ?? 0
        #expect(captionSize < titleSize)
        #expect(labels.last?.textColor == OverlayTheme.current.secondaryText)
    }

    // The theme's caption is the default every call site inherits, and a call site's
    // own caption replaces it.
    @Test func captionFallsBackToTheTheme() {
        let original = OverlayTheme.current
        defer { OverlayTheme.current = original }
        OverlayTheme.current = OverlayTheme(loadingCaption: "Please wait")

        #expect(textLabels(in: LoadingView(message: "Saving…")).map(\.text) == ["Saving…", "Please wait"])
        #expect(textLabels(in: LoadingView(message: "Saving…", caption: "Nearly there")).map(\.text) == ["Saving…", "Nearly there"])
        #expect(textLabels(in: LoadingView(message: "Saving…", caption: "")).map(\.text) == ["Saving…"])
    }

    // The card takes the height of the lines it shows and keeps one width, so a
    // missing line cannot reshape the card.
    @Test func cardSizesToTheLinesItShows() {
        let neither = size(of: LoadingView())
        let titleOnly = size(of: LoadingView(message: "Saving…"))
        let captionOnly = size(of: LoadingView(caption: "Just a moment"))
        let both = size(of: LoadingView(message: "Saving…", caption: "Just a moment"))

        #expect(titleOnly.height > neither.height)
        #expect(captionOnly.height > neither.height)
        #expect(both.height > titleOnly.height)
        #expect(both.height > captionOnly.height)

        let widths = [neither, titleOnly, captionOnly, both].map(\.width)
        #expect(Set(widths).count == 1)
    }

    // The card is one accessibility element, so its lines are read once.
    @Test func accessibilityLabelCarriesTheText() {
        #expect(LoadingView(message: "Saving…", caption: "Just a moment").accessibilityLabel == "Saving…, Just a moment")
        #expect(LoadingView(message: "Saving…").accessibilityLabel == "Saving…")
        #expect(LoadingView(caption: "Just a moment").accessibilityLabel == "Just a moment")
        #expect(LoadingView().accessibilityLabel == OverlayTheme.current.pleaseWaitText)
    }

    private func size(of card: LoadingView) -> CGSize {
        card.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    /// Every label the card draws, in layout order.
    private func textLabels(in view: UIView) -> [UILabel] {
        view.subviews.flatMap { subview -> [UILabel] in
            if let label = subview as? UILabel { return [label] }
            return textLabels(in: subview)
        }
    }
}
