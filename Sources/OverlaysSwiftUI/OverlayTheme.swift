import SwiftUI

public enum OverlayFontWeight: Sendable {
    case regular
    case medium
    case semibold
}

/// The colours, type and icons every overlay draws with. Set `OverlayTheme.current` once at
/// launch, before the first overlay is shown.
public struct OverlayTheme {
    public var accent: Color
    public var onAccent: Color
    public var surface: Color
    public var text: Color
    public var secondaryText: Color
    public var border: Color
    public var success: Color
    public var danger: Color

    public var font: (OverlayFontWeight, CGFloat) -> Font

    public var successIcon: Image
    public var errorIcon: Image
    public var warningIcon: Image
    public var infoIcon: Image

    public var locale: () -> Locale
    public var layoutDirection: () -> LayoutDirection

    /// Builds the filled button for a `ModalAlert`'s primary role. Nil draws a filled accent button.
    public var makePrimaryButton: (@MainActor (_ title: LocalizedStringKey, _ action: @escaping () -> Void) -> AnyView)?

    public init(
        accent: Color = .accentColor,
        onAccent: Color = .white,
        surface: Color = Color(uiColor: .systemBackground),
        text: Color = .primary,
        secondaryText: Color = .secondary,
        border: Color = Color(uiColor: .separator),
        success: Color = .green,
        danger: Color = .red,
        font: @escaping (OverlayFontWeight, CGFloat) -> Font = OverlayTheme.systemFont,
        successIcon: Image = Image(systemName: "checkmark.circle.fill"),
        errorIcon: Image = Image(systemName: "xmark.circle.fill"),
        warningIcon: Image = Image(systemName: "exclamationmark.circle.fill"),
        infoIcon: Image = Image(systemName: "info.circle.fill"),
        locale: @escaping () -> Locale = { .current },
        layoutDirection: @escaping () -> LayoutDirection = { .leftToRight },
        makePrimaryButton: (@MainActor (_ title: LocalizedStringKey, _ action: @escaping () -> Void) -> AnyView)? = nil
    ) {
        self.accent = accent
        self.onAccent = onAccent
        self.surface = surface
        self.text = text
        self.secondaryText = secondaryText
        self.border = border
        self.success = success
        self.danger = danger
        self.font = font
        self.successIcon = successIcon
        self.errorIcon = errorIcon
        self.warningIcon = warningIcon
        self.infoIcon = infoIcon
        self.locale = locale
        self.layoutDirection = layoutDirection
        self.makePrimaryButton = makePrimaryButton
    }

    public static func systemFont(_ weight: OverlayFontWeight, _ size: CGFloat) -> Font {
        switch weight {
        case .regular: .system(size: size, weight: .regular)
        case .medium: .system(size: size, weight: .medium)
        case .semibold: .system(size: size, weight: .semibold)
        }
    }

    nonisolated(unsafe) public static var current = OverlayTheme()
}
