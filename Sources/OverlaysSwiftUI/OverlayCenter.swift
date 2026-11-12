import Observation
import SwiftUI

@MainActor
@Observable
public final class OverlayCenter {
    public static let shared = OverlayCenter()

    public var toastStore = ToastStore()
    public var overlay: CustomOverlay?

    private init() {}

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

    public func showOverlay<Content: View>(
        allowsPassthrough: Bool = false,
        @ViewBuilder content: @escaping @MainActor (_ dismiss: @escaping @MainActor () -> Void) -> Content
    ) {
        overlay = CustomOverlay(allowsPassthrough: allowsPassthrough, content: content)
    }

    public func dismissOverlay() {
        overlay = nil
    }

    public func showLoading(message: String? = nil) {
        showOverlay { dismiss in
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .overlay {

                    LoadingView(message: message)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: dismiss)
        }
    }

    public func dismissLoading() {
        dismissOverlay()
    }

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
}
