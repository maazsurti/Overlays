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

    @Test func aTopScrimReachesPastTheLowestCapsule() {
        let height = ToastScrimLayout.height(
            edge: .top,
            hostHeight: Self.height,
            capsuleFrames: [CGRect(x: 16, y: 90, width: 370, height: 44)],
            padding: 120,
            minimum: 100
        )

        #expect(height == CGFloat(134 + 120))
    }

    @Test func aBottomScrimStartsAboveTheHighestCapsule() {
        let height = ToastScrimLayout.height(
            edge: .bottom,
            hostHeight: Self.height,
            capsuleFrames: [CGRect(x: 16, y: 774, width: 370, height: 44)],
            padding: 120,
            minimum: 100
        )

        #expect(height == Self.height - 774 + 120)
    }

    @Test func aScrimWithNoCapsuleKeepsTheThemeMinimum() {
        for edge in [ToastScrimEdge.top, .bottom] {
            let height = ToastScrimLayout.height(
                edge: edge,
                hostHeight: Self.height,
                capsuleFrames: [],
                padding: 120,
                minimum: 100
            )

            #expect(height == 100)
        }
    }

    @Test func aScrimNeverReachesPastTheScreen() {
        for edge in [ToastScrimEdge.top, .bottom] {
            let height = ToastScrimLayout.height(
                edge: edge,
                hostHeight: Self.height,
                capsuleFrames: [CGRect(x: 0, y: 0, width: 400, height: Self.height)],
                padding: 120,
                minimum: 100
            )

            #expect(height == Self.height)
        }
    }

    @Test func theBlurLeavesUnderReduceTransparency() {
        #expect(
            ToastScrimView.showsBlur(
                style: .systemThinMaterialLight,
                isShown: true,
                reduceTransparency: false
            )
        )
        #expect(
            !ToastScrimView.showsBlur(
                style: .systemThinMaterialLight,
                isShown: true,
                reduceTransparency: true
            )
        )
        #expect(!ToastScrimView.showsBlur(style: nil, isShown: true, reduceTransparency: false))
        #expect(
            !ToastScrimView.showsBlur(
                style: .systemThinMaterialLight,
                isShown: false,
                reduceTransparency: false
            )
        )
    }

    @Test func anErrorAtTheEdgeStrengthensTheScrim() {
        #expect(
            ToastScrimLayout.opacity(for: [.info, .success], normal: 0.28, error: 0.6) == 0.28
        )
        #expect(
            ToastScrimLayout.opacity(for: [.info, .error], normal: 0.28, error: 0.6) == 0.6
        )
        #expect(
            ToastScrimLayout.opacity(for: [], normal: 0.28, error: 0.6) == 0.28
        )
    }

    @Test func theTopScrimArrivesWithATopToastAndLeavesTheBottomOneAlone() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: Self.height))
        let root = UIViewController()
        window.rootViewController = root
        window.isHidden = false

        let store = ToastStore()
        let host = ToastHost(store: store)
        root.view.addSubviews(host)
        host.pinEdgesToSuperview()
        window.layoutIfNeeded()

        let scrims = host.subviews.compactMap { $0 as? ToastScrimView }
        let topScrim = try #require(scrims.first { $0.edge == .top })
        let bottomScrim = try #require(scrims.first { $0.edge == .bottom })
        #expect(scrims.count == 2)

        store.show("Copied", placement: .top, duration: 0)
        try await Task.sleep(for: .milliseconds(600))
        window.layoutIfNeeded()

        #expect(topScrim.alpha == 1)
        #expect(bottomScrim.alpha == 0)
        #expect(topScrim.frame.minY == 0)

        let capsule = try #require(
            host.subviews.filter { $0 is ToastStackView }
                .flatMap(\.subviews)
                .compactMap { $0 as? ToastCapsule }
                .first
        )
        let capsuleFrame = capsule.convert(capsule.bounds, to: host)
        #expect(
            topScrim.frame.height
                == capsuleFrame.maxY + OverlayTheme.current.toastScrimPadding
        )

        store.dismissAll()
        try await Task.sleep(for: .milliseconds(600))

        #expect(topScrim.alpha == 0)
        #expect(bottomScrim.alpha == 0)

        window.isHidden = true
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
