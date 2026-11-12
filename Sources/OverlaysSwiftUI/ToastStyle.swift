import SwiftUI

/// Semantic kind of a toast — drives the leading icon glyph and its tint. Tints use
/// design tokens so toasts stay on-brand. Mirrors `ModalAlert.Icon`.
public enum ToastStyle: Sendable, Hashable {
    case info
    case success
    case error
    case warning

    var image: Image {
        switch self {
        case .success: OverlayTheme.current.successIcon.renderingMode(.template)
        case .error: OverlayTheme.current.errorIcon.renderingMode(.template)
        case .warning: OverlayTheme.current.warningIcon.renderingMode(.template)
        case .info: OverlayTheme.current.infoIcon
        }
    }

    var tint: Color {
        switch self {
        case .success: OverlayTheme.current.success
        case .error, .warning: OverlayTheme.current.danger
        case .info: OverlayTheme.current.accent
        }
    }
}
