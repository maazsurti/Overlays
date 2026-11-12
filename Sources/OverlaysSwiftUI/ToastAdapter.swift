import SwiftUI
import SimpleRouterSwiftUI

public struct ToastAdapter: OverlayAdapter {
    public init() {}

    public func body(state: Binding<ToastStore>) -> some View {

        ToastPresenterHost(store: state.wrappedValue)
    }
}
