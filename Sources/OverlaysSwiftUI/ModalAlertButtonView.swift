import SwiftUI

/// One button inside a `ModalAlertCardView`, rendered per its `ModalAlertButton.Role`
/// (filled primary, destructive, or brand-outlined cancel). Tapping it runs the
/// button's action, then dismisses the alert.
struct ModalAlertButtonView: View {
    let button: ModalAlertButton
    let dismiss: () -> Void

    var body: some View {
        switch button.role {
        case .primary:
            Group {
                if let make = OverlayTheme.current.makePrimaryButton {
                    make(button.title) { run(button) }
                } else {
                    Button { run(button) } label: {
                        Text(button.title)
                            .font(OverlayTheme.current.font(.medium, 14))
                            .foregroundStyle(OverlayTheme.current.onAccent)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(OverlayTheme.current.accent, in: .rect(cornerRadius: 10))
                    }
                }
            }
            .accessibilityIdentifier("modal.alert.confirm")

        case .destructive:
            Button { run(button) } label: {
                Text(button.title)
                    .font(OverlayTheme.current.font(.medium, 14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(OverlayTheme.current.danger, in: .rect(cornerRadius: 10))
            }
            .buttonStyle(.pressable)
            .accessibilityIdentifier("modal.alert.confirm")

        case .cancel:
            Button { run(button) } label: {
                Text(button.title)
                    .font(OverlayTheme.current.font(.medium, 14))
                    .foregroundStyle(OverlayTheme.current.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(OverlayTheme.current.surface, in: .rect(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(OverlayTheme.current.accent, lineWidth: 1.5)
                    }
            }
            .buttonStyle(.pressable)
            .accessibilityIdentifier("modal.alert.cancel")
        }
    }

    /// Run the button's action, then clear the alert from the overlay slot.
    private func run(_ button: ModalAlertButton) {
        button.action()
        dismiss()
    }
}