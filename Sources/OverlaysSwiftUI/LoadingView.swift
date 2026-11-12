import SwiftUI

struct LoadingView: View {
    let message: String?

    var body: some View {

        VStack(spacing: 12) {

            ProgressView()
                .tint(.white)

            if let message {

                Text(message)
                    .font(OverlayTheme.current.font(.medium, 14))
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
    }
}
