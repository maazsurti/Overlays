//
//  ToastCapsule.swift
//

import UIKit

/// One toast: a white rounded pill with the style's glyph and the message.
/// A drag of either direction past 40pt — or a fast flick — dismisses it;
/// anything shorter springs back.
@MainActor
final class ToastCapsule: UIView {

    let id: UUID
    private let onDismiss: () -> Void
    private let messageLabel: UILabel

    var onDragBegan: (() -> Void)?
    var onDragChanged: ((CGFloat) -> Void)?
    var onDragEnded: ((_ translation: CGFloat, _ velocity: CGFloat) -> Void)?

    /// The way out the user chose with the last drag, or `nil` to leave
    /// towards the stack's own edge.
    var dragDismissDirection: CGFloat?

    /// The glyph, its spacing and the pill's margins either side of the message.
    private static let messageInset: CGFloat = 62

    init(toast: Toast, onDismiss: @escaping () -> Void) {
        self.id = toast.id
        self.onDismiss = onDismiss
        self.messageLabel = UILabel(
            text: toast.message,
            font: OverlayTheme.current.font(.medium, 14),
            color: OverlayTheme.current.text,
            numberOfLines: 0
        )
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
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
        let content = UIStackView.horizontal(spacing: 10, alignment: .center, views: [glyph, messageLabel])

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

    /// The size the pill takes when its message wraps inside `maxWidth`.
    func fittingSize(maxWidth: CGFloat) -> CGSize {
        let widthLimit = widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)
        widthLimit.isActive = true
        defer { widthLimit.isActive = false }

        messageLabel.preferredMaxLayoutWidth = max(0, maxWidth - Self.messageInset)
        let size = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(
            width: min(ceil(size.width), ceil(maxWidth)),
            height: ceil(size.height)
        )
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            onDragBegan?()

        case .changed:
            onDragChanged?(recognizer.translation(in: superview).y)

        case .ended:
            onDragEnded?(
                recognizer.translation(in: superview).y,
                recognizer.velocity(in: superview).y
            )

        case .cancelled, .failed:
            onDragEnded?(recognizer.translation(in: superview).y, 0)

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
