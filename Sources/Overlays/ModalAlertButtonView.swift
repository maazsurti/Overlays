//
//  ModalAlertButtonView.swift
//

import UIKit

/// One button inside a `ModalAlertCardView`, rendered per its
/// `ModalAlertButton.Role` (filled primary, destructive, or brand-outlined
/// cancel). Tapping it runs the button's action, then dismisses the alert.
@MainActor
final class ModalAlertButtonView: UIView {

    init(button: ModalAlertButton, dismiss: @escaping @MainActor () -> Void) {
        super.init(frame: .zero)

        let control: UIButton
        switch button.role {
        case .primary:
            let action: @MainActor () -> Void = { [weak self] in self?.run(button, dismiss) }
            let primary = OverlayTheme.current.makePrimaryButton?(button.title, action)
                ?? AlertRoleButton(title: button.title, role: .primary, action: action)
            primary.accessibilityIdentifier = "modal.alert.confirm"
            control = primary

        case .destructive:
            let destructive = AlertRoleButton(title: button.title, role: .destructive) { [weak self] in
                self?.run(button, dismiss)
            }
            destructive.accessibilityIdentifier = "modal.alert.confirm"
            control = destructive

        case .cancel:
            let cancel = AlertRoleButton(title: button.title, role: .cancel) { [weak self] in
                self?.run(button, dismiss)
            }
            cancel.accessibilityIdentifier = "modal.alert.cancel"
            control = cancel
        }

        addSubviews(control)
        control.pinEdgesToSuperview()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    /// Run the button's action, then clear the alert from the overlay slot.
    private func run(_ button: ModalAlertButton, _ dismiss: @MainActor () -> Void) {
        button.action()
        dismiss()
    }
}

/// The 48pt role-styled button used for a `ModalAlert`'s destructive and cancel
/// roles, with the app's press-fade feedback.
@MainActor
private final class AlertRoleButton: UIButton {

    private let action: @MainActor () -> Void

    init(title: String, role: ModalAlertButton.Role, action: @escaping @MainActor () -> Void) {
        self.action = action
        super.init(frame: .zero)

        setTitle(title, for: .normal)
        titleLabel?.font = OverlayTheme.current.font(.medium, 14)
        layer.cornerRadius = 10
        constrainSize(height: 48)

        switch role {
        case .primary:
            backgroundColor = OverlayTheme.current.accent
            setTitleColor(OverlayTheme.current.onAccent, for: .normal)

        case .destructive:
            backgroundColor = OverlayTheme.current.danger
            setTitleColor(.white, for: .normal)

        default:
            backgroundColor = OverlayTheme.current.surface
            setTitleColor(OverlayTheme.current.text, for: .normal)
            layer.borderWidth = 1.5
            layer.borderColor = OverlayTheme.current.accent.cgColor
        }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            UIView.animate(
                withDuration: 0.18,
                delay: 0,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                self.alpha = self.isHighlighted ? 0.55 : 1
            }
        }
    }

    @objc private func handleTap() {
        action()
    }
}
