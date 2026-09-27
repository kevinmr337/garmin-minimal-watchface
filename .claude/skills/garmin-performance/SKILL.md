---
name: garmin-performance
description: Use when adding anything to onUpdate/onPartialUpdate, loading new resources, or asked to evaluate memory/battery impact — this watch face runs on memory- and battery-constrained wearable hardware, not a phone or desktop.
---

# garmin-performance

## When to use this skill
Before adding a resource load, a sensor read, or any per-frame computation to
`minimal-venu3-faceView.mc`, and whenever asked to assess battery or memory impact.

## What it covers
Repo-specific hot paths and known resource-budget issues. Not a general Garmin performance tutorial —
every point here traces to actual code/resources in this repo.

## Important files & confirmed findings
- `source/minimal-venu3-faceView.mc` `onPartialUpdate(dc)` currently just calls `onUpdate(dc)`. On
  devices/modes where `onPartialUpdate` fires every second (always-on/low-power seconds tick), this means
  a **full redraw** — 72 `drawLine` calls with `Math.sin`/`Math.cos` in `drawDial`, an `ActivityMonitor
  .getInfo()` call, and all icon/text draws — runs once per second, not just the second hand. This is a
  known, not-yet-fixed battery/CPU cost; fixing it properly means using `dc.setClip(...)` to redraw only
  the second-hand region, which needs simulator verification of the clip geometry before trusting it —
  don't ship a clip-region change without visually checking it in the simulator.
- `drawDial` recomputes 60 + 12 `Math.sin`/`Math.cos` calls from scratch on every single `onUpdate`/
  `onPartialUpdate`, even though the dial's tick marks never change. A `Graphics.BufferedBitmap` cache
  (draw once in `onLayout`, blit in `onUpdate`) would remove this per-frame cost, but wasn't implemented
  in this pass — it's moderate-complexity Monkey C API usage that couldn't be compile-verified in this
  sandbox (no SDK). Flag it as a validated-on-paper, not validated-in-simulator, recommendation.
- **Resolved**: `resources/drawables/test.png` was a 1024×1024 (1.27MB) bitmap loaded via
  `Ui.loadResource` in `initialize()` but never drawn anywhere — removed. If you see a large drawable
  reappear, check both that it's actually rendered somewhere and that its pixel dimensions match its
  on-screen size (compare against the ~28–36px icons actually used: `heart.png`, `steps.png`,
  `calories.png`, `notifications.png`).
- `iconSun` (64×64) / `iconMoon` (128×128) are loaded into memory in `initialize()` but the `drawBitmap`
  call for them is commented out in `onUpdate` — live memory cost for an unrendered feature. Not removed
  in this pass since the feature looks intentionally unfinished (see `garmin-ui`); flag to the user
  rather than silently deleting.
- `Act.getInfo()` (ActivityMonitor) is called once per `onUpdate`, wrapped in `try/catch` — reasonable;
  the concern is only the frequency amplification from `onPartialUpdate` calling `onUpdate` every second
  (see above), not the call itself.

## Invariants that must remain true
- No bitmap resource should be loaded (`Ui.loadResource`) without a corresponding render call, and vice
  versa — check both directions (see `garmin-ui`).
- Anything added to `onPartialUpdate` should be justified against "does this need to run every second,
  or only once a minute" — default to the cheaper path.

## Common mistakes to avoid
- Adding string concatenation, object allocation, or sensor/API calls inside `drawDial`/`drawHands`
  (called every `onUpdate`, and currently every second via `onPartialUpdate`) — these are the hottest
  paths in the file.
- Assuming a resource "looks small in the editor" is small on disk — check actual file size and pixel
  dimensions (`python3 -c "import struct; ..."` on the PNG header, or `ls -la`) before committing a new
  drawable; compare against the existing ~28–36px/300–600 byte icons as the baseline for "normal" here.

## How to validate changes
- Resource size/dimension checks can be done without the SDK (file size, PNG header dimensions).
- Actual CPU/battery impact of a redraw-frequency change requires the simulator's power/CPU profiling or
  physical-device testing — not available in this sandbox; say so explicitly rather than claiming a
  performance fix is confirmed.

## Related skills
`garmin-ui` (what's being drawn), `garmin-connect-iq` (lifecycle timing of `onUpdate`/`onPartialUpdate`).
