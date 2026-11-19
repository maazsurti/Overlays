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

/// How each scrim moves when the store changes: it fades in with the first
/// toast at its edge and out with the last, and stays put while toasts swap.
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

/// Which screen edge a toast scrim sits against.
enum ToastScrimEdge {
    case top
    case bottom
}

/// How far a scrim reaches across the host, and how strongly it tints.
enum ToastScrimLayout {

    /// The height of the scrim on `edge`, measured from the edge itself.
    ///
    /// `capsuleFrames` are the stack's capsules in the host's space: the scrim
    /// covers everything between the edge and the furthest one, plus `padding`
    /// so the fade has room to read. With no capsule the scrim keeps `minimum`.
    static func height(
        edge: ToastScrimEdge,
        hostHeight: CGFloat,
        capsuleFrames: [CGRect],
        padding: CGFloat,
        minimum: CGFloat
    ) -> CGFloat {
        let natural: CGFloat
        switch edge {
        case .top:
            guard let lowest = capsuleFrames.map(\.maxY).max() else {
                return min(minimum, hostHeight)
            }
            natural = lowest + padding
        case .bottom:
            guard let highest = capsuleFrames.map(\.minY).min() else {
                return min(minimum, hostHeight)
            }
            natural = hostHeight - highest + padding
        }
        return min(max(natural, minimum), hostHeight)
    }

    /// The scrim's strength: an error at the edge darkens it, so the failure
    /// reads before its words do.
    static func opacity(
        for styles: [ToastStyle],
        normal: CGFloat,
        error: CGFloat
    ) -> CGFloat {
        styles.contains(.error) ? error : normal
    }
}
