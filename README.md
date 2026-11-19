# Overlays

Toasts, modal alerts and a loading card for iOS, in UIKit or SwiftUI.

Each overlay is drawn in a window of its own above the app, so it shows over a sheet, a full-screen
cover or a pushed screen without any screen owning it. Nothing in your view hierarchy has to make
room for it.

## What you get

- **Toasts** — four styles (`info`, `success`, `warning`, `error`) from the top or bottom edge. They
  stack, dismiss themselves after five seconds, and swipe away in either direction.
- **Modal alerts** — a dimmed backdrop and a card with an optional icon, title, message and one or
  more buttons. Presets cover a one-button notice and a confirm/cancel.
- **A loading card** — a dimmed screen with a spinner, a message and a caption, so a blocking wait
  has one standard look.
- **Custom overlays** — any `UIView` or SwiftUI view in the same slot, with the same window
  behaviour.
- **Your theme** — colours, type and icons set once at launch.
- **Right-to-left** — each overlay window takes its direction from the theme.
- **Reduce Motion** — toasts change in place without travelling, and the UIKit loading ring stops.
- **VoiceOver** — the loading card is read as one element, its lines once.
- **Cancellation errors** — an `.error` toast for a cancelled task is dropped instead of shown.

## Requirements

- iOS 17 or later.
- Swift 6 tools, Swift 5 language mode.
- Xcode 16 or later.

## Installation

In Xcode: **File ▸ Add Package Dependencies…**, paste
`https://github.com/maazsurti/Overlays.git`, then add the product you need.

Or in `Package.swift`:

```swift
.package(url: "https://github.com/maazsurti/Overlays.git", from: "1.3.6")
```

Products:

- **`Overlays`** — UIKit, with no dependencies.
- **`OverlaysSwiftUI`** — SwiftUI, for apps built on `SimpleRouterSwiftUI`. It pulls
  `SimpleRouter` in for the `OverlayAdapter` attachment point.

## Quick start — UIKit

Attach once, after the main window exists:

```swift
import Overlays

OverlayCenter.shared.attach(to: windowScene)
OverlayCenter.shared.showToast("Profile saved", style: .success)
```

Theme it first if you like. Every value has a system default, so `OverlayTheme()` works as-is:

```swift
OverlayTheme.current = OverlayTheme(
    accent: .brandYellow,
    surface: .white,
    text: .ink,
    font: { weight, size in .appFont(weight, size) }
)
```

## Quick start — SwiftUI

Set the theme, then attach the two hosts on your root view:

```swift
import SwiftUI
import OverlaysSwiftUI

@main
struct MyApp: App {
    @State private var overlays = OverlayCenter.shared

    init() {
        OverlayTheme.current = OverlayTheme(accent: .brandYellow, surface: .white, text: .ink)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .overlayAdapter($overlays.toastStore, adapter: ToastAdapter())
                .overlayAdapter($overlays.overlay, adapter: CustomOverlayAdapter())
        }
    }
}
```

Then call the same methods from anywhere:

```swift
OverlayCenter.shared.showToast("Profile saved", style: .success)
```

Alert titles are `LocalizedStringKey`s, so they translate through your app's own string catalog.
Toast messages are plain `String`s.

## Theming

`OverlayTheme.current` is read when an overlay is built, so set it once at launch, before the first
overlay appears.

| Property | Purpose |
| --- | --- |
| `accent`, `onAccent` | Brand colour and the content drawn on it |
| `surface`, `text`, `secondaryText`, `border` | Card and pill colours |
| `success`, `danger` | Glyph tints for the semantic styles |
| `font` | `(OverlayFontWeight, CGFloat) -> UIFont` (UIKit) or `-> Font` (SwiftUI) |
| `successIcon`, `errorIcon`, `warningIcon`, `infoIcon` | Toast and alert glyphs |
| `okTitle`, `cancelTitle` | Default button titles (UIKit) |
| `pleaseWaitText` | VoiceOver label for a loading card with no text (UIKit) |
| `loadingCaption` | Second line of the loading card |
| `isRightToLeft` | Direction for the overlay windows (UIKit) |
| `locale`, `layoutDirection` | Direction and formatting for overlay content (SwiftUI) |
| `toastScrimColor`, `toastScrimOpacity`, `toastScrimHeightFraction` | Gradient behind the bottom toasts |
| `makePrimaryButton` | Replaces the filled primary button in a modal alert |

UIKit uses `UIColor` and `UIImage`; SwiftUI uses `Color` and `Image`.

## Toasts

```swift
OverlayCenter.shared.showToast(_ message: String,
                               style: ToastStyle = .info,
                               placement: ToastPlacement = .top,
                               duration: TimeInterval = 5)

OverlayCenter.shared.dismissToasts()
```

- `style` picks the glyph and tint: `.info`, `.success`, `.warning`, `.error`.
- `placement` is `.top` or `.bottom`.
- `duration` is seconds on screen. `0` keeps the toast until it is dragged away or dismissed.
- Three toasts show per edge; a fourth pushes the oldest out.
- A toast is dropped instead of shown when it is `.error` and its message is a cancellation:
  `Cancelled`, `Canceled`, `CancellationError`, or `NSURLErrorDomain` with code `-999`.

A bottom toast clears your own bottom bar by the height you publish to
`toastStore.bottomChromeInset`; see [Behaviour](#behaviour). The SwiftUI `ToastStore` is public, so
you can also drive a stack yourself with `show(_:)`, `dismiss(_:)` and `dismissAll()`.

## Alerts

```swift
OverlayCenter.shared.showModalAlert(.confirm(
    icon: .warning,
    title: "Delete this item?",
    confirmTitle: "Delete",
    isDestructive: true,
    onConfirm: { delete() }
))

OverlayCenter.shared.showModalAlert(.notice(
    icon: .success,
    title: "Password changed",
    message: "Use your new password next time you log in.",
    buttonTitle: "OK"
))
```

`ModalAlert` has an optional `icon` (`.success`, `.error`, `.warning`, `.info`, or
`.custom(systemName:tint:)`), a `title`, an optional `message`, and a list of `ModalAlertButton`s with
a `.primary`, `.cancel` or `.destructive` role. A button runs its action, then the alert dismisses.
`dismissModalAlert()` closes it without a choice.

## Loading

```swift
OverlayCenter.shared.showLoading(message: "Saving…", caption: "Just a moment")
defer { OverlayCenter.shared.dismissLoading() }
```

`message` and `caption` are both optional. Omit the caption to draw the theme's `loadingCaption`; pass
`""` to show the message alone. In UIKit the card takes no touches and blocks the app until
`dismissLoading()`. In SwiftUI the card covers the screen and a tap dismisses it.

UIKit draws the themed card: a ring around `loadingGlyph`, a message and a caption. SwiftUI draws a
system `ProgressView` on a dark card.

## Custom overlays

```swift
OverlayCenter.shared.showOverlay { dismiss in
    MyPromoCard(onClose: dismiss)
}

OverlayCenter.shared.dismissOverlay()
```

The content is a `UIView` in UIKit and any view in SwiftUI. It receives the `dismiss` closure that
clears the slot. There is one slot: showing a second overlay replaces the first.

`allowsPassthrough: true` makes the whole overlay window inert, so every touch reaches the app below.
It is all or nothing — the window does not forward only the touches outside your content.

## OverlayWindowPresenter

Toasts and custom overlays are presented by `OverlayWindowPresenter`, which is public for an overlay
of your own that lives outside `OverlayCenter` — a permanent banner, a ribbon, a debug panel.

```swift
let presenter = OverlayWindowPresenter()
presenter.attach(to: windowScene)
presenter.present(myBanner, allowsPassthrough: true)
presenter.dismiss()
```

The window sits at level 50: above the app's own window, where sheets and covers live, and below the
keyboard window. The first present fades the window in; `dismiss()` fades it out and tears it down.

The SwiftUI product has its own `OverlayWindowPresenter` that takes the overlay state and finds the
active window scene for you:

```swift
OverlayWindowPresenter().present(myBanner, allowsPassthrough: { _ in true }) { banner in
    BannerView(banner: banner)
}
```

## Behaviour

- **Placement.** A top toast sits 28pt below the top safe area. A bottom toast sits 12pt above
  whatever holds the bottom of the screen: the keyboard while it is up, otherwise the bottom safe area
  plus `toastStore.bottomChromeInset`.
- **Bottom chrome.** `bottomChromeInset` is the height of your own bar above the bottom safe area, and
  `0` when it is out of the way. A bar that dips into the safe area publishes only the part that stands
  proud of it, so the gap stays 12pt over the bar and over the safe area alone. Writing a new inset
  moves the toasts already on screen.
- **Stack.** In UIKit the toast nearest the edge is full size, and each one behind sits 4% smaller and
  14pt further out. An arrival or departure moves the whole stack in one spring.
- **Drag.** Past 40pt in either direction, or a flick of 500pt/s, dismisses a toast. A shorter drag
  springs back, and only the toast under the finger moves. A UIKit pill keeps the size its message was
  fitted to for the whole gesture, so its text never re-wraps.
- **Scrim.** The bottom toasts sit on `toastScrimColor`, at `toastScrimOpacity` on the screen's bottom
  edge and clear at the top of `toastScrimHeightFraction` of the screen. It fades in with the first
  bottom toast and out with the last, and never takes a touch. `toastScrimOpacity: 0` draws none.
- **Reduce Motion.** Toasts cross-fade in place, the scrim appears without a fade, and the UIKit
  loading ring stops spinning.
- **Right to left.** UIKit forces each overlay window's direction from `isRightToLeft`; SwiftUI sets
  the overlay's `locale` and `layoutDirection` from the theme.
- **VoiceOver.** The loading card is one element and its lines are read once.
