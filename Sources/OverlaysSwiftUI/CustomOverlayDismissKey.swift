import SwiftUI

struct CustomOverlayDismissKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var dismissOverlay: () -> Void {
        get { self[CustomOverlayDismissKey.self] }
        set { self[CustomOverlayDismissKey.self] = newValue }
    }
}
