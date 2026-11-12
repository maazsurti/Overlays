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

    private let topStack = ToastStackView(placement: .top)
    private let bottomStack = ToastStackView(placement: .bottom)

    private lazy var tracker = ObservationTracker { [weak self] in
        self?.render()
    }

    init(store: ToastStore, onFramesChange: @escaping ([CGRect]) -> Void = { _ in }) {
        self.store = store
        self.onFramesChange = onFramesChange
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubviews(topStack, bottomStack)
        topStack.pinEdgesToSuperview()
        bottomStack.pinEdgesToSuperview()

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

    override func layoutSubviews() {
        super.layoutSubviews()
        reportCapsuleFrames()
    }

    // MARK: - Private

    /// Re-reads the store: the toasts per placement, and the main tab shell's
    /// bottom clearance.
    private func render() {
        OverlayDirection.apply(to: window)
        topStack.update(with: store.toasts.filter { $0.placement == .top })
        bottomStack.update(with: store.toasts.filter { $0.placement == .bottom })
        bottomStack.bottomInset = store.bottomChromeInset
    }

    private func reportCapsuleFrames() {
        onFramesChange(topStack.capsuleFrames(in: self) + bottomStack.capsuleFrames(in: self))
    }
}
