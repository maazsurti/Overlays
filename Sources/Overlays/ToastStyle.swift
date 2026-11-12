//
//  ToastStyle.swift
//

import UIKit

/// Semantic kind of a toast — drives the leading icon glyph and its tint. Tints
/// use design tokens so toasts stay on-brand. Mirrors `ModalAlert.Icon`.
public enum ToastStyle: Sendable, Hashable {
    case info
    case success
    case error
    case warning

    var image: UIImage? {
        switch self {
        case .success: OverlayTheme.current.successIcon?.withRenderingMode(.alwaysTemplate)
        case .error: OverlayTheme.current.errorIcon?.withRenderingMode(.alwaysTemplate)
        case .warning: OverlayTheme.current.warningIcon?.withRenderingMode(.alwaysTemplate)
        case .info: OverlayTheme.current.infoIcon
        }
    }

    var tint: UIColor {
        switch self {
        case .success: OverlayTheme.current.success
        case .error, .warning: OverlayTheme.current.danger
        case .info: OverlayTheme.current.accent
        }
    }
}
