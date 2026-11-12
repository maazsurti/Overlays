//
//  ModalAlertCardView.swift
//

import UIKit

/// The white card body of a `ModalAlertView`: an optional icon badge, a title
/// and optional message, and the vertical button stack.
@MainActor
final class ModalAlertCardView: UIView {

    init(alert: ModalAlert, dismiss: @escaping @MainActor () -> Void) {
        super.init(frame: .zero)

        backgroundColor = OverlayTheme.current.surface
        layer.cornerRadius = 20
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)

        let header = UIStackView.vertical(spacing: 12)
        if let icon = alert.icon {
            header.addArrangedSubviews(ModalAlertIconView(icon: icon))
        }

        let text = UIStackView.vertical(
            spacing: 8,
            views: [
                UILabel(
                    text: alert.title,
                    font: OverlayTheme.current.font(.semibold, 17),
                    color: OverlayTheme.current.text,
                    alignment: .center,
                    numberOfLines: 0
                )
            ]
        )
        if let message = alert.message {
            text.addArrangedSubviews(
                UILabel(
                    text: message,
                    font: OverlayTheme.current.font(.regular, 14),
                    color: OverlayTheme.current.secondaryText,
                    alignment: .center,
                    numberOfLines: 0
                )
            )
        }
        header.addArrangedSubviews(text)

        let buttons = UIStackView.vertical(spacing: 12)
        alert.buttons.forEach { buttons.addArrangedSubviews(ModalAlertButtonView(button: $0, dismiss: dismiss)) }

        let content = UIStackView.vertical(spacing: 24, views: [header, buttons])
        addSubviews(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }
}

/// The icon badge at the top of a card: an 88pt circle in the icon's tint at
/// 12% opacity, holding the 44pt glyph.
@MainActor
private final class ModalAlertIconView: UIView {

    init(icon: ModalAlert.Icon) {
        super.init(frame: .zero)

        let badge = UIView()
        badge.backgroundColor = icon.tint.withAlphaComponent(0.12)
        badge.layer.cornerRadius = 44

        let glyph = UIImageView(image: icon.image)
        glyph.tintColor = icon.tint
        glyph.contentMode = .scaleAspectFit

        badge.addSubviews(glyph)
        NSLayoutConstraint.activate([
            glyph.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            glyph.widthAnchor.constraint(equalToConstant: 44),
            glyph.heightAnchor.constraint(equalToConstant: 44),
        ])

        addSubviews(badge)
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: topAnchor),
            badge.bottomAnchor.constraint(equalTo: bottomAnchor),
            badge.centerXAnchor.constraint(equalTo: centerXAnchor),
            badge.widthAnchor.constraint(equalToConstant: 88),
            badge.heightAnchor.constraint(equalToConstant: 88),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }
}
