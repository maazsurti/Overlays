import Foundation
import Observation

@MainActor
@Observable
public final class ToastStore {
    private(set) var toasts: [Toast] = []
    public var maxVisible: Int
    public var bottomChromeInset: CGFloat = 0

    private var dismissTasks: [UUID: Task<Void, Never>] = [:]

    public init(maxVisible: Int = 3) {
        self.maxVisible = maxVisible
    }

    public func show(_ toast: Toast) {
        guard shouldPresent(toast) else { return }
        toasts.append(toast)
        trim(placement: toast.placement)

        guard toast.duration > 0 else { return }
        dismissTasks[toast.id] = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(toast.duration))
            guard !Task.isCancelled else { return }
            self?.dismiss(toast.id)
        }
    }

    public func show(
        _ message: String,
        style: ToastStyle = .info,
        placement: ToastPlacement = .top,
        duration: TimeInterval = 2.5
    ) {
        show(Toast(message: message, style: style, placement: placement, duration: duration))
    }

    public func dismiss(_ id: UUID) {
        cancel(id)
        toasts.removeAll { $0.id == id }
    }

    public func dismissAll() {
        dismissTasks.values.forEach { $0.cancel() }
        dismissTasks.removeAll()
        toasts.removeAll()
    }

    private func trim(placement: ToastPlacement) {
        let ids = toasts.filter { $0.placement == placement }.map(\.id)
        guard ids.count > maxVisible else { return }
        for id in ids.prefix(ids.count - maxVisible) {
            dismiss(id)
        }
    }

    private func cancel(_ id: UUID) {
        dismissTasks[id]?.cancel()
        dismissTasks[id] = nil
    }

    private func shouldPresent(_ toast: Toast) -> Bool {
        guard toast.style == .error else { return true }
        let message = toast.message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if message == "cancelled" || message == "canceled" { return false }
        if message.contains("cancellationerror") { return false }
        let hasCancelledURLCode = message.range(
            of: #"(?<!\d)-999(?!\d)"#,
            options: .regularExpression
        ) != nil
        if message.contains("nsurlerrordomain") && hasCancelledURLCode { return false }
        return true
    }
}
