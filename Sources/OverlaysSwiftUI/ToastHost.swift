import SwiftUI
import UIKit

/// The toast window's content: one stack per placement, the gradient each
/// placement's toasts sit on, and the frames of the capsules it is showing.
struct ToastHost: View {
    private let store: ToastStore
    private let onFramesChange: ([CGRect]) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var stackFrames: [ToastPlacement: CGRect] = [:]
    @State private var notified: Set<UUID> = []
    private let haptic = UINotificationFeedbackGenerator()

    init(store: ToastStore, onFramesChange: @escaping ([CGRect]) -> Void = { _ in }) {
        self.store = store
        self.onFramesChange = onFramesChange
    }

    private var topToasts: [Toast] {
        store.toasts.filter { $0.placement == .top }
    }

    private var bottomToasts: [Toast] {
        store.toasts.filter { $0.placement == .bottom }
    }

    var body: some View {

        GeometryReader { geometry in
            ZStack {
                scrim(height: geometry.size.height, origin: origin(of: geometry), placement: .top)
                scrim(height: geometry.size.height, origin: origin(of: geometry), placement: .bottom)
                ToastStackView(
                    placement: .top,
                    items: topToasts,
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
        .onPreferenceChange(ToastStackFramesKey.self) { stackFrames = $0 }
        .onChange(of: store.toasts) { _, toasts in fireHaptics(for: toasts) }
        .onAppear { haptic.prepare() }
    }

    private func origin(of geometry: GeometryProxy) -> CGFloat {
        geometry.frame(in: .global).minY
    }

    /// How far the scrim would reach to clear the capsules at its edge, before
    /// the theme's minimum and the host's height are applied.
    private func naturalHeight(height: CGFloat, origin: CGFloat, placement: ToastPlacement) -> CGFloat {
        let toasts = placement == .top ? topToasts : bottomToasts
        guard let stack = stackFrames[placement], !toasts.isEmpty else { return 0 }
        let padding = OverlayTheme.current.toastScrimPadding
        return placement == .top
            ? stack.maxY - origin + padding
            : height - (stack.minY - origin) + padding
    }

    /// The theme's scrim, anchored to the edge its placement meets and out only
    /// while a toast of that placement is on screen.
    @ViewBuilder
    private func scrim(height: CGFloat, origin: CGFloat, placement: ToastPlacement) -> some View {
        let theme = OverlayTheme.current
        let toasts = placement == .top ? topToasts : bottomToasts
        let minimum = height * theme.toastScrimHeightFraction
        let extent = min(max(naturalHeight(height: height, origin: origin, placement: placement), minimum), height)
        let strong = toasts.contains { $0.style == .error }
            ? theme.toastScrimErrorOpacity
            : theme.toastScrimOpacity
        let gradient = LinearGradient(
            colors: [
                theme.toastScrimColor.opacity(0),
                theme.toastScrimColor.opacity(min(max(strong, 0), 1)),
            ],
            startPoint: placement == .top ? .bottom : .top,
            endPoint: placement == .top ? .top : .bottom
        )

        if !toasts.isEmpty {
            gradient
                .background {
                    if let style = theme.toastScrimBlurStyle, !reduceTransparency {
                        ToastScrimBlur(style: style).mask(gradient)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: extent)
                .frame(maxHeight: .infinity, alignment: placement == .top ? .top : .bottom)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    /// One notification haptic per error or warning toast that has just arrived,
    /// never for a re-render of a toast already on screen.
    private func fireHaptics(for toasts: [Toast]) {
        let arrivals = toasts.filter { !notified.contains($0.id) }
        notified = Set(toasts.map(\.id))
        guard OverlayTheme.current.toastHaptics else { return }

        for toast in arrivals {
            switch toast.style {
            case .error:
                haptic.notificationOccurred(.error)
            case .warning:
                haptic.notificationOccurred(.warning)
            case .info, .success:
                continue
            }
            haptic.prepare()
        }
    }
}
