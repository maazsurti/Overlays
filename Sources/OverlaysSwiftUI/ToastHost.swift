import SwiftUI

/// The toast window's content: one stack per placement, the gradient the bottom
/// toasts sit on, and the frames of the capsules it is showing.
struct ToastHost: View {
    private let store: ToastStore
    private let onFramesChange: ([CGRect]) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: ToastStore, onFramesChange: @escaping ([CGRect]) -> Void = { _ in }) {
        self.store = store
        self.onFramesChange = onFramesChange
    }

    private var bottomToasts: [Toast] {
        store.toasts.filter { $0.placement == .bottom }
    }

    var body: some View {

        GeometryReader { geometry in
            ZStack {
                scrim(height: geometry.size.height)
                ToastStackView(
                    placement: .top,
                    items: store.toasts.filter { $0.placement == .top },
                    onDismiss: { store.dismiss($0) }
                )
                ToastStackView(
                    placement: .bottom,
                    items: bottomToasts,
                    onDismiss: { store.dismiss($0) },
                    bottomInset: store.bottomChromeInset
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(
                reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.86),
                value: store.toasts
            )
        }
        .onPreferenceChange(ToastFramesKey.self) { onFramesChange($0) }
    }

    /// The theme's scrim, anchored to the bottom edge and up only while a bottom
    /// toast is on screen.
    @ViewBuilder
    private func scrim(height: CGFloat) -> some View {
        let theme = OverlayTheme.current
        if !bottomToasts.isEmpty {
            LinearGradient(
                colors: [
                    theme.toastScrimColor.opacity(0),
                    theme.toastScrimColor.opacity(min(max(theme.toastScrimOpacity, 0), 1)),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: height * theme.toastScrimHeightFraction)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }
}
