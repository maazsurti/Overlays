import CoreGraphics
import Testing
import UIKit
@testable import Overlays

@MainActor
struct ToastLayoutTests {

    private static let height: CGFloat = 874
    private static let safeAreaBottom: CGFloat = 34
    /// The tab shell's dock: 64 pt tall, dipping 10 pt into the safe area.
    private static let dock: CGFloat = 54

    @Test func aBottomToastClearsTheDockByOneGap() {
        let edge = ToastLayout.bottomEdgeY(
            height: Self.height,
            safeAreaBottom: Self.safeAreaBottom,
            chromeInset: Self.dock
        )

        #expect(edge == Self.height - Self.safeAreaBottom - Self.dock - ToastLayout.bottomGap)
        #expect(edge == 774)
    }

    @Test func theGapAboveTheChromeDoesNotDependOnHowTallItIs() {
        for chrome in [CGFloat(0), Self.dock, 100, 260] {
            let edge = ToastLayout.bottomEdgeY(
                height: Self.height,
                safeAreaBottom: Self.safeAreaBottom,
                chromeInset: chrome
            )
            let chromeTop = Self.height - Self.safeAreaBottom - chrome

            #expect(chromeTop - edge == ToastLayout.bottomGap, "chrome \(chrome)")
        }
    }

    @Test func withNoChromeTheToastClearsTheSafeAreaEdge() {
        let edge = ToastLayout.bottomEdgeY(
            height: Self.height,
            safeAreaBottom: Self.safeAreaBottom,
            chromeInset: 0
        )

        #expect(edge == Self.height - Self.safeAreaBottom - ToastLayout.bottomGap)
        #expect(Self.height - Self.safeAreaBottom - edge == 12)
    }

    @Test func aSafeAreaTheStackCannotSeeLeavesTheEdgeAlone() {
        // A device without a bottom safe area: the toast still keeps its gap.
        let edge = ToastLayout.bottomEdgeY(height: Self.height, safeAreaBottom: 0, chromeInset: 0)

        #expect(Self.height - edge == ToastLayout.bottomGap)
    }

    @Test func theKeyboardTakesTheRoomTheDockWouldHave() {
        let keyboard: CGFloat = 336

        let edge = ToastLayout.bottomEdgeY(
            height: Self.height,
            safeAreaBottom: Self.safeAreaBottom,
            chromeInset: 0,
            keyboardInset: keyboard
        )

        #expect(Self.height - keyboard - edge == ToastLayout.bottomGap)
    }

    @Test func theTallerOfTheKeyboardAndTheDockWins() {
        let keyboard: CGFloat = 336

        let withKeyboard = ToastLayout.bottomEdgeY(
            height: Self.height,
            safeAreaBottom: Self.safeAreaBottom,
            chromeInset: Self.dock,
            keyboardInset: keyboard
        )
        let withDockAlone = ToastLayout.bottomEdgeY(
            height: Self.height,
            safeAreaBottom: Self.safeAreaBottom,
            chromeInset: Self.dock
        )

        #expect(withKeyboard < withDockAlone)
        #expect(Self.height - keyboard - withKeyboard == ToastLayout.bottomGap)
    }

    @Test func aTopToastKeepsItsPaddingUnderTheSafeArea() {
        let edge = ToastLayout.topEdgeY(safeAreaTop: 62)

        #expect(edge == 62 + ToastLayout.topPadding)
    }

    // MARK: - The scrim

    @Test func theScrimFadesInOnTheFirstBottomToast() {
        #expect(ToastScrimTransition.between(before: 0, after: 1) == .fadeIn)
        #expect(ToastScrimTransition.between(before: 0, after: 3) == .fadeIn)
    }

    @Test func theScrimFadesOutOnTheLastBottomToast() {
        #expect(ToastScrimTransition.between(before: 1, after: 0) == .fadeOut)
        #expect(ToastScrimTransition.between(before: 3, after: 0) == .fadeOut)
    }

    @Test func theScrimStaysPutWhileBottomToastsSwap() {
        #expect(ToastScrimTransition.between(before: 1, after: 1) == .none)
        #expect(ToastScrimTransition.between(before: 1, after: 2) == .none)
        #expect(ToastScrimTransition.between(before: 2, after: 1) == .none)
        #expect(ToastScrimTransition.between(before: 0, after: 0) == .none)
    }

    @Test func theScrimLeavesFasterThanItArrives() {
        #expect(ToastScrimTransition.fadeOutDuration < ToastScrimTransition.fadeInDuration)
        #expect(ToastScrimTransition.fadeOutDuration > 0)
    }

    @Test func theScrimNeverTakesATouch() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: Self.height))
        let root = UIViewController()
        window.rootViewController = root
        window.isHidden = false

        let store = ToastStore()
        let host = ToastHost(store: store)
        root.view.addSubviews(host)
        host.pinEdgesToSuperview()
        window.layoutIfNeeded()

        store.show("Added to your order", placement: .bottom, duration: 0)
        try await Task.sleep(for: .milliseconds(600))
        window.layoutIfNeeded()

        let scrim = try #require(host.subviews.first { $0 is ToastScrimView })
        #expect(scrim.isUserInteractionEnabled == false)

        // A point in the scrim, well clear of the pill, belongs to the app.
        let point = CGPoint(x: 8, y: Self.height - 8)
        #expect(scrim.hitTest(scrim.convert(point, from: host), with: nil) == nil)
        #expect(host.hitTest(point, with: nil) === host)

        window.isHidden = true
    }
}
