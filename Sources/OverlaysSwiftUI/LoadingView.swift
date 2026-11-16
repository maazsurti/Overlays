import SwiftUI

struct LoadingView: View {
    let message: String?
    let caption: String?

    init(message: String? = nil, caption: String? = nil) {
        self.message = message
        self.caption = caption ?? OverlayTheme.current.loadingCaption
    }

    var body: some View {

        VStack(spacing: 12) {

            ProgressView()
                .tint(.white)

            if let message {

                Text(message)
                    .font(OverlayTheme.current.font(.medium, 14))
                    .foregroundStyle(.white)
            }

            if let caption, !caption.isEmpty {

                Text(caption)
                    .font(OverlayTheme.current.font(.regular, 12))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(20)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}
