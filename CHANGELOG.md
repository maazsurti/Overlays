# Changelog

## 1.3.5

- A bottom toast is placed against the clearance current when it is placed: the stack reads
  `bottomChromeInset` before it positions a new pill, so the pill enters and rests at the gap its
  chrome gives it.
- An inset that changes while a pill is entering is applied once the spring ends, moving the pill
  to its new slot without restarting the entrance.

## 1.3.4

- A bottom toast sits 12pt above the chrome that holds the bottom of the screen — the keyboard
  while it is up, the value of `toastStore.bottomChromeInset` otherwise. A bar that dips into the
  bottom safe area publishes its height above that safe area, so the gap stays 12pt over the bar
  and over the safe area alone.
- Bottom toasts sit on a gradient scrim, set by `toastScrimColor`, `toastScrimOpacity` and
  `toastScrimHeightFraction`. It fades in with the first bottom toast and out with the last, never
  takes a touch, and appears without a fade under Reduce Motion.
- The pill carries a 0.5pt hairline border, a tighter shadow, a 16pt semibold message over 10pt
  vertical margins, 12pt between glyph and text, and a 32pt entrance.
- `OverlaysSwiftUI` mirrors the placement, the scrim and the pill's metrics.
