//
//  OverlayWindowPresenter.swift
//

import UIKit

/// Base level for app-managed overlay windows (safety ribbon, custom overlays,
/// toasts). Sheets and covers live in the main window (level 0), so this keeps
/// overlays above app content while staying far below the keyboard window, so a
/// full-screen transparent window never renders on top of the keyboard.
enum OverlayWindowLevel {
    static let app: UIWindow.Level = UIWindow.Level(rawValue: 50)
}

/// Forces the app's chosen language direction onto an overlay window. Overlay
/// windows are siblings of the app's window, so they don't inherit its
/// direction: this is the UIKit stand-in for the `.supportRTL()` the SwiftUI
/// overlay hosts applied — and it reads the same `isArabic` source they did.
@MainActor
enum OverlayDirection {
    static func apply(to window: UIWindow?) {
        window?.semanticContentAttribute = OverlayTheme.current.isRightToLeft() ? .forceRightToLeft : .forceLeftToRight
    }
}

/// Presents one view in its own window above the app.
///
/// The window is created on the first `present` and re-used while an overlay is
/// up — a second `present` replaces the content in place, with no extra fade.
/// `dismiss()` fades the window out and tears it down, so the next overlay
/// fades back in.
///
/// Content is pinned to the window's bounds: the window, not the safe area, is
/// the coordinate space, which matches how the SwiftUI overlay hosts laid out.
@MainActor
public final class OverlayWindowPresenter {
    private var window: OverlayWindow?
    private var windowScene: UIWindowScene?

    public init() {}

    /// Wires the presenter onto a scene's windows. Overlays presented before
    /// this is called are dropped, exactly as they were when the presenter
    /// looked the scene up for itself.
    public func attach(to windowScene: UIWindowScene) {
        self.windowScene = windowScene
    }

    public func present(_ content: UIView, allowsPassthrough: Bool) {
        guard let windowScene else { return }

        let isNewWindow = window == nil
        let overlayWindow: OverlayWindow
        let host: OverlayHostViewController

        if let existing = window, let existingHost = existing.rootViewController as? OverlayHostViewController {
            overlayWindow = existing
            host = existingHost
        } else {
            overlayWindow = OverlayWindow(windowScene: windowScene)
            overlayWindow.backgroundColor = .clear
            overlayWindow.windowLevel = OverlayWindowLevel.app
            host = OverlayHostViewController()
            overlayWindow.rootViewController = host
            window = overlayWindow
        }

        overlayWindow.allowsPassthrough = allowsPassthrough
        OverlayDirection.apply(to: overlayWindow)
        host.setContent(content)
        overlayWindow.isHidden = false

        if isNewWindow {
            host.view.alpha = 0
            UIView.animate(withDuration: 0.25) {
                host.view.alpha = 1
            }
        }
    }

    public func dismiss() {
        guard let window else { return }
        self.window = nil

        UIView.animate(withDuration: 0.2) {
            window.rootViewController?.view.alpha = 0
        } completion: { _ in
            window.isHidden = true
            window.rootViewController = nil
        }
    }
}

/// Root view controller for an overlay window: hosts one content view, pinned
/// to the window's bounds.
final class OverlayHostViewController: UIViewController {
    private var content: UIView?

    func setContent(_ content: UIView) {
        guard self.content !== content else { return }
        self.content?.removeFromSuperview()
        self.content = content

        view.backgroundColor = .clear
        view.addSubviews(content)
        content.pinEdgesToSuperview()
    }
}

/// A window that can hand every touch back to the app below it. Passthrough is
/// all-or-nothing — the whole window is inert, not just the space around the
/// overlay — which is what the SwiftUI overlay window did.
private final class OverlayWindow: UIWindow {
    var allowsPassthrough = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !allowsPassthrough else { return nil }
        return super.hitTest(point, with: event)
    }
}
