import SwiftUI

/// The white card body of a `ModalAlertView`: an optional icon badge, a title and
/// optional message, and the vertical button stack.
struct ModalAlertCardView: View {
    let alert: ModalAlert
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                if let icon = alert.icon {
                    icon.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(icon.tint)
                        .frame(width: 88, height: 88)
                        .background(icon.tint.opacity(0.12), in: .circle)
                }

                VStack(spacing: 8) {
                    Text(alert.title)
                        .font(OverlayTheme.current.font(.semibold, 17))
                        .foregroundStyle(OverlayTheme.current.text)
                        .multilineTextAlignment(.center)

                    if let message = alert.message {
                        Text(message)
                            .font(OverlayTheme.current.font(.regular, 14))
                            .foregroundStyle(OverlayTheme.current.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach(alert.buttons) { button in
                    ModalAlertButtonView(button: button, dismiss: dismiss)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(OverlayTheme.current.surface, in: .rect(cornerRadius: 20))
    }
}