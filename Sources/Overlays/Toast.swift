import Foundation

struct Toast: Identifiable, Equatable, Sendable {
    let id: UUID
    let message: String
    let style: ToastStyle
    let placement: ToastPlacement
    let duration: TimeInterval

    init(
        id: UUID = UUID(),
        message: String,
        style: ToastStyle = .info,
        placement: ToastPlacement = .top,
        duration: TimeInterval = 2.5
    ) {
        self.id = id
        self.message = message
        self.style = style
        self.placement = placement
        self.duration = duration
    }
}
