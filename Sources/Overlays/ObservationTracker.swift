//
//  ObservationTracking.swift
//

import Observation

/// Re-arms `withObservationTracking` so a view controller can render from an
/// `@Observable` model: call `start()` once; `apply` runs immediately and again
/// after every change to anything it reads.
///
///     private lazy var tracker = ObservationTracker { [weak self] in
///         self?.render()
///     }
///     // viewDidLoad: tracker.start()
///
@MainActor
final class ObservationTracker {
    private let apply: () -> Void
    private var isCancelled = false

    init(apply: @escaping () -> Void) {
        self.apply = apply
    }

    func start() {
        guard !isCancelled else { return }
        withObservationTracking { [apply] in
            apply()
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.start()
            }
        }
    }

    func cancel() {
        isCancelled = true
    }
}
