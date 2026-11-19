import SwiftUI

/// The blur under a scrim, drawn with the same `UIBlurEffect` the UIKit target
/// uses so both products look alike.
struct ToastScrimBlur: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        view.effect = UIBlurEffect(style: style)
    }
}
