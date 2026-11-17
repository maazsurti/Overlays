//
//  ToastLayout.swift
//

import CoreGraphics
import Foundation

/// Where a toast stack's front capsule sits against its edge.
///
/// A bottom toast clears whatever holds the bottom of the screen — the tab
/// shell's dock, or the keyboard — by one small gap, so it reads as attached to
/// that chrome instead of floating above it.
enum ToastLayout {

    /// Space between the top safe area and a top toast.
    static let topPadding: CGFloat = 28

    /// Space between the bottom chrome's top edge and a bottom toast.
    static let bottomGap: CGFloat = 12

    /// The y of the top toast's top edge.
    static func topEdgeY(safeAreaTop: CGFloat) -> CGFloat {
        safeAreaTop + topPadding
    }

    /// The y of the bottom toast's bottom edge in a host `height` tall.
    ///
    /// `chromeInset` is the height of the dock above the bottom safe area, and
    /// `keyboardInset` how far the keyboard covers the host — measured from the
    /// host's own bottom edge, which already includes that safe area. Whichever
    /// edge is higher is the one the toast clears.
    static func bottomEdgeY(
        height: CGFloat,
        safeAreaBottom: CGFloat,
        chromeInset: CGFloat,
        keyboardInset: CGFloat = 0
    ) -> CGFloat {
        let chromeTop = max(safeAreaBottom + chromeInset, keyboardInset)
        return height - chromeTop - bottomGap
    }
}

/// How the bottom scrim moves when the store changes: it fades in with the
/// first bottom toast and out with the last, and stays put while toasts swap.
enum ToastScrimTransition: Equatable {
    case none
    case fadeIn
    case fadeOut

    static func between(before: Int, after: Int) -> ToastScrimTransition {
        switch (before > 0, after > 0) {
        case (false, true): .fadeIn
        case (true, false): .fadeOut
        default: .none
        }
    }

    static let fadeInDuration: TimeInterval = 0.25
    static let fadeOutDuration: TimeInterval = 0.2
}
