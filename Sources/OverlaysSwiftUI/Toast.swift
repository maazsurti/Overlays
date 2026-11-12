import Foundation

public struct Toast: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let message: String
    public let style: ToastStyle
    public let placement: ToastPlacement
    public let duration: TimeInterval

    public init(
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
