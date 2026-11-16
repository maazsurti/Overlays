import CoreGraphics
import Testing
import UIKit
@testable import Overlays

/// A drag moves a toast without touching its contents. The pill keeps the size
/// its message fits in for the whole gesture and after it, wherever the pill
/// travels, so the message never re-wraps or truncates.
@MainActor
struct ToastDragStabilityTests {

    private static let windowSize = CGSize(width: 393, height: 852)
    private static let topSafeArea: CGFloat = 62
    private static let horizontalPadding: CGFloat = 16
    /// Long enough to wrap onto two lines at the front capsule's width.
    private static let message = "Wallet top-ups aren't available in the app yet."

    /// A capsule dragged into the top safe area is still the pill it was: its
    /// message area keeps the height its two lines need.
    @Test func aDragIntoTheTopSafeAreaKeepsBothLinesOfTheMessage() async throws {
        let (window, stack) = makeStack(placement: .top, topSafeArea: Self.topSafeArea)
        defer { window.isHidden = true }

        stack.update(with: [Toast(message: Self.message, placement: .top, duration: 0)])
        try await Task.sleep(for: .milliseconds(700))
        forceLayout(window)

        let capsule = try #require(frontCapsule(in: stack))
        let rest = try #require(geometry(of: capsule), "the capsule has no message area")
        let fitted = fittingSize(of: capsule, in: stack)
        #expect(rest.messageFrame.height > 30, "the message did not wrap: \(rest)")

        capsule.onDragBegan?()
        for translation in [CGFloat(-20), -45, -60, -75] {
            capsule.onDragChanged?(translation)
            forceLayout(window)

            let dragged = try #require(geometry(of: capsule))
            #expect(
                abs(dragged.messageHeight - rest.messageHeight) <= 0.5,
                """
                the message area is \(dragged.messageHeight) tall at \(translation)pt, \
                not \(rest.messageHeight); label \(dragged.messageFrame) against \(rest.messageFrame), \
                capsule bounds \(capsule.bounds), margins \(capsule.layoutMargins)
                """
            )
            #expect(
                dragged.messageFrame == rest.messageFrame,
                """
                the message moved at \(translation)pt: \(dragged.messageFrame) against \
                \(rest.messageFrame), capsule bounds \(capsule.bounds), margins \(capsule.layoutMargins)
                """
            )
            #expect(
                abs(capsule.bounds.height - fitted.height) <= 1,
                "the capsule is \(capsule.bounds.height) tall at \(translation)pt, not \(fitted.height)"
            )
        }

        capsule.onDragEnded?(-75, 0)
        try await Task.sleep(for: .milliseconds(600))
        forceLayout(window)

        let settled = try #require(geometry(of: capsule))
        #expect(
            settled.messageFrame == rest.messageFrame,
            "the message settled at \(settled.messageFrame) against \(rest.messageFrame)"
        )
    }

    @Test func aDragDoesNotResizeTheCapsule() async throws {
        let (window, stack) = makeStack(placement: .top, topSafeArea: 0)
        defer { window.isHidden = true }

        stack.update(with: [
            Toast(message: Self.message, placement: .top, duration: 0),
            Toast(message: Self.message, placement: .top, duration: 0),
        ])
        try await Task.sleep(for: .milliseconds(700))
        forceLayout(window)

        let front = try #require(frontCapsule(in: stack))
        let fitted = fittingSize(of: front, in: stack)
        let rest = try #require(geometry(of: front))

        front.onDragBegan?()
        for translation in [CGFloat(10), 25, 35] {
            front.onDragChanged?(translation)
            forceLayout(window)

            #expect(
                abs(front.bounds.height - fitted.height) <= 1,
                "the capsule is \(front.bounds.height) tall at \(translation)pt, not \(fitted.height)"
            )
            #expect(
                geometry(of: front)?.messageFrame == rest.messageFrame,
                "the message moved at \(translation)pt: \(String(describing: geometry(of: front)?.messageFrame))"
            )
        }

        front.onDragEnded?(35, 0)
        for delay in [16, 80, 160] {
            try await Task.sleep(for: .milliseconds(delay))
            forceLayout(window)

            #expect(
                abs(front.bounds.height - fitted.height) <= 1,
                "the capsule is \(front.bounds.height) tall \(delay)ms into the spring back, not \(fitted.height)"
            )
            #expect(
                geometry(of: front)?.messageFrame == rest.messageFrame,
                "the message moved \(delay)ms into the spring back"
            )
        }
    }

    @Test func aDragThatDismissesDoesNotResizeTheCapsule() async throws {
        let (window, stack) = makeStack(placement: .top, topSafeArea: 0)
        defer { window.isHidden = true }

        stack.update(with: [Toast(message: Self.message, placement: .top, duration: 0)])
        try await Task.sleep(for: .milliseconds(700))
        forceLayout(window)

        let capsule = try #require(stack.subviews.compactMap { $0 as? ToastCapsule }.first)
        let fitted = fittingSize(of: capsule, in: stack)
        let rest = try #require(geometry(of: capsule))

        capsule.onDragBegan?()
        for translation in [CGFloat(20), 70, 120] {
            capsule.onDragChanged?(translation)
            forceLayout(window)

            #expect(
                abs(capsule.bounds.height - fitted.height) <= 1,
                "the capsule is \(capsule.bounds.height) tall at \(translation)pt, not \(fitted.height)"
            )
            #expect(
                geometry(of: capsule)?.messageFrame == rest.messageFrame,
                "the message moved at \(translation)pt"
            )
        }

        capsule.onDragEnded?(120, 0)
        try await Task.sleep(for: .milliseconds(16))
        forceLayout(window)

        #expect(
            abs(capsule.bounds.height - fitted.height) <= 1,
            "the capsule is \(capsule.bounds.height) tall as it leaves, not \(fitted.height)"
        )
    }

    // MARK: - Helpers

    /// The message area's height and the label's frame, as the pill lays them out.
    private struct Geometry: Equatable, CustomStringConvertible {
        let contentHeight: CGFloat
        let messageFrame: CGRect
        let messageHeight: CGFloat

        var description: String {
            "content \(contentHeight) tall, message \(messageFrame)"
        }
    }

    private func geometry(of capsule: ToastCapsule) -> Geometry? {
        guard
            let content = capsule.subviews.compactMap({ $0 as? UIStackView }).first,
            let label = content.arrangedSubviews.last
        else {
            return nil
        }
        return Geometry(
            contentHeight: content.frame.height,
            messageFrame: label.frame,
            messageHeight: label.frame.height
        )
    }

    private func makeStack(placement: ToastPlacement, topSafeArea: CGFloat) -> (UIWindow, ToastStackView) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.windowSize))
        let root = UIViewController()
        root.additionalSafeAreaInsets = UIEdgeInsets(top: topSafeArea, left: 0, bottom: 0, right: 0)
        window.rootViewController = root
        window.isHidden = false

        let stack = ToastStackView(placement: placement)
        root.view.addSubviews(stack)
        stack.pinEdgesToSuperview()
        forceLayout(window)

        return (window, stack)
    }

    /// The capsule nearest the stack's edge, which is the one a touch reaches.
    private func frontCapsule(in stack: ToastStackView) -> ToastCapsule? {
        let capsules = stack.subviews.compactMap { $0 as? ToastCapsule }
        return stack.placement == .top
            ? capsules.min { $0.center.y < $1.center.y }
            : capsules.max { $0.center.y < $1.center.y }
    }

    private func fittingSize(of capsule: ToastCapsule, in stack: ToastStackView) -> CGSize {
        capsule.fittingSize(maxWidth: Self.windowSize.width - 2 * Self.horizontalPadding)
    }

    private func forceLayout(_ window: UIWindow) {
        window.setNeedsLayout()
        window.layoutIfNeeded()
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
    }
}
