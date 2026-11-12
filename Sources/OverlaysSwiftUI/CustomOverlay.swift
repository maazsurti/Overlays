import SwiftUI

public struct CustomOverlay: Identifiable, Equatable {
    public let id: UUID
    public let allowsPassthrough: Bool

    private let makeContent: @MainActor (_ dismiss: @escaping @MainActor () -> Void) -> AnyView

    public init<Content: View>(
        id: UUID = UUID(),
        allowsPassthrough: Bool = false,
        @ViewBuilder content: @escaping @MainActor (_ dismiss: @escaping @MainActor () -> Void) -> Content
    ) {
        self.id = id
        self.allowsPassthrough = allowsPassthrough
        self.makeContent = { dismiss in AnyView(content(dismiss)) }
    }

    @MainActor
    func content(dismiss: @escaping @MainActor () -> Void) -> AnyView {
        makeContent(dismiss)
    }

    public static func == (lhs: CustomOverlay, rhs: CustomOverlay) -> Bool {
        lhs.id == rhs.id
    }
}
