import Foundation

/// What a pan decides: spring back, or leave in the drag's direction. Mirrors
/// the UIKit product's rule so both products dismiss the same way.
enum ToastDrag {
    /// A drag longer than this dismisses the toast.
    static let threshold: CGFloat = 40
    /// A flick faster than this dismisses it even under the threshold.
    static let velocityThreshold: CGFloat = 500

    enum Outcome: Equatable {
        case springBack
        case dismiss(direction: CGFloat)
    }

    static func outcome(offset: CGFloat, velocity: CGFloat) -> Outcome {
        let direction: CGFloat
        if offset != 0 {
            direction = offset < 0 ? -1 : 1
        } else if velocity != 0 {
            direction = velocity < 0 ? -1 : 1
        } else {
            return .springBack
        }

        let flicked = velocity * direction >= velocityThreshold
        return abs(offset) >= threshold || flicked ? .dismiss(direction: direction) : .springBack
    }
}
