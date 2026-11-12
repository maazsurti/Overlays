//
//  ToastPresenter.swift
//

import UIKit

/// Mounts the toast window: a full-screen window one level above the
/// custom-overlay window, up for the app's lifetime so toasts can appear at any
/// moment. Hit testing is restricted to the capsules that are on screen, so
/// every other touch falls through to the app.
@MainActor
final class ToastPresenter {
    private var window: ToastWindow?

    func attach(store: ToastStore, to windowScene: UIWindowScene) {
        guard window == nil else { return }

        let toastWindow = ToastWindow(windowScene: windowScene)
        let host = ToastHost(store: store) { [weak toastWindow] frames in
            toastWindow?.interactiveFrames = frames
        }
        let hostController = OverlayHostViewController()
        hostController.setContent(host)

        toastWindow.rootViewController = hostController
        toastWindow.backgroundColor = .clear
        toastWindow.windowLevel = OverlayWindowLevel.app + 1
        OverlayDirection.apply(to: toastWindow)
        toastWindow.isHidden = false
        window = toastWindow
    }
}

/// A window that only takes the touches that land on a toast capsule.
private final class ToastWindow: UIWindow {
    var interactiveFrames: [CGRect] = []

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard interactiveFrames.contains(where: { $0.contains(point) }) else { return nil }
        return super.hitTest(point, with: event)
    }
}
