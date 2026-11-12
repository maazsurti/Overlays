import SwiftUI

struct ToastPresenterHost: View {
    let store: ToastStore
    @State private var presenter = ToastPresenter()

    var body: some View {

        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                presenter.attach(store: store)
            }
    }
}
