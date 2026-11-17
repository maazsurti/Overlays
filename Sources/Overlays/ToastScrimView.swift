//
//  ToastScrimView.swift
//

import UIKit

/// The gradient behind the bottom toasts: the theme's scrim colour at its
/// opacity on the bottom edge, clear at the top of its height. It never takes a
/// touch — the toast window hands every touch outside a capsule to the app.
@MainActor
final class ToastScrimView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradient: CAGradientLayer { layer as! CAGradientLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        isAccessibilityElement = false
        backgroundColor = .clear
        alpha = 0

        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        applyTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    /// Takes the theme's scrim colour and bottom-edge opacity.
    func applyTheme() {
        let theme = OverlayTheme.current
        let opacity = min(max(theme.toastScrimOpacity, 0), 1)
        gradient.colors = [
            theme.toastScrimColor.withAlphaComponent(0).cgColor,
            theme.toastScrimColor.withAlphaComponent(opacity).cgColor,
        ]
    }
}
