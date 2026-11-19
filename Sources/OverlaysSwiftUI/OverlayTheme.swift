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

    /// The second line of the loading card, under the message. Nil draws one line;
    /// a caller's own caption wins.
    public var loadingCaption: String?

    /// The gradient the toasts sit on, at its strongest on the screen edge they
    /// meet and clear at the other end of its height.
    public var toastScrimColor: Color

    /// The scrim's opacity on that edge, while the toasts there are not errors.
    /// `0` draws no scrim at all.
    public var toastScrimOpacity: CGFloat

    /// The scrim's opacity when a toast at that edge is an error, so a failure
    /// pulls the eye harder than good news.
    public var toastScrimErrorOpacity: CGFloat

    /// How far past the outermost capsule the scrim runs, so its fade reads as a
    /// wash rather than a band.
    public var toastScrimPadding: CGFloat

    /// The scrim's shortest height as a fraction of the screen, used until a
    /// toast at that edge gives it a height to cover.
    public var toastScrimHeightFraction: CGFloat

    /// The blur under the scrim. Nil draws none.
    public var toastScrimBlurStyle: UIBlurEffect.Style?

    /// Whether an error or warning toast fires a notification haptic.
    public var toastHaptics: Bool

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
        loadingCaption: String? = nil,
        locale: @escaping () -> Locale = { .current },
        layoutDirection: @escaping () -> LayoutDirection = { .leftToRight },
        toastScrimColor: Color = .black,
        toastScrimOpacity: CGFloat = 0.28,
        toastScrimErrorOpacity: CGFloat = 0.6,
        toastScrimPadding: CGFloat = 120,
        toastScrimHeightFraction: CGFloat = 0.25,
        toastScrimBlurStyle: UIBlurEffect.Style? = nil,
        toastHaptics: Bool = false,
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
        self.loadingCaption = loadingCaption
        self.locale = locale
        self.layoutDirection = layoutDirection
        self.toastScrimColor = toastScrimColor
        self.toastScrimOpacity = toastScrimOpacity
        self.toastScrimErrorOpacity = toastScrimErrorOpacity
        self.toastScrimPadding = toastScrimPadding
        self.toastScrimHeightFraction = toastScrimHeightFraction
        self.toastScrimBlurStyle = toastScrimBlurStyle
        self.toastHaptics = toastHaptics
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
