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

    /// Reduce Motion's cross-fade: opacity only, no travel.
    static func crossFade() -> UIViewPropertyAnimator {
        UIViewPropertyAnimator(duration: 0.2, curve: .easeOut)
    }
}

/// Where a capsule sits and how far it travels. A capsule enters from its own
/// edge and leaves towards the same one; a drag chooses the way out instead.
enum ToastMotion {
    /// How far a capsule travels as it enters or leaves the stack.
    static let travel: CGFloat = 44

    /// The distance from its resting slot a capsule starts its entrance at.
    static func entryOffset(for placement: ToastPlacement) -> CGFloat {
        placement == .top ? -travel : travel
    }

    /// The distance from its resting slot a capsule ends its exit at.
    /// `dragDirection` is the drag's sign when the user threw it away.
    static func exitOffset(for placement: ToastPlacement, dragDirection: CGFloat? = nil) -> CGFloat {
        guard let dragDirection, dragDirection != 0 else {
            return entryOffset(for: placement)
        }
        return dragDirection * travel
    }
}

/// What a pan decides: spring back, or leave in the drag's direction.
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

/// One vertical stack of toast capsules, pinned to the top or bottom edge of
/// its host. Capsules are laid out by hand, nearest the edge first, so the
/// stack can animate every survivor to its new slot in the same frame as the
/// capsule that arrived or left.
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
            needsTargetCenters = true
            setNeedsLayout()
        }
    }

    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 28
    /// How far each capsule behind the front one peeks out from under it.
    private static let depthPeek: CGFloat = 14
    /// How much smaller each capsule behind the front one is.
    private static let depthScaleStep: CGFloat = 0.04

    /// Live capsules in flow order: index 0 sits nearest this stack's edge.
    private var live: [ToastCapsule] = []
    /// Capsules fading out of the stack.
    private var departing: [ToastCapsule] = []

    private var targetCenters: [ObjectIdentifier: CGPoint] = [:]
    private var targetScales: [ObjectIdentifier: CGFloat] = [:]
    private var animator: UIViewPropertyAnimator?
    private var generation = 0
    private var displayLink: CADisplayLink?

    private var draggedCapsule: ToastCapsule?
    private var dragTranslation: CGFloat = 0
    private var dragBaseCenter: CGPoint = .zero

    private var laidOutSize: CGSize = .zero
    private var needsTargetCenters = false

    init(placement: ToastPlacement) {
        self.placement = placement
        super.init(frame: .zero)

        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0 else { return }
        guard bounds.size != laidOutSize || needsTargetCenters else { return }

        if animator != nil || draggedCapsule != nil {
            needsTargetCenters = true
            return
        }

        laidOutSize = bounds.size
        needsTargetCenters = false
        computeTargetCenters()
        for capsule in live {
            let key = ObjectIdentifier(capsule)
            if let center = targetCenters[key] {
                capsule.center = center
            }
            capsule.transform = CGAffineTransform(scaleX: targetScales[key] ?? 1, y: targetScales[key] ?? 1)
            capsule.alpha = 1
        }
        onFramesInvalidated?()
    }

    /// Only the capsules take touches. The stacks fill the whole window, so
    /// without this the stack behind the top one would swallow its drags.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        live.contains { capsule in
            (capsule.layer.presentation()?.frame ?? capsule.frame).contains(point)
        }
    }

    /// Reconciles the visible capsules with `items`. Capsules enter at the
    /// edge, leave towards the edge (or the way they were dragged), and every
    /// survivor moves to its new slot in the same animation.
    func update(with items: [Toast]) {
        let flow = Array(items.reversed())
        let ids = Set(flow.map(\.id))

        freezeAnimations()

        if let draggedCapsule, !ids.contains(draggedCapsule.id) {
            self.draggedCapsule = nil
            dragTranslation = 0
        }

        for capsule in live where !ids.contains(capsule.id) {
            departing.append(capsule)
            sendSubviewToBack(capsule)
        }
        live.removeAll { !ids.contains($0.id) }

        let existing = Dictionary(uniqueKeysWithValues: live.map { ($0.id, $0) })
        var entering: [ToastCapsule] = []
        var ordered: [ToastCapsule] = []
        for toast in flow {
            if let capsule = existing[toast.id] {
                ordered.append(capsule)
            } else if let revived = departing.first(where: { $0.id == toast.id }) {
                departing.removeAll { $0 === revived }
                ordered.append(revived)
            } else {
                let capsule = makeCapsule(for: toast)
                addSubview(capsule)
                capsule.alpha = 0
                entering.append(capsule)
                ordered.append(capsule)
            }
        }
        live = ordered

        guard window != nil, bounds.width > 0 else {
            placeWithoutAnimation()
            return
        }

        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        computeTargetCenters()

        for capsule in entering {
            guard let target = targetCenters[ObjectIdentifier(capsule)] else { continue }
            let scale = targetScales[ObjectIdentifier(capsule)] ?? 1
            capsule.transform = CGAffineTransform(scaleX: scale, y: scale)
            if reduceMotion {
                capsule.center = target
            } else {
                let offset = ToastMotion.entryOffset(for: placement)
                capsule.center = CGPoint(x: target.x, y: target.y + offset)
            }
        }

        if draggedCapsule != nil {
            applyDrag()
        }

        updateDepthOrder()
        animateReflow(reduceMotion: reduceMotion)
    }

    /// The visible capsules' frames, in `view`'s coordinate space. The toast
    /// window hit-tests against these, so an animating capsule reports where
    /// it is being drawn, not where it will end up.
    func capsuleFrames(in view: UIView) -> [CGRect] {
        live.compactMap { capsule in
            guard capsule.window != nil, let superview = capsule.superview else { return nil }
            let frame = capsule.layer.presentation()?.frame ?? capsule.frame
            return superview.convert(frame, to: view)
        }
    }

    // MARK: - Layout

    private func computeTargetCenters() {
        guard bounds.width > 0 else {
            targetCenters = [:]
            targetScales = [:]
            return
        }

        let maxWidth = bounds.width - 2 * Self.horizontalPadding
        var edgeY: CGFloat
        switch placement {
        case .top:
            edgeY = safeAreaInsets.top + Self.verticalPadding
        case .bottom:
            edgeY = bounds.height - safeAreaInsets.bottom - Self.verticalPadding - bottomInset
        }

        var centers: [ObjectIdentifier: CGPoint] = [:]
        var scales: [ObjectIdentifier: CGFloat] = [:]
        for (index, capsule) in live.enumerated() {
            let size = capsule.fittingSize(maxWidth: maxWidth)
            capsule.bounds = CGRect(origin: .zero, size: size)

            // Each capsule behind the front one is a little smaller and tucked
            // under its neighbour, so the stack reads as depth, not as a list.
            let depth = CGFloat(index)
            let scale = max(0.86, 1 - Self.depthScaleStep * depth)
            let visualHeight = size.height * scale
            let centerY: CGFloat
            switch placement {
            case .top:
                centerY = edgeY + Self.depthPeek * depth + visualHeight / 2
            case .bottom:
                centerY = edgeY - Self.depthPeek * depth - visualHeight / 2
            }

            let key = ObjectIdentifier(capsule)
            centers[key] = CGPoint(x: bounds.midX, y: centerY)
            scales[key] = scale
        }
        targetCenters = centers
        targetScales = scales
    }

    private func placeWithoutAnimation() {
        if bounds.width > 0 {
            computeTargetCenters()
        } else {
            targetCenters = [:]
            targetScales = [:]
        }
        for capsule in live {
            let key = ObjectIdentifier(capsule)
            if let center = targetCenters[key] {
                capsule.center = center
            }
            capsule.transform = CGAffineTransform(scaleX: targetScales[key] ?? 1, y: targetScales[key] ?? 1)
            capsule.alpha = 1
        }
        updateDepthOrder()
        removeDeparted()
        onFramesInvalidated?()
    }

    /// The front capsule sits above the ones behind it; a departee goes under
    /// the whole stack.
    private func updateDepthOrder() {
        for capsule in live.reversed() {
            bringSubviewToFront(capsule)
        }
        for capsule in departing {
            sendSubviewToBack(capsule)
        }
    }

    // MARK: - Animation

    private func animateReflow(reduceMotion: Bool) {
        generation += 1
        let current = generation

        var exits: [ObjectIdentifier: CGPoint] = [:]
        for capsule in departing {
            let offset = reduceMotion
                ? 0
                : ToastMotion.exitOffset(for: placement, dragDirection: capsule.dragDismissDirection)
            exits[ObjectIdentifier(capsule)] = CGPoint(
                x: capsule.center.x,
                y: capsule.center.y + offset
            )
        }

        let destinations = targetCenters
        let scales = targetScales
        if reduceMotion {
            for capsule in live where capsule !== draggedCapsule {
                let key = ObjectIdentifier(capsule)
                if let center = destinations[key] {
                    capsule.center = center
                }
                let scale = scales[key] ?? 1
                capsule.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }

        let animator = reduceMotion ? ToastAnimation.crossFade() : ToastAnimation.spring()
        animator.addAnimations { [weak self] in
            guard let self else { return }
            for capsule in self.live {
                let key = ObjectIdentifier(capsule)
                if capsule !== self.draggedCapsule {
                    if !reduceMotion, let center = destinations[key] {
                        capsule.center = center
                    }
                    let scale = scales[key] ?? 1
                    capsule.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
                capsule.alpha = 1
            }
            for capsule in self.departing {
                if let exit = exits[ObjectIdentifier(capsule)] {
                    capsule.center = exit
                }
                capsule.alpha = 0
            }
        }
        animator.addCompletion { [weak self] _ in
            guard let self, self.generation == current else { return }
            self.animator = nil
            self.removeDeparted()
            self.stopFrameReportingIfIdle()
            self.onFramesInvalidated?()
            self.applyDeferredLayout()
        }
        animator.startAnimation()
        self.animator = animator
        startFrameReporting()
    }

    private func springBack() {
        if UIAccessibility.isReduceMotionEnabled {
            for capsule in live {
                let key = ObjectIdentifier(capsule)
                if let target = targetCenters[key] {
                    capsule.center = target
                }
                let scale = targetScales[key] ?? 1
                capsule.transform = CGAffineTransform(scaleX: scale, y: scale)
                capsule.alpha = 1
            }
            onFramesInvalidated?()
            stopFrameReportingIfIdle()
            return
        }

        generation += 1
        let current = generation
        let destinations = targetCenters
        let scales = targetScales
        let animator = ToastAnimation.dragSpring()
        animator.addAnimations { [weak self] in
            guard let self else { return }
            for capsule in self.live {
                let key = ObjectIdentifier(capsule)
                if let target = destinations[key] {
                    capsule.center = target
                }
                let scale = scales[key] ?? 1
                capsule.transform = CGAffineTransform(scaleX: scale, y: scale)
                capsule.alpha = 1
            }
        }
        animator.addCompletion { [weak self] _ in
            guard let self, self.generation == current else { return }
            self.animator = nil
            self.stopFrameReportingIfIdle()
            self.onFramesInvalidated?()
            self.applyDeferredLayout()
        }
        animator.startAnimation()
        self.animator = animator
        startFrameReporting()
    }

    /// Stops whatever is in flight, leaving the capsules where they are being
    /// drawn so the next animation starts from the pixels on screen.
    private func freezeAnimations() {
        guard let animator else { return }

        generation += 1
        var frozen: [(ToastCapsule, CGRect, CGPoint, CGAffineTransform, CGFloat)] = []
        for capsule in live + departing {
            if let presentation = capsule.layer.presentation() {
                frozen.append((
                    capsule,
                    presentation.bounds,
                    presentation.position,
                    CATransform3DGetAffineTransform(presentation.transform),
                    CGFloat(presentation.opacity)
                ))
            }
        }
        animator.stopAnimation(true)
        self.animator = nil

        for (capsule, bounds, position, transform, opacity) in frozen {
            capsule.layer.removeAllAnimations()
            capsule.bounds = bounds
            capsule.center = position
            capsule.transform = transform
            capsule.alpha = opacity
        }
    }

    private func removeDeparted() {
        for capsule in departing {
            capsule.removeFromSuperview()
        }
        departing.removeAll()
    }

    private func applyDeferredLayout() {
        guard needsTargetCenters else { return }
        needsTargetCenters = false
        setNeedsLayout()
    }

    // MARK: - Dragging

    private func makeCapsule(for toast: Toast) -> ToastCapsule {
        let capsule = ToastCapsule(toast: toast) { [weak self] in
            self?.onDismiss?(toast.id)
        }
        capsule.onDragBegan = { [weak self, weak capsule] in
            guard let capsule else { return }
            self?.dragBegan(capsule)
        }
        capsule.onDragChanged = { [weak self, weak capsule] translation in
            guard let capsule else { return }
            self?.dragChanged(capsule, translation: translation)
        }
        capsule.onDragEnded = { [weak self, weak capsule] translation, velocity in
            guard let capsule else { return }
            self?.dragEnded(capsule, translation: translation, velocity: velocity)
        }
        return capsule
    }

    private func dragBegan(_ capsule: ToastCapsule) {
        guard live.contains(where: { $0 === capsule }) else { return }

        freezeAnimations()
        draggedCapsule = capsule
        dragTranslation = 0
        dragBaseCenter = capsule.center
        startFrameReporting()
    }

    private func dragChanged(_ capsule: ToastCapsule, translation: CGFloat) {
        guard draggedCapsule === capsule else { return }
        dragTranslation = translation
        applyDrag()
    }

    private func dragEnded(_ capsule: ToastCapsule, translation: CGFloat, velocity: CGFloat) {
        guard draggedCapsule === capsule else { return }

        dragTranslation = translation
        let outcome = ToastDrag.outcome(offset: translation, velocity: velocity)
        draggedCapsule = nil

        switch outcome {
        case .springBack:
            springBack()
        case .dismiss(let direction):
            capsule.dragDismissDirection = direction
            onDismiss?(capsule.id)
            stopFrameReportingIfIdle()
        }
    }

    /// The dragged capsule trails the finger and dims towards the threshold.
    /// The rest of the stack stays where it is.
    private func applyDrag() {
        guard let draggedCapsule else { return }
        draggedCapsule.center = CGPoint(
            x: dragBaseCenter.x,
            y: dragBaseCenter.y + dragTranslation
        )
        draggedCapsule.alpha = 1 - 0.3 * min(1, abs(dragTranslation) / 120)
    }

    // MARK: - Frame reporting

    private func startFrameReporting() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(reportFrames))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func reportFrames() {
        onFramesInvalidated?()
    }

    private func stopFrameReportingIfIdle() {
        guard animator == nil, draggedCapsule == nil else { return }
        displayLink?.invalidate()
        displayLink = nil
    }
}
