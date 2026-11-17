import SwiftUI

struct ToastCapsule: View {
    let toast: Toast
    let onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {

        HStack(spacing: 12) {

            toast.style.image
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(toast.style.tint)
                .frame(width: 28, height: 28)
                .background(toast.style.tint.opacity(0.14), in: .circle)

            Text(toast.message)
                .font(OverlayTheme.current.font(.semibold, 16))
                .foregroundStyle(OverlayTheme.current.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 10)
        .background(OverlayTheme.current.surface, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(OverlayTheme.current.border, lineWidth: 0.5)
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ToastFramesKey.self,
                    value: [geo.frame(in: .global)]
                )
            }
        )
        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
        .offset(y: dragOffset)
        .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {

        DragGesture(minimumDistance: 4)
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                // The prediction runs about a quarter second ahead, so the
                // difference is the gesture's speed in points per second.
                let velocity = (value.predictedEndTranslation.height - value.translation.height) * 4
                switch ToastDrag.outcome(offset: value.translation.height, velocity: velocity) {
                case .dismiss:
                    onDismiss()
                case .springBack:
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
}
