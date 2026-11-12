import UIKit

public enum OverlayFontWeight: Sendable {
    case regular
    case medium
    case semibold
}

/// The colours, type, icons and copy every overlay draws with. Set `OverlayTheme.current` once at
/// launch, before the first overlay is shown.
public struct OverlayTheme {
    public var accent: UIColor
    public var onAccent: UIColor
    public var surface: UIColor
    public var text: UIColor
    public var secondaryText: UIColor
    public var border: UIColor
    public var success: UIColor
    public var danger: UIColor

    public var font: (OverlayFontWeight, CGFloat) -> UIFont

    public var successIcon: UIImage?
    public var errorIcon: UIImage?
    public var warningIcon: UIImage?
    public var infoIcon: UIImage?
    public var loadingGlyph: UIImage?

    public var okTitle: String
    public var cancelTitle: String
    public var pleaseWaitText: String

    public var isRightToLeft: () -> Bool

    /// Builds the filled button for a `ModalAlert`'s primary role. Nil draws a filled accent button.
    public var makePrimaryButton: (@MainActor (_ title: String, _ action: @escaping @MainActor () -> Void) -> UIButton)?

    public init(
        accent: UIColor = .systemBlue,
        onAccent: UIColor = .white,
        surface: UIColor = .systemBackground,
        text: UIColor = .label,
        secondaryText: UIColor = .secondaryLabel,
        border: UIColor = .separator,
        success: UIColor = .systemGreen,
        danger: UIColor = .systemRed,
        font: @escaping (OverlayFontWeight, CGFloat) -> UIFont = OverlayTheme.systemFont,
        successIcon: UIImage? = UIImage(systemName: "checkmark.circle.fill"),
        errorIcon: UIImage? = UIImage(systemName: "xmark.circle.fill"),
        warningIcon: UIImage? = UIImage(systemName: "exclamationmark.circle.fill"),
        infoIcon: UIImage? = OverlayTheme.current.infoIcon,
        loadingGlyph: UIImage? = nil,
        okTitle: String = "OK",
        cancelTitle: String = "Cancel",
        pleaseWaitText: String = "Please wait",
        isRightToLeft: @escaping () -> Bool = {
            UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        },
        makePrimaryButton: (@MainActor (_ title: String, _ action: @escaping @MainActor () -> Void) -> UIButton)? = nil
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
        self.loadingGlyph = loadingGlyph
        self.okTitle = okTitle
        self.cancelTitle = cancelTitle
        self.pleaseWaitText = pleaseWaitText
        self.isRightToLeft = isRightToLeft
        self.makePrimaryButton = makePrimaryButton
    }

    public static func systemFont(_ weight: OverlayFontWeight, _ size: CGFloat) -> UIFont {
        switch weight {
        case .regular: .systemFont(ofSize: size, weight: .regular)
        case .medium: .systemFont(ofSize: size, weight: .medium)
        case .semibold: .systemFont(ofSize: size, weight: .semibold)
        }
    }

    nonisolated(unsafe) public static var current = OverlayTheme()
}
