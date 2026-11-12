//
//  ToastCapsule.swift
//

import UIKit

/// One toast: a white rounded pill with the style's glyph and the message.
/// Dragging it past 40pt towards its own edge dismisses it; anything shorter
/// springs back.
@MainActor
final class ToastCapsule: UIView {

    private let toast: Toast
    private let onDismiss: () -> Void

    /// Called whenever the capsule stops moving, so the host can re-report the
    /// frames the toast window hit-tests against.
    var onSettled: (() -> Void)?

    private var dragOffset: CGFloat = 0

    init(toast: Toast, onDismiss: @escaping () -> Void) {
        self.toast = toast
        self.onDismiss = onDismiss
        super.init(frame: .zero)

        backgroundColor = OverlayTheme.current.surface
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = OverlayTheme.current.border.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 16)

        let glyph = ToastGlyphView(style: toast.style)
        let message = UILabel(
            text: toast.message,
            font: OverlayTheme.current.font(.medium, 14),
            color: OverlayTheme.current.text,
            numberOfLines: 0
        )
        let content = UIStackView.horizontal(spacing: 10, alignment: .center, views: [glyph, message])

        addSubviews(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])

        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            let translation = recognizer.translation(in: self).y
            dragOffset = toast.placement == .top ? min(0, translation) : max(0, translation)
            transform = CGAffineTransform(translationX: 0, y: dragOffset)

        case .ended, .cancelled, .failed:
            guard abs(dragOffset) > 40 else {
                let animator = ToastAnimation.dragSpring()
                animator.addAnimations { self.transform = .identity }
                animator.addCompletion { _ in
                    self.dragOffset = 0
                    self.onSettled?()
                }
                animator.startAnimation()
                return
            }
            onDismiss()

        default:
            break
        }
    }
}

/// The 28pt tinted circle holding a toast style's 16pt glyph.
@MainActor
private final class ToastGlyphView: UIView {

    init(style: ToastStyle) {
        super.init(frame: .zero)

        backgroundColor = style.tint.withAlphaComponent(0.14)
        layer.cornerRadius = 14

        let glyph = UIImageView(image: style.image)
        glyph.tintColor = style.tint
        glyph.contentMode = .scaleAspectFit

        addSubviews(glyph)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 28),
            heightAnchor.constraint(equalToConstant: 28),
            glyph.centerXAnchor.constraint(equalTo: centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: centerYAnchor),
            glyph.widthAnchor.constraint(equalToConstant: 16),
            glyph.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }
}
