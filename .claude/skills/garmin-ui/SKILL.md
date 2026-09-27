---
name: garmin-ui
description: Use when changing what's drawn on screen, adding/removing icons or text, or touching resources/layouts, resources/drawables, or the onUpdate/drawDial/drawHands/drawHand methods.
---

# garmin-ui

## When to use this skill
Before editing `onUpdate`, `drawDial`, `drawHands`, `drawHand` in `minimal-venu3-faceView.mc`, or any
file under `resources/drawables/` or `resources/layouts/`.

## What it covers
Rendering architecture and resource wiring. For device-shape risk in these coordinates, see
`garmin-device-compatibility`; for redraw-frequency/battery cost, see `garmin-performance`.

## Important files
- `source/minimal-venu3-faceView.mc` — all drawing. Draw order in `onUpdate` (later = on top): clear →
  `drawDial` (60 minute ticks + 12 hour ticks, pen widths 1 and 5) → date/day text → digital time text →
  notification/steps/calories/heart-rate icon+text rows → `drawHands` (hour, minute, second hands, then
  a filled hub circle on top of everything).
- `resources/drawables/drawables.xml` — declares every bitmap id (`icon_heart`, `icon_steps`,
  `icon_flame`, `icon_notif`, `icon_sun`, `icon_moon`, `LauncherIcon`). Every id here must have a
  matching `Ui.loadResource(Rez.Drawables.<id>)` call in `initialize()` to actually be used, and every
  loaded bitmap should have a corresponding `drawBitmap` call — check both directions when adding or
  removing an icon (a declared-but-never-loaded resource is wasted flash; a loaded-but-never-drawn one is
  wasted RAM, as `test.png`/`icon_test` was before removal).
- `resources/layouts/layout.xml`, `source/minimal-venu3-faceBackground.mc` — **dead**, not wired via
  `setLayout`. Confirmed dead by grep for `setLayout`/`Rez.Layouts` across `source/`. Don't add new UI
  here expecting it to render; either finish wiring the layout system in properly or remove these files
  (removal was withheld in the last audit pending explicit user approval — ask before deleting).
- `resources/settings/properties.xml` / `settings.xml` — `BackgroundColor`, `ForegroundColor` (raw
  `0xRRGGBB` numbers, no alpha), `UseMilitaryFormat` (boolean). Read once per `onUpdate` call via
  `getApp().getProperty(...)` and stored in the view's `bg`/`fg` instance fields, which every draw method
  reads instead of hardcoding `Graphics.COLOR_WHITE`. See `garmin-data` for the settings side.
- Only `Graphics.FONT_XTINY` is used anywhere — no custom font resources exist in `resources/`.

## Invariants that must remain true
- `fg`/`bg` are set once at the top of `onUpdate` from properties and must stay the single source of
  truth for the dial/hands/text color — don't reintroduce a hardcoded `Graphics.COLOR_WHITE` or a
  hand-picked `Graphics.createColor(...)` literal for these elements; that's the exact bug this audit
  fixed (user color settings were previously ignored).
- `drawHands` must be called last in `onUpdate` — hands are meant to render on top of the dial/text, per
  the existing "AL FINAL" comment.

## Common mistakes to avoid
- Loading a bitmap in `initialize()` without ever calling `drawBitmap` for it (see `iconSun`/`iconMoon`:
  loaded, day/night bitmap computed, but the actual `drawBitmap` call is commented out — a known
  unfinished feature, not something to "clean up" without checking with the user first).
- Setting color via `dc.setColor(...)` in one method and relying on that state leaking into a later
  method's drawing calls (this repo used to rely on `drawDial`'s trailing color state to color the
  text block that followed it — now made explicit; keep new code explicit about color rather than
  relying on call-order side effects).

## How to validate changes
Visual changes require the simulator (no SDK in this sandbox — see `garmin-build`). At minimum, before
claiming a rendering change is correct: re-check every `drawBitmap`/`drawText` call still receives
coordinates derived from `_w`/`_h`/`_cx`/`_cy` where intended, and that no bitmap is loaded without a
render call (or vice versa).

## Related skills
`garmin-data` (settings → `fg`/`bg`), `garmin-device-compatibility` (coordinate safety across devices),
`garmin-performance` (redraw cost of this code).
