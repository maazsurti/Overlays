# Changelog

## 1.3.11

- `toastLineHeight` sets the message's line height in points, with the glyphs centred in each line;
  `toastLineHeightMultiple` still scales the font's natural line height when it is nil.
- `toastContentInsets` sets the pill's content insets, and `toastTextLeadingInset` the leading edge
  when no glyph is drawn. Both default to the previous values.
- `toastGlyphSpacing` sets the space between the glyph and the message. Default 12.

## 1.3.10

- `toastHorizontalMargin` sets the pill's margin from each screen edge, replacing the fixed 16pt.
- `toastFillsWidth` makes the pill span the width the margin leaves instead of fitting its message.
  Default `false`.
- `toastLineHeightMultiple` sets the message's line height as a multiple of its size. Default `1`.

## 1.3.9

- The toast pill's chrome moves to `OverlayTheme`: `toastSurface`, `toastTextColor`,
  `toastBorderColor`, `toastBorderWidth`, `toastCornerRadius`, `toastShowsGlyph`, `toastFontSize`
  and `toastFontWeight`. Every default keeps the white pill at 16pt.
- With `toastShowsGlyph` off, the pill drops the tinted circle and narrows to a 16pt text inset, so
  a theme can draw a plain message pill.

## 1.3.8

- Top toasts get the scrim the bottom ones had: `ToastScrimView` takes an edge, and the toast host
  runs one scrim per placement, each fading in with the first toast at its edge and out with the
  last.
- A scrim is sized from its stack, covering `toastScrimPadding` past the outermost capsule and
  following an entrance, an exit and a reflow; `toastScrimHeightFraction` is now its shortest height
  rather than its only height. `toastScrimPadding` is new, at 120pt.
- An error toast strengthens its scrim to the new `toastScrimErrorOpacity` (0.6) and back, on the
  same fade timing.
- While the top scrim is up, the toast window's root controller answers the status bar with the new
  `toastScrimStatusBarStyle` (`.lightContent`), and hands it back when the scrim leaves.
- `toastScrimBlurStyle` puts a blur under each scrim, masked by the same gradient, hidden while the
  scrim is off screen, and skipped under Reduce Transparency. Default is `nil`.
- `toastHaptics` fires `.error` or `.warning` once per error or warning toast arrival. Default is
  `false`.
- `OverlaysSwiftUI` mirrors the top scrim, the sizing, the error opacity and the blur. The status
  bar and haptics stay in the UIKit target.

## 1.3.7

- The README opens with the problem the package solves, what each overlay looks like on screen, when
  to use it and the `SimpleRouterSwiftUI` requirement of the SwiftUI product, before the feature
  list.
- No code changes.

## 1.3.6

- README rewritten around the package itself: what each overlay is, what it looks like, quick starts
  for UIKit and SwiftUI, one reference section per overlay, and the behaviour notes last.
- No code changes.

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
