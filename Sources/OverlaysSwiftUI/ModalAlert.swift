import SwiftUI

/// A standardised modal alert: an optional icon, a title, an optional message, and
/// one or more buttons. Presented through `router.showModalAlert(_:)` /
/// `nav.showModalAlert(_:)`, which render `ModalAlertView` in the shared
/// custom-overlay slot. This is the app's own card-style alert — distinct from
/// SimpleRouter's native `AppAlert` (the system `.alert` bar, via
/// `nav.showAlert(title:message:)`). Build a `ModalAlert` instead of a one-off
/// overlay popup.
public struct ModalAlert: Identifiable {
    public let id = UUID()
    public var icon: Icon?
    public var title: LocalizedStringKey
    public var message: LocalizedStringKey?
    public var buttons: [ModalAlertButton]

    public init(icon: Icon? = nil, title: LocalizedStringKey, message: LocalizedStringKey? = nil, buttons: [ModalAlertButton]) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttons = buttons
    }

    /// Preset glyphs with their semantic tint, plus an escape hatch for a custom
    /// symbol. Tints use design tokens so alerts stay on-brand.
    public enum Icon: Equatable {
        case success
        case error
        case warning
        case info
        case custom(systemName: String, tint: Color)

        var image: Image {
            switch self {
            case .success: OverlayTheme.current.successIcon.renderingMode(.template)
            case .error: OverlayTheme.current.errorIcon.renderingMode(.template)
            case .warning: OverlayTheme.current.warningIcon.renderingMode(.template)
            case .info: OverlayTheme.current.infoIcon
            case let .custom(systemName, _): Image(systemName: systemName)
            }
        }

        var tint: Color {
            switch self {
            case .success: OverlayTheme.current.success
            case .error, .warning: OverlayTheme.current.danger
            case .info: OverlayTheme.current.accent
            case let .custom(_, tint): tint
            }
        }
    }
}

extension ModalAlert {

    /// One-button informational/success alert — the common case.
    public static func notice(
        icon: Icon? = nil,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttonTitle: LocalizedStringKey = "OK",
        action: @escaping () -> Void = {}
    ) -> ModalAlert {
        ModalAlert(
            icon: icon,
            title: title,
            message: message,
            buttons: [.primary(buttonTitle, action: action)]
        )
    }

    /// Two-button confirm/cancel alert.
    public static func confirm(
        icon: Icon? = nil,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        confirmTitle: LocalizedStringKey,
        isDestructive: Bool = false,
        cancelTitle: LocalizedStringKey = "Cancel",
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> ModalAlert {
        let confirm: ModalAlertButton = isDestructive
            ? .destructive(confirmTitle, action: onConfirm)
            : .primary(confirmTitle, action: onConfirm)
        return ModalAlert(
            icon: icon,
            title: title,
            message: message,
            buttons: [confirm, .cancel(cancelTitle, action: onCancel)]
        )
    }
}

/// One action in a `ModalAlert`. The role drives the standard styling; the action
/// runs and then the alert dismisses itself.
public struct ModalAlertButton: Identifiable {
    public let id = UUID()
    public let title: LocalizedStringKey
    public let role: Role
    public let action: () -> Void

    public enum Role {
        case primary
        case cancel
        case destructive
    }

    public static func primary(_ title: LocalizedStringKey, action: @escaping () -> Void) -> ModalAlertButton {
        ModalAlertButton(title: title, role: .primary, action: action)
    }

    public static func cancel(_ title: LocalizedStringKey = "Cancel", action: @escaping () -> Void = {}) -> ModalAlertButton {
        ModalAlertButton(title: title, role: .cancel, action: action)
    }

    public static func destructive(_ title: LocalizedStringKey, action: @escaping () -> Void) -> ModalAlertButton {
        ModalAlertButton(title: title, role: .destructive, action: action)
    }
}
