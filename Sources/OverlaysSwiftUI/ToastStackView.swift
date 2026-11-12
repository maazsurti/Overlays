import SwiftUI

/// One vertical stack of toasts pinned to the top or bottom edge of the host.
struct ToastStackView: View {
    let placement: ToastPlacement
    let items: [Toast]
    let onDismiss: (UUID) -> Void
    var bottomInset: CGFloat = 0

    var body: some View {
        let orderedItems = placement == .top ? items.reversed() : items

        VStack(spacing: 8) {

            ForEach(orderedItems) { toast in
                ToastCapsule(toast: toast) {
                    onDismiss(toast.id)
                }
                .transition(.move(edge: placement == .top ? .top : .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: placement == .top ? .top : .bottom
        )
        .padding(.top, placement == .top ? 18 : 0)
        .padding(.bottom, placement == .bottom ? 18 + bottomInset : 0)
    }
}