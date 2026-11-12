import SwiftUI
import SimpleRouterSwiftUI

public struct CustomOverlayAdapter: OverlayAdapter {
    public init() {}

    public func body(state: Binding<CustomOverlay?>) -> some View {

        CustomOverlayPresenterHost(overlay: state)
    }
}
