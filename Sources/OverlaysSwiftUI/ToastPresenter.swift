import SwiftUI

#if canImport(UIKit)
import UIKit

@MainActor
final class ToastPresenter {
    private var window: ToastWindow?

    func attach(store: ToastStore) {
        guard window == nil, let scene = activeWindowScene() else { return }

        let toastWindow = ToastWindow(windowScene: scene)
        let host = UIHostingController(
            rootView: ToastHost(store: store) { [weak toastWindow] frames in
                toastWindow?.interactiveFrames = frames
            }.supportRTL()
        )
        host.view.backgroundColor = .clear
        toastWindow.rootViewController = host
        toastWindow.backgroundColor = .clear
        toastWindow.windowLevel = OverlayWindowLevel.app + 1
        toastWindow.isHidden = false
        window = toastWindow
    }

    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundInactive }
    }
}

private final class ToastWindow: UIWindow {
    var interactiveFrames: [CGRect] = []

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard interactiveFrames.contains(where: { $0.contains(point) }) else { return nil }
        return super.hitTest(point, with: event)
    }
}
#else
@MainActor
final class ToastPresenter {
    func attach(store: ToastStore) {}
}
#endif
