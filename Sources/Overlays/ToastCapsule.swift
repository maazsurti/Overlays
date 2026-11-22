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

    /// The pill's own margins, whatever the theme leaves unset.
    private static let leadingMargin: CGFloat = 8
    private static let trailingMargin: CGFloat = 16
    private static let verticalMargin: CGFloat = 10

    /// The pill's insets around its content.
    private static var insets: UIEdgeInsets {
        let theme = OverlayTheme.current
        let base = theme.toastContentInsets
            ?? UIEdgeInsets(
                top: verticalMargin,
                left: leadingMargin,
                bottom: verticalMargin,
                right: trailingMargin
            )
        guard !theme.toastShowsGlyph else { return base }
        return UIEdgeInsets(
            top: base.top,
            left: theme.toastTextLeadingInset,
            bottom: base.bottom,
            right: base.right
        )
    }

    /// The glyph, its spacing and the pill's margins either side of the message.
    private static var messageInset: CGFloat {
        guard OverlayTheme.current.toastShowsGlyph else {
            return insets.left + insets.right
        }
        return insets.left + glyphSize + OverlayTheme.current.toastGlyphSpacing + insets.right
    }

    /// The glyph's height plus the pill's vertical margins.
    private static var minimumHeight: CGFloat {
        guard OverlayTheme.current.toastShowsGlyph else { return insets.top + insets.bottom }
        return glyphSize + insets.top + insets.bottom
    }

    init(toast: Toast, onDismiss: @escaping () -> Void) {
        let theme = OverlayTheme.current
        self.id = toast.id
        self.onDismiss = onDismiss
        self.messageLabel = UILabel()
        super.init(frame: .zero)

        let colours = theme.toastColours[toast.style]
        let font = theme.font(theme.toastFontWeight, theme.toastFontSize)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakStrategy = theme.toastLineBreakStrategy
        paragraph.lineHeightMultiple = theme.toastLineHeightMultiple
        paragraph.alignment = theme.isRightToLeft() ? .right : .left
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: colours?.text ?? theme.toastTextColor ?? theme.text,
            .paragraphStyle: paragraph,
        ]
        if let lineHeight = theme.toastLineHeight, font.lineHeight > 0 {
            // Scale the font's own leading to the requested pitch: a fixed
            // minimum/maximum height clips the last line on iOS.
            paragraph.lineHeightMultiple = lineHeight / font.lineHeight
        }
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        // The pill's width is decided by the text; the label must then wrap inside
        // it rather than hold its own single-line width and clip.
        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        messageLabel.attributedText = NSAttributedString(
            string: toast.message,
            attributes: attributes
        )

        backgroundColor = colours?.surface ?? theme.toastSurface ?? theme.surface
        layer.cornerRadius = theme.toastCornerRadius
        layer.borderWidth = theme.toastBorderWidth
        layer.borderColor = (colours?.border ?? theme.toastBorderColor ?? theme.border).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)
        let insets = Self.insets
        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right
        )
        // A drag carries the pill over the safe-area insets, which would add
        // them to its margins and squeeze the message to fewer lines. The pill
        // keeps its own margins, so its message keeps the height it was fitted to.
        insetsLayoutMarginsFromSafeArea = false

        let glyph = ToastGlyphView(style: toast.style)
        let content: UIStackView
        if theme.toastShowsGlyph {
            content = UIStackView.horizontal(
                spacing: theme.toastGlyphSpacing,
                alignment: theme.toastGlyphAlignsToFirstLine ? .top : .center,
                views: [glyph, messageLabel]
            )
        } else {
            content = UIStackView.horizontal(
                alignment: .fill,
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

        if theme.toastShowsGrabber {
            let grabber = UIView()
            grabber.backgroundColor = theme.toastGrabberColor ?? UIColor.white.withAlphaComponent(0.25)
            grabber.layer.cornerRadius = 2
            addSubviews(grabber)
            NSLayoutConstraint.activate([
                grabber.widthAnchor.constraint(equalToConstant: 36),
                grabber.heightAnchor.constraint(equalToConstant: 4),
                grabber.centerXAnchor.constraint(equalTo: centerXAnchor),
                grabber.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            ])
        }

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
        // A multi-line label reports one line until it knows the width it wraps in.
        messageLabel.preferredMaxLayoutWidth = contentWidth
        // The label's own fit ignores a paragraph style's fixed line height, so
        // the text is measured from its attributed string, line boxes included.
        let text = messageLabel.attributedText?.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size ?? messageLabel.sizeThatFits(
            CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
        )
        let width = OverlayTheme.current.toastFillsWidth
            ? maxWidth
            : min(maxWidth, Self.messageInset + ceil(text.width))
        let height = max(Self.minimumHeight, ceil(text.height) + Self.insets.top + Self.insets.bottom)
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

        backgroundColor = OverlayTheme.current.toastGlyphFill ?? style.tint.withAlphaComponent(0.14)
        layer.cornerRadius = 14

        let glyph = UIImageView(image: style.image)
        glyph.tintColor = OverlayTheme.current.toastGlyphTint ?? style.tint
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
