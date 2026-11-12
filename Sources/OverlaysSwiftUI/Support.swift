import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    var pressedOpacity: Double = 0.55

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

private struct ThemeDirectionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.locale, OverlayTheme.current.locale())
            .environment(\.layoutDirection, OverlayTheme.current.layoutDirection())
    }
}

extension View {
    func supportRTL() -> some View {
        modifier(ThemeDirectionModifier())
    }
}
