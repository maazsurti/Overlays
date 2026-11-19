//
//  ToastScrimView.swift
//

import UIKit

/// The gradient behind a toast stack: the theme's scrim colour at its opacity on
/// the screen edge the stack meets, clear at the other end of its height. It
/// never takes a touch — the toast window hands every touch outside a capsule to
/// the app.
@MainActor
final class ToastScrimView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradient: CAGradientLayer { layer as! CAGradientLayer }

    /// The screen edge the scrim is opaque on.
    let edge: ToastScrimEdge

    /// The opacity the gradient is holding: the theme's normal or error value.
    private(set) var strength: CGFloat = 0

    /// The blur under the gradient, masked the same way and on screen only while
    /// the scrim is and the theme asks for one.
    private let blurView = UIVisualEffectView(effect: nil)
    private let blurMask = CAGradientLayer()
    private var blurStyle: UIBlurEffect.Style?
    private var isShown = false

    init(edge: ToastScrimEdge) {
        self.edge = edge
        super.init(frame: .zero)

        isUserInteractionEnabled = false
        isAccessibilityElement = false
        backgroundColor = .clear
        alpha = 0

        // The colours run clear to opaque, so the points run away from the edge.
        gradient.startPoint = CGPoint(x: 0.5, y: edge == .top ? 1 : 0)
        gradient.endPoint = CGPoint(x: 0.5, y: edge == .top ? 0 : 1)

        blurView.isUserInteractionEnabled = false
        blurView.isAccessibilityElement = false
        blurView.isHidden = true
        blurMask.startPoint = gradient.startPoint
        blurMask.endPoint = gradient.endPoint
        blurMask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        blurView.layer.mask = blurMask
        addSubview(blurView)
        blurView.pinEdgesToSuperview()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceTransparencyDidChange),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )
        applyTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blurMask.frame = bounds
    }

    /// Takes the theme's scrim colour, blur and the opacity it is holding.
    func applyTheme() {
        gradient.colors = colors(strength)
        updateBlur()
    }

    /// Sets the gradient's strongest opacity when the toasts at this edge turn
    /// into an error, or stop being one.
    func setStrength(_ opacity: CGFloat, duration: TimeInterval) {
        let target = min(max(opacity, 0), 1)
        guard target != strength else { return }
        strength = target

        let next = colors(target)
        guard duration > 0 else {
            gradient.colors = next
            return
        }

        let fade = CABasicAnimation(keyPath: "colors")
        fade.fromValue = gradient.colors
        fade.toValue = next
        fade.duration = duration
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)
        gradient.colors = next
        gradient.add(fade, forKey: "colors")
    }

    /// Fades the scrim in or out. A `duration` of 0 changes it at once, which is
    /// what Reduce Motion asks for.
    func fade(to visible: Bool, duration: TimeInterval) {
        isShown = visible
        // The blur arrives with the tint and leaves with it, so it is shown now
        // and put away once the fade out has finished.
        if visible { updateBlur() }

        let change = { self.alpha = visible ? 1 : 0 }
        guard duration > 0 else {
            change()
            updateBlur()
            return
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]
        ) {
            change()
        } completion: { _ in
            self.updateBlur()
        }
    }

    private func colors(_ opacity: CGFloat) -> [CGColor] {
        let theme = OverlayTheme.current
        return [
            theme.toastScrimColor.withAlphaComponent(0).cgColor,
            theme.toastScrimColor.withAlphaComponent(opacity).cgColor,
        ]
    }

    private func updateBlur() {
        let style = OverlayTheme.current.toastScrimBlurStyle
        if style != blurStyle {
            blurStyle = style
            blurView.effect = style.map { UIBlurEffect(style: $0) }
        }
        blurView.isHidden = !ToastScrimView.showsBlur(
            style: style,
            isShown: isShown,
            reduceTransparency: UIAccessibility.isReduceTransparencyEnabled
        )
    }

    /// Whether the blur belongs on screen: only with a style the theme asked
    /// for, while the scrim is up, and never over Reduce Transparency.
    static func showsBlur(
        style: UIBlurEffect.Style?,
        isShown: Bool,
        reduceTransparency: Bool
    ) -> Bool {
        isShown && style != nil && !reduceTransparency
    }

    @objc private func reduceTransparencyDidChange() {
        updateBlur()
    }
}
