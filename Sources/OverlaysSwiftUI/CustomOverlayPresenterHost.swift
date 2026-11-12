import SwiftUI

struct CustomOverlayPresenterHost: View {
    @Binding var overlay: CustomOverlay?
    @State private var presenter = OverlayWindowPresenter()

    var body: some View {

        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                present(overlay)
            }
            .onChange(of: overlay) { _, overlay in
                present(overlay)
            }
    }

    private func present(_ overlay: CustomOverlay?) {
        presenter.present(overlay, allowsPassthrough: \.allowsPassthrough) { overlay in
            overlay.content {
                self.overlay = nil
            }
            .environment(\.dismissOverlay) {
                self.overlay = nil
            }
        }
    }
}
