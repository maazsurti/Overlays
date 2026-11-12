import SwiftUI

/// The single standard rendering for a `ModalAlert`: a dimmed backdrop and a white
/// card with an optional icon, title, optional message, and a vertical button
/// stack. Every modal alert in the app looks like this — screens describe a
/// `ModalAlert`, they do not lay out their own popup.
struct ModalAlertView: View {
    let alert: ModalAlert
    let dismiss: @MainActor () -> Void

    var body: some View {

        ZStack {

            Color.black.opacity(0.2)
                .ignoresSafeArea()

            ModalAlertCardView(alert: alert, dismiss: dismiss)
                .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

#Preview {

    ModalAlertView(
        alert: .notice(
            icon: .success,
            title: "Password Changed!",
            message: "You can now use your new password to log in to your account.",
            buttonTitle: "Log In"
        ),
        dismiss: {}
    )
}
