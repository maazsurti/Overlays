//
//  ModalAlertView.swift
//

import UIKit

/// The single standard rendering for a `ModalAlert`: a dimmed backdrop and a
/// white card with an optional icon, title, optional message, and a vertical
/// button stack. Every modal alert in the app looks like this — screens
/// describe a `ModalAlert`, they do not lay out their own popup.
@MainActor
final class ModalAlertView: UIView {

    init(alert: ModalAlert, dismiss: @escaping @MainActor () -> Void) {
        super.init(frame: .zero)

        backgroundColor = UIColor.black.withAlphaComponent(0.2)

        let card = ModalAlertCardView(alert: alert, dismiss: dismiss)
        addSubviews(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }
}
