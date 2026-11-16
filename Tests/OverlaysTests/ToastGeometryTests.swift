import CoreGraphics
import Testing
import UIKit
@testable import Overlays

@MainActor
struct ToastGeometryTests {

    private static let windowSize = CGSize(width: 393, height: 852)
    private static let horizontalPadding: CGFloat = 16

    @Test(arguments: [ToastPlacement.top, .bottom])
    func aToastIsACompactPill(placement: ToastPlacement) async throws {
        let (window, stack) = makeStack(placement: placement)
        defer { window.isHidden = true }

        stack.update(with: [
            Toast(message: "Please fill in the required fields.", style: .error, placement: placement, duration: 0)
        ])
        try await Task.sleep(for: .milliseconds(600))
        forceLayout(window)

        let frames = stack.capsuleFrames(in: stack)
        #expect(frames.count == 1)
        guard let frame = frames.first else { return }

        #expect(frame.width > 0, "frame \(frame)")
        #expect(
            frame.width <= Self.windowSize.width - 2 * Self.horizontalPadding,
            "frame \(frame)"
        )
        #expect(frame.height > 0, "frame \(frame)")
        #expect(frame.height <= 120, "frame \(frame)")
        #expect(frame.minX >= 0, "frame \(frame)")
        #expect(frame.maxX <= Self.windowSize.width, "frame \(frame)")
        #expect(frame.minY >= 0, "frame \(frame)")
        #expect(frame.maxY <= Self.windowSize.height, "frame \(frame)")
        #expect(abs(frame.midX - Self.windowSize.width / 2) <= 1, "frame \(frame)")
    }

    @Test(arguments: [ToastPlacement.top, .bottom])
    func stackedToastsOverlapInDepth(placement: ToastPlacement) async throws {
        let (window, stack) = makeStack(placement: placement)
        defer { window.isHidden = true }

        stack.update(with: (1...3).map {
            Toast(message: "Toast \($0)", placement: placement, duration: 0)
        })
        try await Task.sleep(for: .milliseconds(600))
        forceLayout(window)

        let frames = stack.capsuleFrames(in: stack).sorted {
            placement == .top ? $0.minY < $1.minY : $0.maxY > $1.maxY
        }
        #expect(frames.count == 3)
        guard frames.count == 3 else { return }

        for frame in frames {
            #expect(frame.width > 0, "frame \(frame)")
            #expect(
                frame.width <= Self.windowSize.width - 2 * Self.horizontalPadding,
                "frame \(frame)"
            )
            #expect(frame.height > 0, "frame \(frame)")
            #expect(frame.height <= 60, "frame \(frame)")
            #expect(abs(frame.midX - Self.windowSize.width / 2) <= 1, "frame \(frame)")
            #expect(frame.minY >= 0, "frame \(frame)")
            #expect(frame.maxY <= Self.windowSize.height, "frame \(frame)")
        }

        #expect(frames[0].height > frames[1].height, "\(frames)")
        #expect(frames[1].height > frames[2].height, "\(frames)")

        if placement == .top {
            #expect(frames[1].minY < frames[0].maxY, "\(frames)")
            #expect(frames[2].minY < frames[1].maxY, "\(frames)")
            let firstStep = frames[1].minY - frames[0].minY
            let secondStep = frames[2].minY - frames[1].minY
            #expect(abs(firstStep - secondStep) <= 1, "steps \(firstStep) and \(secondStep)")
            #expect(firstStep < frames[0].height, "\(frames)")
        } else {
            #expect(frames[1].maxY > frames[0].minY, "\(frames)")
            #expect(frames[2].maxY > frames[1].minY, "\(frames)")
            let firstStep = frames[0].maxY - frames[1].maxY
            let secondStep = frames[1].maxY - frames[2].maxY
            #expect(abs(firstStep - secondStep) <= 1, "steps \(firstStep) and \(secondStep)")
            #expect(firstStep < frames[0].height, "\(frames)")
        }
    }

    @Test func aTouchReachesTheToastNotTheStackBehindIt() async throws {
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.windowSize))
        let root = UIViewController()
        window.rootViewController = root
        window.isHidden = false

        let store = ToastStore()
        let host = ToastHost(store: store)
        root.view.addSubviews(host)
        host.pinEdgesToSuperview()
        forceLayout(window)

        store.show("Touch me", duration: 0)
        try await Task.sleep(for: .milliseconds(600))
        forceLayout(window)

        let stacks = host.subviews.compactMap { $0 as? ToastStackView }
        let topStack = try #require(stacks.first { $0.placement == .top })
        let bottomStack = try #require(stacks.first { $0.placement == .bottom })
        let frame = try #require(topStack.capsuleFrames(in: host).first)
        let center = CGPoint(x: frame.midX, y: frame.midY)

        #expect(topStack.point(inside: center, with: nil))
        #expect(!bottomStack.point(inside: center, with: nil))
        let hit = host.hitTest(center, with: nil)
        #expect(hit is ToastCapsule, "hit \(String(describing: hit))")
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

    private func forceLayout(_ window: UIWindow) {
        window.setNeedsLayout()
        window.layoutIfNeeded()
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
    }
}
