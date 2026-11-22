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

    private static let glyphSize: CGFloat = 28
    private static let contentSpacing: CGFloat = 12
    private static let leadingMargin: CGFloat = 8
    private static let textLeadingMargin: CGFloat = 16
    private static let trailingMargin: CGFloat = 16
    private static let verticalMargin: CGFloat = 10

    /// The glyph, its spacing and the pill's margins either side of the message.
    private static var messageInset: CGFloat {
        guard OverlayTheme.current.toastShowsGlyph else {
            return textLeadingMargin + trailingMargin
        }
        return leadingMargin + glyphSize + contentSpacing + trailingMargin
    }

    /// The glyph's height plus the pill's vertical margins.
    private static var minimumHeight: CGFloat {
        guard OverlayTheme.current.toastShowsGlyph else { return 2 * verticalMargin }
        return glyphSize + 2 * verticalMargin
    }

    init(toast: Toast, onDismiss: @escaping () -> Void) {
        let theme = OverlayTheme.current
        self.id = toast.id
        self.onDismiss = onDismiss
        self.messageLabel = UILabel()
        super.init(frame: .zero)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = theme.toastLineHeightMultiple
        paragraph.alignment = theme.isRightToLeft() ? .right : .left
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = NSAttributedString(
            string: toast.message,
            attributes: [
                .font: theme.font(theme.toastFontWeight, theme.toastFontSize),
                .foregroundColor: theme.toastTextColor ?? theme.text,
                .paragraphStyle: paragraph,
            ]
        )

        backgroundColor = theme.toastSurface ?? theme.surface
        layer.cornerRadius = theme.toastCornerRadius
        layer.borderWidth = theme.toastBorderWidth
        layer.borderColor = (theme.toastBorderColor ?? theme.border).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)
        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: Self.verticalMargin,
            leading: theme.toastShowsGlyph ? Self.leadingMargin : Self.textLeadingMargin,
            bottom: Self.verticalMargin,
            trailing: Self.trailingMargin
        )
        // A drag carries the pill over the safe-area insets, which would add
        // them to its margins and squeeze the message to fewer lines. The pill
        // keeps its own margins, so its message keeps the height it was fitted to.
        insetsLayoutMarginsFromSafeArea = false

        let glyph = ToastGlyphView(style: toast.style)
        let content: UIStackView
        if theme.toastShowsGlyph {
            content = UIStackView.horizontal(
                spacing: Self.contentSpacing,
                alignment: .center,
                views: [glyph, messageLabel]
            )
        } else {
            content = UIStackView.horizontal(
                alignment: .center,
                views: [messageLabel]
            )
        }
        content.isUserInteractionEnabled = false

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

    /// The size the pill takes when its message wraps inside `maxWidth`. The
    /// capsule is frame-positioned, so this is the only size it ever gets:
    /// the stack assigns it to `bounds` and nothing else can resize it.
    func fittingSize(maxWidth: CGFloat) -> CGSize {
        let contentWidth = max(0, maxWidth - Self.messageInset)
        let text = messageLabel.sizeThatFits(
            CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
        )
        let width = OverlayTheme.current.toastFillsWidth
            ? maxWidth
            : min(maxWidth, Self.messageInset + ceil(text.width))
        let height = max(Self.minimumHeight, ceil(text.height) + 2 * Self.verticalMargin)
        return CGSize(width: ceil(width), height: ceil(height))
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
