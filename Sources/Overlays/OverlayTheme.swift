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

    /// What VoiceOver reads for a loading card that has neither a message nor a
    /// caption of its own.
    public var pleaseWaitText: String

    /// The second line of the loading card, under the message and in
    /// ``secondaryText``. Nil draws one line; a caller's own caption wins.
    public var loadingCaption: String?

    public var isRightToLeft: () -> Bool

    /// The gradient the toasts sit on, at its strongest on the screen edge they
    /// meet and clear at the other end of its height.
    public var toastScrimColor: UIColor

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

    /// The status bar while a top scrim is on screen. `.default` leaves it to the
    /// app.
    public var toastScrimStatusBarStyle: UIStatusBarStyle

    /// Whether an error or warning toast fires a notification haptic.
    public var toastHaptics: Bool

    /// The toast pill's fill. Nil uses ``surface``.
    public var toastSurface: UIColor?

    /// The toast message's colour. Nil uses ``text``.
    public var toastTextColor: UIColor?

    /// The toast pill's border. Nil uses ``border``.
    public var toastBorderColor: UIColor?

    /// The toast pill's border width.
    public var toastBorderWidth: CGFloat

    /// The toast pill's corner radius.
    public var toastCornerRadius: CGFloat

    /// Whether the toast draws its style's glyph before the message.
    public var toastShowsGlyph: Bool

    /// The pill's margin from each screen edge.
    public var toastHorizontalMargin: CGFloat

    /// Whether the pill spans the width its margin leaves, instead of fitting its
    /// message.
    public var toastFillsWidth: Bool

    /// The message's line height, as a multiple of its natural line height.
    public var toastLineHeightMultiple: CGFloat

    /// The message's fixed line height in points. Nil keeps the font's own line
    /// height times ``toastLineHeightMultiple``.
    public var toastLineHeight: CGFloat?

    /// The pill's insets around its content. The glyph keeps a tighter leading
    /// edge through ``toastGlyphLeadingInset``.
    public var toastContentInsets: UIEdgeInsets?

    /// The pill's leading inset when it draws no glyph, in place of the content
    /// insets' leading value.
    public var toastTextLeadingInset: CGFloat

    /// Whether the pill draws a grabber capsule in its top padding.
    public var toastShowsGrabber: Bool

    /// The glyph's ink and the circle behind it. Nil keeps the style's tint.
    public var toastGlyphTint: UIColor?
    public var toastGlyphFill: UIColor?

    /// Whether the glyph sits with the first line instead of centred on both.
    public var toastGlyphAlignsToFirstLine: Bool

    /// Space between the style's glyph and the message.
    public var toastGlyphSpacing: CGFloat

    /// The toast message's size and weight.
    public var toastFontSize: CGFloat
    public var toastFontWeight: OverlayFontWeight

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
        infoIcon: UIImage? = UIImage(systemName: "info.circle.fill"),
        loadingGlyph: UIImage? = nil,
        okTitle: String = "OK",
        cancelTitle: String = "Cancel",
        pleaseWaitText: String = "Please wait",
        loadingCaption: String? = nil,
        isRightToLeft: @escaping () -> Bool = {
            UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        },
        toastScrimColor: UIColor = .black,
        toastScrimOpacity: CGFloat = 0.28,
        toastScrimErrorOpacity: CGFloat = 0.6,
        toastScrimPadding: CGFloat = 120,
        toastScrimHeightFraction: CGFloat = 0.25,
        toastScrimBlurStyle: UIBlurEffect.Style? = nil,
        toastScrimStatusBarStyle: UIStatusBarStyle = .lightContent,
        toastHaptics: Bool = false,
        toastSurface: UIColor? = nil,
        toastTextColor: UIColor? = nil,
        toastBorderColor: UIColor? = nil,
        toastBorderWidth: CGFloat = 0.5,
        toastCornerRadius: CGFloat = 16,
        toastShowsGlyph: Bool = true,
        toastHorizontalMargin: CGFloat = 16,
        toastFillsWidth: Bool = false,
        toastLineHeightMultiple: CGFloat = 1,
        toastLineHeight: CGFloat? = nil,
        toastContentInsets: UIEdgeInsets? = nil,
        toastTextLeadingInset: CGFloat = 16,
        toastShowsGrabber: Bool = false,
        toastGlyphTint: UIColor? = nil,
        toastGlyphFill: UIColor? = nil,
        toastGlyphAlignsToFirstLine: Bool = false,
        toastGlyphSpacing: CGFloat = 12,
        toastFontSize: CGFloat = 16,
        toastFontWeight: OverlayFontWeight = .semibold,
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
        self.loadingCaption = loadingCaption
        self.isRightToLeft = isRightToLeft
        self.toastScrimColor = toastScrimColor
        self.toastScrimOpacity = toastScrimOpacity
        self.toastScrimErrorOpacity = toastScrimErrorOpacity
        self.toastScrimPadding = toastScrimPadding
        self.toastScrimHeightFraction = toastScrimHeightFraction
        self.toastScrimBlurStyle = toastScrimBlurStyle
        self.toastScrimStatusBarStyle = toastScrimStatusBarStyle
        self.toastHaptics = toastHaptics
        self.toastSurface = toastSurface
        self.toastTextColor = toastTextColor
        self.toastBorderColor = toastBorderColor
        self.toastBorderWidth = toastBorderWidth
        self.toastCornerRadius = toastCornerRadius
        self.toastShowsGlyph = toastShowsGlyph
        self.toastHorizontalMargin = toastHorizontalMargin
        self.toastFillsWidth = toastFillsWidth
        self.toastLineHeightMultiple = toastLineHeightMultiple
        self.toastLineHeight = toastLineHeight
        self.toastContentInsets = toastContentInsets
        self.toastTextLeadingInset = toastTextLeadingInset
        self.toastShowsGrabber = toastShowsGrabber
        self.toastGlyphTint = toastGlyphTint
        self.toastGlyphFill = toastGlyphFill
        self.toastGlyphAlignsToFirstLine = toastGlyphAlignsToFirstLine
        self.toastGlyphSpacing = toastGlyphSpacing
        self.toastFontSize = toastFontSize
        self.toastFontWeight = toastFontWeight
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
