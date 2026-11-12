import SwiftUI

#if canImport(UIKit)
import UIKit

/// Base level for app-managed overlay windows (safety ribbon, custom overlays,
/// toasts). Sheets and covers live in the main window (level 0), so this keeps
/// overlays above app content while staying far below the keyboard window, so a
/// full-screen transparent window never renders on top of the keyboard.
enum OverlayWindowLevel {
    static let app: UIWindow.Level = UIWindow.Level(rawValue: 50)
}

@MainActor
public final class OverlayWindowPresenter {
    public init() {}
    private var window: OverlayWindow?

    public func present<Overlay, Content: View>(
        _ overlay: Overlay?,
        allowsPassthrough: (Overlay) -> Bool,
        @ViewBuilder content: (Overlay) -> Content
    ) {
        guard let overlay else {
            dismiss()
            return
        }

        guard let scene = activeWindowScene() else { return }

        let hostingController = UIHostingController(rootView: AnyView(content(overlay).supportRTL()))
        hostingController.view.backgroundColor = .clear

        let isNewWindow = window == nil
        let overlayWindow = window ?? OverlayWindow(windowScene: scene)
        overlayWindow.allowsPassthrough = allowsPassthrough(overlay)
        overlayWindow.rootViewController = hostingController
        overlayWindow.backgroundColor = .clear
        overlayWindow.windowLevel = OverlayWindowLevel.app
        overlayWindow.isHidden = false
        window = overlayWindow

        if isNewWindow {
            hostingController.view.alpha = 0
            UIView.animate(withDuration: 0.25) {
                hostingController.view.alpha = 1
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

    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundInactive }
    }
}

private final class OverlayWindow: UIWindow {
    var allowsPassthrough = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !allowsPassthrough else { return nil }
        return super.hitTest(point, with: event)
    }
}
#else
@MainActor
public final class OverlayWindowPresenter {
    public init() {}
    public func present<Overlay, Content: View>(
        _ overlay: Overlay?,
        allowsPassthrough: (Overlay) -> Bool,
        @ViewBuilder content: (Overlay) -> Content
    ) {}

    public func dismiss() {}
}
#endif
