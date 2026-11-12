import Testing
import UIKit
@testable import Overlays

@MainActor
struct OverlayThemeTests {

    // Every overlay reads `OverlayTheme.current` while drawing; if building the default theme
    // touched `current` itself, the first overlay would trap the app at launch.
    @Test func defaultThemeBuildsWithoutReadingItself() {
        let theme = OverlayTheme()
        #expect(theme.infoIcon != nil)
        #expect(OverlayTheme.current.okTitle == "OK")
    }

    // An app's theme replaces the defaults it names and keeps the rest.
    @Test func appThemeOverridesOnlyWhatItSets() {
        let original = OverlayTheme.current
        defer { OverlayTheme.current = original }

        OverlayTheme.current = OverlayTheme(accent: .systemYellow, okTitle: "حسنا")
        #expect(OverlayTheme.current.accent == .systemYellow)
        #expect(OverlayTheme.current.okTitle == "حسنا")
        #expect(OverlayTheme.current.cancelTitle == "Cancel")
    }
}
