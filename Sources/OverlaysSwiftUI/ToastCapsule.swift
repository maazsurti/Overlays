import SwiftUI

struct ToastCapsule: View {
    let toast: Toast
    let onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {

        HStack(spacing: 10) {

            toast.style.image
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(toast.style.tint)
                .frame(width: 28, height: 28)
                .background(toast.style.tint.opacity(0.14), in: .circle)

            Text(toast.message)
                .font(OverlayTheme.current.font(.medium, 14))
                .foregroundStyle(OverlayTheme.current.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .background(OverlayTheme.current.surface, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(OverlayTheme.current.border, lineWidth: 1)
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ToastFramesKey.self,
                    value: [geo.frame(in: .global)]
                )
            }
        )
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .offset(y: dragOffset)
        .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {

        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let translation = value.translation.height
                dragOffset = toast.placement == .top ? min(0, translation) : max(0, translation)
            }
            .onEnded { _ in
                if abs(dragOffset) > 40 {
                    onDismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
}
