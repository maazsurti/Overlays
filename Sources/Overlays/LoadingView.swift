//
//  LoadingView.swift
//

import UIKit

@MainActor
final class LoadingView: UIView {

    private let ring = CAShapeLayer()
    private let track = CAShapeLayer()
    private let ringHost = UIView()
    private static let ringSize: CGFloat = 64
    private static let glyphSize: CGFloat = 28

    private let message: String?
    private let caption: String?

    init(message: String? = nil, caption: String? = nil) {
        self.message = Self.line(message)
        self.caption = Self.line(caption ?? OverlayTheme.current.loadingCaption)

        super.init(frame: .zero)

        backgroundColor = OverlayTheme.current.surface
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 8)
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 28, bottom: 22, trailing: 28)

        track.fillColor = UIColor.clear.cgColor
        track.strokeColor = OverlayTheme.current.accent.withAlphaComponent(0.22).cgColor
        track.lineWidth = 5
        ring.fillColor = UIColor.clear.cgColor
        ring.strokeColor = OverlayTheme.current.accent.cgColor
        ring.lineWidth = 5
        ring.lineCap = .round
        ring.strokeEnd = 0.3
        let ringBounds = CGRect(x: 0, y: 0, width: Self.ringSize, height: Self.ringSize)
        let path = UIBezierPath(ovalIn: ringBounds.insetBy(dx: 2.5, dy: 2.5)).cgPath
        for shape in [track, ring] {
            shape.frame = ringBounds
            shape.path = path
            ringHost.layer.addSublayer(shape)
        }
        ringHost.constrainSize(width: Self.ringSize, height: Self.ringSize)

        let glyph = UIImageView(image: OverlayTheme.current.loadingGlyph?.withRenderingMode(.alwaysTemplate))
        glyph.tintColor = OverlayTheme.current.text
        glyph.contentMode = .scaleAspectFit
        ringHost.addSubviews(glyph)
        glyph.constrainSize(width: Self.glyphSize, height: Self.glyphSize)
        glyph.center(in: ringHost)

        let content = UIStackView.vertical(spacing: 14, alignment: .center, views: [ringHost])
        if let text = makeText() {
            content.addArrangedSubview(text)
        }

        addSubviews(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            widthAnchor.constraint(lessThanOrEqualToConstant: 260),
        ])

        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently
        accessibilityLabel = spokenLines.isEmpty
            ? OverlayTheme.current.pleaseWaitText
            : spokenLines.joined(separator: ", ")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    /// What the card says: the title, then the caption. Either may be absent; the
    /// ring keeps its size and the card its width, so a line only adds its own height.
    private var spokenLines: [String] {
        [message, caption].compactMap { $0 }
    }

    /// An absent line and an empty one draw the same card, so a caller can ask for no
    /// caption without knowing the theme's.
    private static func line(_ text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        return text
    }

    private func makeText() -> UIStackView? {
        let title = message.map {
            UILabel(
                text: $0,
                font: OverlayTheme.current.font(.semibold, 15),
                color: OverlayTheme.current.text,
                alignment: .center,
                numberOfLines: 0
            )
        }
        let detail = caption.map {
            UILabel(
                text: $0,
                font: OverlayTheme.current.font(.regular, 13),
                color: OverlayTheme.current.secondaryText,
                alignment: .center,
                numberOfLines: 0
            )
        }
        let lines = [title, detail].compactMap { $0 }
        guard !lines.isEmpty else { return nil }
        return UIStackView.vertical(spacing: 6, alignment: .center, views: lines)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        ring.removeAllAnimations()
        guard window != nil, !UIAccessibility.isReduceMotionEnabled else { return }
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = CGFloat.pi * 2
        spin.duration = 0.9
        spin.repeatCount = .infinity
        ring.add(spin, forKey: "spin")
    }
}

@MainActor
final class LoadingOverlayView: UIView {

    private let card: LoadingView

    init(message: String? = nil, caption: String? = nil) {
        card = LoadingView(message: message, caption: caption)
        super.init(frame: .zero)

        backgroundColor = UIColor.black.withAlphaComponent(0.35)
        accessibilityViewIsModal = true
        addSubviews(card)
        card.center(in: self)
        card.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        card.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.card.transform = .identity
        }
        UIAccessibility.post(notification: .screenChanged, argument: card)
    }
}
