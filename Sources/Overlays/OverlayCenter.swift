//
//  OverlayCenter.swift
//

import Observation
import UIKit

/// The app's overlay hub: toasts, the shared custom-overlay slot (loading
/// cards, debug banners), and standardised modal alerts. A singleton, because
/// overlays are triggered from anywhere and land in windows of their own.
///
/// The app attaches it to the active window scene once, at launch:
///
///     OverlayCenter.shared.attach(to: windowScene)
///
/// After that, every preset is a method call — usually through the `AppRouter`
/// / `Navigator` helpers in `OverlayRouting.swift`.
@MainActor
@Observable
public final class OverlayCenter {
    public static let shared = OverlayCenter()

    public var toastStore = ToastStore()

    /// The overlay currently occupying the shared slot, or `nil` when there is
    /// none. Single slot: showing a second overlay replaces the first.
    private(set) var overlay: CustomOverlay?

    private let overlayPresenter = OverlayWindowPresenter()
    private let toastPresenter = ToastPresenter()

    private init() {}

    /// Wires both overlay windows onto `windowScene`. The app calls this once,
    /// after its main window exists.
    public func attach(to windowScene: UIWindowScene) {
        overlayPresenter.attach(to: windowScene)
        toastPresenter.attach(store: toastStore, to: windowScene)
    }

    // MARK: - Toasts

    public func showToast(
        _ message: String,
        style: ToastStyle = .info,
        placement: ToastPlacement = .top,
        duration: TimeInterval = 2.5
    ) {
        toastStore.show(message, style: style, placement: placement, duration: duration)
    }

    public func dismissToasts() {
        toastStore.dismissAll()
    }

    // MARK: - Custom overlay

    public func showOverlay(
        allowsPassthrough: Bool = false,
        content: @escaping @MainActor (_ dismiss: @escaping @MainActor () -> Void) -> UIView
    ) {
        let overlay = CustomOverlay(allowsPassthrough: allowsPassthrough, content: content)
        self.overlay = overlay
        present(overlay)
    }

    public func dismissOverlay() {
        overlay = nil
        overlayPresenter.dismiss()
    }

    // MARK: - Loading

    /// Dims the screen behind the app's loading card: the brand ring spinning around the
    /// dumbbell, with an optional message. Taps are blocked until the caller dismisses it.
    public func showLoading(message: String? = nil) {
        showOverlay { _ in
            LoadingOverlayView(message: message)
        }
    }

    public func dismissLoading() {
        dismissOverlay()
    }

    // MARK: - Modal alerts

    /// Presents a standardised `ModalAlert` in the shared custom-overlay slot,
    /// rendered by `ModalAlertView`. Each button runs its action, then dismisses.
    public func showModalAlert(_ alert: ModalAlert) {
        showOverlay { dismiss in
            ModalAlertView(alert: alert, dismiss: dismiss)
        }
    }

    public func dismissModalAlert() {
        dismissOverlay()
    }

    // MARK: - Private

    private func present(_ overlay: CustomOverlay) {
        overlayPresenter.present(
            overlay.content(dismiss: { [weak self] in self?.dismissOverlay() }),
            allowsPassthrough: overlay.allowsPassthrough
        )
    }
}
