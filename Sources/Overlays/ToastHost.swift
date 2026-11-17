//
//  ToastHost.swift
//

import UIKit

/// The toast window's content: one stack per placement, driven by a
/// `ToastStore`, plus the frames of the capsules it is showing so the window
/// can restrict hit testing to them.
@MainActor
final class ToastHost: UIView {

    private let store: ToastStore
    private let onFramesChange: ([CGRect]) -> Void

    private let scrim = ToastScrimView()
    private let topStack = ToastStackView(placement: .top)
    private let bottomStack = ToastStackView(placement: .bottom)

    private var scrimHeight: NSLayoutConstraint?
    private var bottomCount = 0

    private lazy var tracker = ObservationTracker { [weak self] in
        self?.render()
    }

    init(store: ToastStore, onFramesChange: @escaping ([CGRect]) -> Void = { _ in }) {
        self.store = store
        self.onFramesChange = onFramesChange
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubviews(scrim, topStack, bottomStack)
        topStack.pinEdgesToSuperview()
        bottomStack.pinEdgesToSuperview()
        NSLayoutConstraint.activate([
            scrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrim.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        let height = scrim.heightAnchor.constraint(equalToConstant: 0)
        height.isActive = true
        scrimHeight = height

        topStack.onDismiss = { [weak store] id in store?.dismiss(id) }
        bottomStack.onDismiss = { [weak store] id in store?.dismiss(id) }
        topStack.onFramesInvalidated = { [weak self] in self?.setNeedsLayout() }
        bottomStack.onFramesInvalidated = { [weak self] in self?.setNeedsLayout() }

        tracker.start()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("The app builds its UI in code; init(coder:) is not supported")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrimHeight?.constant = bounds.height * OverlayTheme.current.toastScrimHeightFraction
        reportCapsuleFrames()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else {
            observeKeyboard(false)
            return
        }
        observeKeyboard(true)
    }

    // MARK: - Private

    /// Re-reads the store: the toasts per placement, the main tab shell's
    /// bottom clearance, and whether the scrim belongs on screen.
    private func render() {
        OverlayDirection.apply(to: window)

        let bottom = store.toasts.filter { $0.placement == .bottom }
        // The clearance is part of where a pill goes, so it reaches the stack
        // before the stack places anything: a new pill starts against the
        // chrome it lives above, not the one from the previous render.
        bottomStack.bottomInset = store.bottomChromeInset
        topStack.update(with: store.toasts.filter { $0.placement == .top })
        bottomStack.update(with: bottom)

        scrim.applyTheme()
        let transition = ToastScrimTransition.between(before: bottomCount, after: bottom.count)
        bottomCount = bottom.count
        apply(transition)
    }

    private func apply(_ transition: ToastScrimTransition) {
        guard transition != .none else { return }

        let visible = transition == .fadeIn
        guard !UIAccessibility.isReduceMotionEnabled else {
            scrim.alpha = visible ? 1 : 0
            return
        }

        let duration = visible
            ? ToastScrimTransition.fadeInDuration
            : ToastScrimTransition.fadeOutDuration
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]
        ) {
            self.scrim.alpha = visible ? 1 : 0
        }
    }

    /// The toast window sits below the keyboard, so the stack measures the
    /// keyboard itself rather than leaving a bottom toast behind it.
    private func observeKeyboard(_ observing: Bool) {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        guard observing else { return }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameWillChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardFrameWillChange(_ notification: Notification) {
        guard
            let end = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        let frame = convert(end, from: nil)
        bottomStack.keyboardInset = max(0, bounds.maxY - frame.minY)
    }

    private func reportCapsuleFrames() {
        onFramesChange(topStack.capsuleFrames(in: self) + bottomStack.capsuleFrames(in: self))
    }
}
