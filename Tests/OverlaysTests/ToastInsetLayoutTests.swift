import CoreGraphics
import Testing
import UIKit
@testable import Overlays

/// A bottom toast is placed against the clearance that is current when it is
/// placed, and a clearance that arrives later reaches the pill once its
/// entrance has finished — never by restarting that entrance.
@MainActor
struct ToastInsetLayoutTests {

    private static let windowSize = CGSize(width: 393, height: 852)
    /// A dock standing 54pt proud of the bottom safe area.
    private static let dock: CGFloat = 54

    @Test func aBottomToastEntersAgainstTheClearanceHeldWhenItArrives() async throws {
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.windowSize))
        let root = UIViewController()
        window.rootViewController = root
        window.isHidden = false
        defer { window.isHidden = true }

        let store = ToastStore()
        let host = ToastHost(store: store)
        root.view.addSubviews(host)
        host.pinEdgesToSuperview()
        forceLayout(window)

        // The dock publishes its height before the toast appears, as the main
        // tab shell does for its first bottom toast.
        store.bottomChromeInset = Self.dock
        store.show("Saved", placement: .bottom, duration: 0)

        // The host renders on the turn after the store changes, and sets the
        // pill's slot in that turn while the entrance is still running.
        try await Task.sleep(for: .milliseconds(80))

        let stack = try #require(bottomStack(in: host))
        let capsule = try #require(stack.subviews.compactMap { $0 as? ToastCapsule }.first)
        let expected = bottomCenter(for: capsule, in: stack, chromeInset: Self.dock)
        let withoutTheDock = bottomCenter(for: capsule, in: stack, chromeInset: 0)

        #expect(abs(expected - withoutTheDock) > 1, "the dock does not change the slot")
        #expect(
            abs(capsule.center.y - expected) <= 0.5,
            """
            the pill's first slot is \(capsule.center.y), not \(expected); \
            it was placed against the clearance from before the dock appeared
            """
        )

        try await Task.sleep(for: .milliseconds(600))
        forceLayout(window)

        #expect(
            abs(capsule.center.y - expected) <= 0.5,
            "the pill settled at \(capsule.center.y), not \(expected)"
        )
    }

    @Test func aClearanceThatArrivesDuringTheEntranceIsAppliedOnceAfterIt() async throws {
        let (window, stack) = makeStack(placement: .bottom)
        defer { window.isHidden = true }

        stack.update(with: [Toast(message: "Saved", placement: .bottom, duration: 0)])
        let capsule = try #require(stack.subviews.compactMap { $0 as? ToastCapsule }.first)
        let entered = capsule.center.y
        #expect(
            abs(entered - bottomCenter(for: capsule, in: stack, chromeInset: 0)) <= 0.5,
            "the pill entered at \(entered), not above the safe area alone"
        )

        // The dock appears while the entrance spring is still in flight.
        stack.bottomInset = Self.dock
        #expect(
            abs(capsule.center.y - entered) <= 0.5,
            "the new clearance moved the pill off its entrance at \(capsule.center.y)"
        )

        // The layout it asks for cannot run under the entrance; it waits.
        forceLayout(window)
        #expect(
            abs(capsule.center.y - entered) <= 0.5,
            "the pill left its entrance mid-flight at \(capsule.center.y)"
        )

        try await Task.sleep(for: .milliseconds(600))
        forceLayout(window)

        let expected = bottomCenter(for: capsule, in: stack, chromeInset: Self.dock)
        #expect(
            abs(capsule.center.y - expected) <= 0.5,
            "the pill stayed at \(capsule.center.y), not the \(expected) its new clearance gives it"
        )
        #expect(stack.subviews.compactMap { $0 as? ToastCapsule }.count == 1)

        // The clearance has been applied; another pass has nothing left to move.
        forceLayout(window)
        #expect(
            abs(capsule.center.y - expected) <= 0.5,
            "a later layout moved the pill again, to \(capsule.center.y)"
        )
    }

    // MARK: - Helpers

    private func makeStack(placement: ToastPlacement) -> (UIWindow, ToastStackView) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.windowSize))
        let root = UIViewController()
        window.rootViewController = root
        window.isHidden = false

        let stack = ToastStackView(placement: placement)
        root.view.addSubviews(stack)
        stack.pinEdgesToSuperview()
        forceLayout(window)

        return (window, stack)
    }

    private func bottomStack(in host: ToastHost) -> ToastStackView? {
        host.subviews
            .compactMap { $0 as? ToastStackView }
            .first { $0.placement == .bottom }
    }

    /// The centre the front capsule's slot puts it at, from the same edge the
    /// stack measures against.
    private func bottomCenter(
        for capsule: ToastCapsule,
        in stack: ToastStackView,
        chromeInset: CGFloat
    ) -> CGFloat {
        let edge = ToastLayout.bottomEdgeY(
            height: stack.bounds.height,
            safeAreaBottom: stack.safeAreaInsets.bottom,
            chromeInset: chromeInset
        )
        return edge - capsule.bounds.height / 2
    }

    private func forceLayout(_ window: UIWindow) {
        window.setNeedsLayout()
        window.layoutIfNeeded()
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
    }
}
