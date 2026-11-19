import SwiftUI

/// The on-screen frame of each placement's capsules, so the host can size the
/// scrim behind them.
struct ToastStackFramesKey: PreferenceKey {
    static let defaultValue: [ToastPlacement: CGRect] = [:]

    static func reduce(
        value: inout [ToastPlacement: CGRect],
        nextValue: () -> [ToastPlacement: CGRect]
    ) {
        value.merge(nextValue()) { _, new in new }
    }
}
