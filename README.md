# Overlays

Toasts, modal alerts and a blocking loading card for UIKit apps, each drawn in its own window
above the app, so they show over sheets, covers and navigation without any screen owning them.

## Install

```swift
.package(url: "https://github.com/maazsurti/Overlays.git", from: "1.3.3")
```

## Products

- **`Overlays`** — UIKit. Everything below.
- **`OverlaysSwiftUI`** — the same toasts, alerts and loading card for SwiftUI apps built on
  `SimpleRouterSwiftUI`. Set `OverlayTheme.current` (SwiftUI `Color`/`Font`/`Image`, plus `locale`
  and `layoutDirection` closures for RTL) and attach the hosts on your root view:

  ```swift
  @State private var overlays = OverlayCenter.shared

  RootContent()
      .overlayAdapter($overlays.toastStore, adapter: ToastAdapter())
      .overlayAdapter($overlays.overlay, adapter: CustomOverlayAdapter())
  ```

  Titles are `LocalizedStringKey`s, so they translate through your app's own string catalog.

## Set up

Attach once, after your main window exists, and give it your app's look:

```swift
import Overlays

OverlayTheme.current = OverlayTheme(
    accent: .brandYellow,
    surface: .white,
    text: .ink,
    font: { weight, size in .appFont(weight, size) },
    successIcon: UIImage(named: "check-circle"),
    loadingGlyph: UIImage(named: "logo-mark"),
    okTitle: String(localized: "OK"),
    cancelTitle: String(localized: "Cancel"),
    pleaseWaitText: String(localized: "Please wait"),
    loadingCaption: String(localized: "Just a moment"),
    isRightToLeft: { Locale.current.language.characterDirection == .rightToLeft }
)

OverlayCenter.shared.attach(to: windowScene)
```

Every value has a system default, so `OverlayTheme()` works as-is.

## Use

```swift
// Toasts enter from their edge, stack, auto-dismiss, and swipe away either way.
OverlayCenter.shared.showToast("Profile saved", style: .success)
OverlayCenter.shared.showToast("Please enter your email", style: .warning, placement: .bottom)

// A blocking loading card: dimmed screen, a spinning accent ring around the glyph,
// a message over a caption. Omit the caption to draw the theme's.
OverlayCenter.shared.showLoading(message: "Saving…", caption: "Just a moment")
defer { OverlayCenter.shared.dismissLoading() }

// Modal alerts for questions that need an answer.
OverlayCenter.shared.showModalAlert(.confirm(
    icon: .warning,
    title: "Delete this item?",
    confirmTitle: "Delete",
    isDestructive: true,
    onConfirm: { delete() }
))

// Any view of your own in the same overlay slot.
OverlayCenter.shared.showOverlay { dismiss in
    MyPromoCard(onClose: dismiss)
}
```

`OverlayWindowPresenter` is public too, for a permanent banner of your own above the app (pass
`allowsPassthrough: true` to let touches through around it).

### Behaviour

- Toasts: four styles (`info`, `success`, `warning`, `error`), top or bottom placement, and a
  five-second life of their own. A toast enters from its edge and leaves back towards the same
  one. An arrival or departure moves the whole stack in one spring, so the survivors slide to
  their new slots in the same frame.
- A stack overlaps in depth: the toast nearest the edge is full size, and each one behind it is a
  little smaller and tucked under its neighbour.
- Drag a toast either way to dismiss it: past 40pt, or with a flick. A short drag springs back,
  and only the toast under the finger moves. A pill keeps the size its message was fitted to for
  the whole gesture, wherever it travels, so its text never re-wraps. Only the capsules take
  touches.
- Reduce Motion: toasts cross-fade in place, and nothing travels.
- Cancellation errors (`Cancelled`, `CancellationError`, `NSURLErrorDomain -999`) are dropped
  instead of shown.
- Loading card: a ring, its glyph, a message and a caption, on one card that takes the height
  of the lines it shows. It cannot be tapped away; it goes when you dismiss it. Reduce Motion
  stops the spin. VoiceOver reads the card as one element, its lines once.
- Overlays follow `isRightToLeft` for their layout direction.

## Requirements

iOS 17+, Swift 6 tools (Swift 5 language mode).
