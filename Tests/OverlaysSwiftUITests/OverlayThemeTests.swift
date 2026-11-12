import SwiftUI
import Testing
@testable import OverlaysSwiftUI

@MainActor
struct OverlayThemeTests {

    // Every overlay reads `OverlayTheme.current` while drawing; building the default theme must
    // not read it back, or the first overlay traps the app.
    @Test func defaultThemeBuildsWithoutReadingItself() {
        let theme = OverlayTheme()
        #expect(theme.layoutDirection() == .leftToRight)
        #expect(OverlayTheme.current.makePrimaryButton == nil)
    }

    // An app's direction rule reaches the overlays: Arabic lays them out right to left.
    @Test func appDirectionReplacesTheDefault() {
        let original = OverlayTheme.current
        defer { OverlayTheme.current = original }

        OverlayTheme.current = OverlayTheme(layoutDirection: { .rightToLeft })
        #expect(OverlayTheme.current.layoutDirection() == .rightToLeft)
    }
}
