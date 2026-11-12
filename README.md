# Overlays

Toasts, modal alerts and a blocking loading card for UIKit apps, each drawn in its own window
above the app, so they show over sheets, covers and navigation without any screen owning them.

## Install

```swift
.package(url: "https://github.com/maazsurti/Overlays.git", from: "1.0.0")
```

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
    isRightToLeft: { Locale.current.language.characterDirection == .rightToLeft }
)

OverlayCenter.shared.attach(to: windowScene)
```

Every value has a system default, so `OverlayTheme()` works as-is.

## Use

```swift
// Toasts stack, auto-dismiss, and swipe away.
OverlayCenter.shared.showToast("Profile saved", style: .success)
OverlayCenter.shared.showToast("Please enter your email", style: .warning, placement: .bottom)

// A blocking loading card: dimmed screen, spinning accent ring, optional message.
OverlayCenter.shared.showLoading(message: "Saving…")
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

- Toasts: four styles (`info`, `success`, `warning`, `error`), top or bottom placement, a stack
  that springs in and out, drag to dismiss. Cancellation errors (`Cancelled`,
  `CancellationError`, `NSURLErrorDomain -999`) are dropped instead of shown.
- Loading card: cannot be tapped away; it goes when you dismiss it. Reduce Motion stops the spin.
- Overlays follow `isRightToLeft` for their layout direction.

## Requirements

iOS 17+, Swift 6 tools (Swift 5 language mode).
