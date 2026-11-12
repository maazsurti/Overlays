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

    init(message: String? = nil) {
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
        glyph.constrainSize(width: 28, height: 28)
        glyph.center(in: ringHost)

        let content = UIStackView.vertical(spacing: 14, alignment: .center, views: [ringHost])
        if let message {
            content.addArrangedSubviews(
                UILabel(
                    text: message,
                    font: OverlayTheme.current.font(.semibold, 15),
                    color: OverlayTheme.current.text,
                    alignment: .center,
                    numberOfLines: 0
                )
            )
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
        accessibilityLabel = message ?? OverlayTheme.current.pleaseWaitText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
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

    init(message: String? = nil) {
        card = LoadingView(message: message)
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
