//
//  CustomOverlay.swift
//

import UIKit

/// An overlay shown in `OverlayCenter`'s shared custom-overlay slot: a view
/// built on demand, plus whether touches fall through to the app below it.
///
/// The content closure receives the `dismiss` closure that clears the slot, the
/// UIKit replacement for the SwiftUI `\.dismissOverlay` environment key.
struct CustomOverlay: Identifiable, Equatable {
    let id: UUID
    let allowsPassthrough: Bool

    private let makeContent: @MainActor (_ dismiss: @escaping @MainActor () -> Void) -> UIView

    init(
        id: UUID = UUID(),
        allowsPassthrough: Bool = false,
        content: @escaping @MainActor (_ dismiss: @escaping @MainActor () -> Void) -> UIView
    ) {
        self.id = id
        self.allowsPassthrough = allowsPassthrough
        self.makeContent = content
    }

    @MainActor
    func content(dismiss: @escaping @MainActor () -> Void) -> UIView {
        makeContent(dismiss)
    }

    static func == (lhs: CustomOverlay, rhs: CustomOverlay) -> Bool {
        lhs.id == rhs.id
    }
}
