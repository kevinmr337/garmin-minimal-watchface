---
name: garmin-connect-iq
description: Use when working on this repo's Monkey C source, app lifecycle, or Toybox API usage — i.e. any change inside source/*.mc or questions about how the watch face's App/View classes fit together.
---

# garmin-connect-iq

## When to use this skill
Before editing anything under `source/`, or when asked how the app starts up, what class does what, or
which Toybox modules are in play.

## What it covers
The three `.mc` files and how they relate. Does not cover rendering details (see `garmin-ui`) or
performance/battery concerns (see `garmin-performance`).

## Important files
- `manifest.xml` — declares `type="watchface"`, `entry="minimal_venu3_faceApp"`, `minApiLevel="3.0.0"`,
  target products, and (currently empty) permissions.
- `monkey.jungle` — one line: `project.manifest = manifest.xml`. No custom jungle source paths,
  resource excludes, or per-device overrides are configured.
- `source/minimal-venu3-faceApp.mc` — `Application.AppBase` subclass. `getInitialView()` returns
  `[ new minimal_venu3_faceView() ]` — a single view, no `InputDelegate`.
- `source/minimal-venu3-faceView.mc` — `WatchUi.WatchFace` subclass; all rendering logic (see `garmin-ui`).
- `source/minimal-venu3-faceBackground.mc` — **dead code**, a `WatchUi.Drawable` subclass never
  instantiated (nothing calls `setLayout`). Don't extend it under the assumption it's live.

## How it works
Standard Connect IQ watch-face lifecycle: the system constructs the `AppBase`, calls `getInitialView()`
once, then drives the returned `WatchFace` view through `onLayout` → `onShow` → `onUpdate` (once per
minute or on settings change) → `onPartialUpdate` (once per second while active/AOD, when supported) →
`onHide`. This repo only overrides `onLayout`, `onUpdate`, and `onPartialUpdate` — no `onShow`/`onHide`/
`onEnterSleep`/`onExitSleep` are implemented, so there is no sleep/wake-specific behavior (e.g. reduced
detail while sleeping) beyond what `onPartialUpdate` does.

Toybox modules actually imported and used: `WatchUi`, `Graphics`, `System` (imported but currently
unused — `Sys` alias exists with no call sites), `Lang`, `Time`, `Time.Gregorian`, `ActivityMonitor`,
`Math`, `Application` (via `getApp()`/`getProperty()`, not directly imported in the view file).
`Toybox.Background`, `Toybox.UserProfile`, and `Toybox.Communications` are **not** used anywhere.

## Invariants that must remain true
- `getInitialView()` must keep returning exactly one `WatchFace`-derived view — this is a watch face,
  not a multi-view app; adding a second view changes the app type's expected behavior.
- `onSettingsChanged()` in the App class must keep calling `WatchUi.requestUpdate()`, or property edits
  made in the Garmin Connect companion app won't be reflected until the next natural redraw.
- Every `Toybox.*` import must correspond to at least one real call site — this repo intentionally keeps
  the import list matched to actual usage; don't import modules speculatively.

## Common mistakes to avoid
- Assuming `layout.xml`/`Background.mc` are live — they are not (verified by grep, no `setLayout` call
  anywhere). Don't add UI elements there expecting them to render.
- Adding a manifest permission (`Background`, `UserProfile`, etc.) without a matching Toybox API call —
  the manifest previously requested both with no corresponding usage; this was removed as a finding.

## How to validate changes
No SDK is installed in most cloud/sandbox sessions (`which monkeyc` returns nothing here). If the SDK is
available, build with `./run.sh` (see `garmin-build`). Without it: re-read the diff for balanced
braces/parens, and cross-check every new API call against a Toybox module already imported in the file
(or add the corresponding `import`/`using`).

## Related skills
`garmin-ui` (rendering), `garmin-data` (settings/properties), `garmin-build` (compiling this code).
