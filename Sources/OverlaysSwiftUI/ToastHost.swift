import SwiftUI

struct ToastHost: View {
    private let store: ToastStore
    private let onFramesChange: ([CGRect]) -> Void

    init(store: ToastStore, onFramesChange: @escaping ([CGRect]) -> Void = { _ in }) {
        self.store = store
        self.onFramesChange = onFramesChange
    }

    var body: some View {

        ZStack {
            ToastStackView(
                placement: .top,
                items: store.toasts.filter { $0.placement == .top },
                onDismiss: { store.dismiss($0) }
            )
            ToastStackView(
                placement: .bottom,
                items: store.toasts.filter { $0.placement == .bottom },
                onDismiss: { store.dismiss($0) },
                bottomInset: store.bottomChromeInset
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: store.toasts)
        .onPreferenceChange(ToastFramesKey.self) { onFramesChange($0) }
    }
}
