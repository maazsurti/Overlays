//
//  ToastHost.swift
//

import UIKit

/// The toast window's content: one stack per placement, driven by a
/// `ToastStore`, the scrim behind each stack, plus the frames of the capsules it
/// is showing so the window can restrict hit testing to them.
@MainActor
final class ToastHost: UIView {

    private let store: ToastStore
    private let onFramesChange: ([CGRect]) -> Void

    private let topScrim = ToastScrimView(edge: .top)
    private let bottomScrim = ToastScrimView(edge: .bottom)
    private let topStack = ToastStackView(placement: .top)
    private let bottomStack = ToastStackView(placement: .bottom)

    private var topScrimHeight: NSLayoutConstraint?
    private var bottomScrimHeight: NSLayoutConstraint?
    private var topCount = 0
    private var bottomCount = 0

    private let haptic = UINotificationFeedbackGenerator()
    private var notified: Set<UUID> = []

    private lazy var tracker = ObservationTracker { [weak self] in
        self?.render()
    }

    init(store: ToastStore, onFramesChange: @escaping ([CGRect]) -> Void = { _ in }) {
        self.store = store
        self.onFramesChange = onFramesChange
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubviews(topScrim, bottomScrim, topStack, bottomStack)
        topStack.pinEdgesToSuperview()
        bottomStack.pinEdgesToSuperview()
        NSLayoutConstraint.activate([
            topScrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            topScrim.trailingAnchor.constraint(equalTo: trailingAnchor),
            topScrim.topAnchor.constraint(equalTo: topAnchor),
            bottomScrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomScrim.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomScrim.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        topScrimHeight = topScrim.heightAnchor.constraint(equalToConstant: 0)
        bottomScrimHeight = bottomScrim.heightAnchor.constraint(equalToConstant: 0)
        topScrimHeight?.isActive = true
        bottomScrimHeight?.isActive = true

        topStack.onDismiss = { [weak store] id in store?.dismiss(id) }
        bottomStack.onDismiss = { [weak store] id in store?.dismiss(id) }
        topStack.onFramesInvalidated = { [weak self] in self?.setNeedsLayout() }
        bottomStack.onFramesInvalidated = { [weak self] in self?.setNeedsLayout() }

        haptic.prepare()
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

        // Sized from where the capsules are being drawn, so the scrim travels
        // with a stack that is entering, leaving or reflowing.
        let theme = OverlayTheme.current
        let minimum = bounds.height * theme.toastScrimHeightFraction
        topScrimHeight?.constant = ToastScrimLayout.height(
            edge: .top,
            hostHeight: bounds.height,
            capsuleFrames: topStack.capsuleFrames(in: self),
            padding: theme.toastScrimPadding,
            minimum: minimum
        )
        bottomScrimHeight?.constant = ToastScrimLayout.height(
            edge: .bottom,
            hostHeight: bounds.height,
            capsuleFrames: bottomStack.capsuleFrames(in: self),
            padding: theme.toastScrimPadding,
            minimum: minimum
        )
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
    /// bottom clearance, and whether each scrim belongs on screen.
    private func render() {
        OverlayDirection.apply(to: window)

        let top = store.toasts.filter { $0.placement == .top }
        let bottom = store.toasts.filter { $0.placement == .bottom }
        // The clearance is part of where a pill goes, so it reaches the stack
        // before the stack places anything: a new pill starts against the
        // chrome it lives above, not the one from the previous render.
        bottomStack.bottomInset = store.bottomChromeInset
        topStack.update(with: top)
        bottomStack.update(with: bottom)

        let theme = OverlayTheme.current
        let colourDuration = UIAccessibility.isReduceMotionEnabled ? 0 : ToastScrimTransition.fadeInDuration
        for (scrim, toasts) in [(topScrim, top), (bottomScrim, bottom)] {
            scrim.applyTheme()
            scrim.setStrength(
                ToastScrimLayout.opacity(
                    for: toasts.map(\.style),
                    normal: theme.toastScrimOpacity,
                    error: theme.toastScrimErrorOpacity
                ),
                duration: colourDuration
            )
        }
        apply(ToastScrimTransition.between(before: topCount, after: top.count), to: topScrim)
        apply(ToastScrimTransition.between(before: bottomCount, after: bottom.count), to: bottomScrim)
        updateStatusBar(withTopToasts: !top.isEmpty)
        fireHaptics(for: top + bottom)
        topCount = top.count
        bottomCount = bottom.count
    }

    private func apply(_ transition: ToastScrimTransition, to scrim: ToastScrimView) {
        guard transition != .none else { return }

        let visible = transition == .fadeIn
        let duration = UIAccessibility.isReduceMotionEnabled
            ? 0
            : (visible ? ToastScrimTransition.fadeInDuration : ToastScrimTransition.fadeOutDuration)
        scrim.fade(to: visible, duration: duration)
    }

    /// Hands the status bar style to the toast window's root controller while the
    /// top scrim is up. The window never takes key, so touches and the app's own
    /// status bar style are untouched.
    private func updateStatusBar(withTopToasts visible: Bool) {
        guard let host = window?.rootViewController as? OverlayHostViewController else { return }
        let style = visible ? OverlayTheme.current.toastScrimStatusBarStyle : nil
        guard host.statusBarStyleOverride != style else { return }
        host.statusBarStyleOverride = style
    }

    /// One notification haptic per error or warning toast that has just arrived,
    /// never for a re-render of a toast already on screen.
    private func fireHaptics(for toasts: [Toast]) {
        let arrivals = toasts.filter { !notified.contains($0.id) }
        notified = Set(toasts.map(\.id))
        guard OverlayTheme.current.toastHaptics else { return }

        for toast in arrivals {
            switch toast.style {
            case .error:
                haptic.notificationOccurred(.error)
            case .warning:
                haptic.notificationOccurred(.warning)
            case .info, .success:
                continue
            }
            haptic.prepare()
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
