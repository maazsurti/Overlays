//
//  ToastStackView.swift
//

import UIKit

/// The springs the toast system animates with, as `UIViewPropertyAnimator`s.
enum ToastAnimation {
    /// The stack's spring — SwiftUI's `.spring(response: 0.35, dampingFraction: 0.86)`.
    static func spring() -> UIViewPropertyAnimator {
        UIViewPropertyAnimator(duration: 0.35, dampingRatio: 0.86)
    }

    /// The drag snap-back — SwiftUI's `.spring(response: 0.3, dampingFraction: 0.8)`.
    static func dragSpring() -> UIViewPropertyAnimator {
        UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.8)
    }
}

/// One vertical stack of toast capsules, pinned to the top or bottom edge of
/// its host. The top stack lists newest-first; the bottom stack grows upwards
/// from the tab shell's chrome.
@MainActor
final class ToastStackView: UIView {

    let placement: ToastPlacement

    /// Called with the id of a toast the user dismissed by dragging it away.
    var onDismiss: ((UUID) -> Void)?

    /// Called whenever the capsules' on-screen frames change.
    var onFramesInvalidated: (() -> Void)?

    /// Clearance for the main tab shell's floating bar, written by
    /// `ToastStore.bottomChromeInset`.
    var bottomInset: CGFloat = 0 {
        didSet {
            guard bottomInset != oldValue else { return }
            bottomConstraint?.constant = -(Self.verticalPadding + bottomInset)
        }
    }

    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 18
    private static let spacing: CGFloat = 8
    /// How far a capsule travels as it enters or leaves the stack.
    private static let travelDistance: CGFloat = 44

    private let stack = UIStackView.vertical(spacing: spacing, alignment: .center)
    private var capsules: [UUID: ToastCapsule] = [:]
    private var bottomConstraint: NSLayoutConstraint?

    init(placement: ToastPlacement) {
        self.placement = placement
        super.init(frame: .zero)

        backgroundColor = .clear
        addSubviews(stack)

        var constraints: [NSLayoutConstraint] = [
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.horizontalPadding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.horizontalPadding),
        ]

        switch placement {
        case .top:
            constraints.append(
                stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Self.verticalPadding)
            )
        case .bottom:
            let bottom = stack.bottomAnchor.constraint(
                equalTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -(Self.verticalPadding + bottomInset)
            )
            bottomConstraint = bottom
            constraints.append(bottom)
        }
        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    /// Reconciles the visible capsules with `items`. Capsules only ever appear
    /// or disappear — the store appends new toasts and trims old ones per
    /// placement — so surviving capsules never need re-ordering.
    func update(with items: [Toast]) {
        let ordered = placement == .top ? Array(items.reversed()) : items
        let visibleIDs = Set(ordered.map(\.id))

        for (id, capsule) in capsules where !visibleIDs.contains(id) {
            capsules[id] = nil
            remove(capsule)
        }

        for (index, toast) in ordered.enumerated() where capsules[toast.id] == nil {
            let capsule = makeCapsule(for: toast)
            capsules[toast.id] = capsule
            insert(capsule, at: index)
        }
    }

    /// The raw index to insert at, for a capsule whose live position is
    /// `index`. Capsules on their way out still occupy their slot until their
    /// exit animation finishes, so raw and live positions diverge while one is
    /// leaving.
    private func insertionPosition(forLiveIndex index: Int) -> Int {
        var liveIndex = 0
        for (rawIndex, view) in stack.arrangedSubviews.enumerated() {
            guard capsules.values.contains(where: { $0 === view }) else { continue }
            if liveIndex == index { return rawIndex }
            liveIndex += 1
        }
        return stack.arrangedSubviews.count
    }

    /// The visible capsules' frames, in `view`'s coordinate space. The toast
    /// window hit-tests against these.
    func capsuleFrames(in view: UIView) -> [CGRect] {
        capsules.values.compactMap { capsule in
            guard capsule.window != nil else { return nil }
            return capsule.convert(capsule.bounds, to: view)
        }
    }

    // MARK: - Private

    private func makeCapsule(for toast: Toast) -> ToastCapsule {
        let capsule = ToastCapsule(toast: toast) { [weak self] in
            self?.onDismiss?(toast.id)
        }
        capsule.onSettled = { [weak self] in self?.onFramesInvalidated?() }
        return capsule
    }

    private func insert(_ capsule: ToastCapsule, at index: Int) {
        let position = insertionPosition(forLiveIndex: index)
        stack.insertArrangedSubview(capsule, at: position)
        // Long messages wrap instead of stretching past the stack's margins.
        capsule.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor).isActive = true

        guard window != nil else { return }

        capsule.alpha = 0
        capsule.transform = CGAffineTransform(translationX: 0, y: entryOffset)
        stack.layoutIfNeeded()

        let animator = ToastAnimation.spring()
        animator.addAnimations {
            capsule.alpha = 1
            capsule.transform = .identity
        }
        animator.addCompletion { _ in self.onFramesInvalidated?() }
        animator.startAnimation()
    }

    private func remove(_ capsule: ToastCapsule) {
        guard window != nil else {
            capsule.removeFromSuperview()
            return
        }

        let exit = CGAffineTransform(translationX: 0, y: -entryOffset)
        let animator = ToastAnimation.spring()
        animator.addAnimations {
            capsule.alpha = 0
            capsule.transform = capsule.transform.concatenating(exit)
        }
        animator.addCompletion { _ in
            capsule.removeFromSuperview()
            self.onFramesInvalidated?()
        }
        animator.startAnimation()
    }

    /// Capsules travel in from (and out towards) their own edge.
    private var entryOffset: CGFloat {
        placement == .top ? -Self.travelDistance : Self.travelDistance
    }
}
