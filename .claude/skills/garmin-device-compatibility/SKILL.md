---
name: garmin-device-compatibility
description: Use before changing pixel coordinates, layout, manifest products, or API-level-gated code — anything that could behave differently across the seven declared target devices.
---

# garmin-device-compatibility

## When to use this skill
Before touching hardcoded coordinates in `onUpdate`/`drawDial`/`drawHands`, before adding/removing a
`<iq:product>` entry in `manifest.xml`, or before using any Toybox API that isn't guaranteed at
`minApiLevel="3.0.0"`.

## What it covers
Device/manifest compatibility only. Rendering *logic* itself is covered by `garmin-ui`.

## Important files
- `manifest.xml` `<iq:products>` — current list: `venu3`, `venu3s`, `venu441mm`, `venu445mm`, `venux1`,
  `vivoactive5`, `vivoactive6`. `minApiLevel="3.0.0"`.
- `source/minimal-venu3-faceView.mc` — the only place device geometry matters; `onLayout` captures
  `_w`, `_h`, `_cx`, `_cy` from `dc.getWidth()/getHeight()` (correct, resolution-agnostic).

## How it works / key risk
- `drawDial`/`drawHands` scale off `base = min(_w, _h)`, which degrades gracefully on any rectangular
  screen (it just uses the shorter dimension as the "radius" reference) — this part is device-agnostic.
- The icon/text block in `onUpdate` (notifications, steps, calories, heart-rate rows, the date block, the
  digital time) uses **hardcoded absolute pixel coordinates** (e.g. `dc.drawBitmap(70, 100, iconNotif)`,
  `dc.drawBitmap(320, 100, iconSteps)`) tuned for one specific circular screen. `venux1` (Venu X1) is
  a **rectangular** AMOLED display with a materially different aspect ratio from the other six (all
  circular) — these absolute coordinates are very likely to misplace or clip content on it. This has not
  been verified in the simulator in this environment (no SDK available) — treat it as a confirmed static
  finding, not a confirmed visual bug, and re-check with the actual simulator per device before trusting
  either way.
- Two of the seven product ids (`venu441mm`, `venu445mm`) were not independently cross-checked against
  Garmin's current device-id catalog in this session (no network/SDK access) — treat their exact screen
  resolutions as an open question until verified against the SDK's device list
  (`connectiq --list-devices` or the SDK's `devices.xml`) rather than assumed from the id string alone.

## Invariants that must remain true
- Any new hardcoded pixel value added to `onUpdate` should be justified against `_w`/`_h`/`_cx`/`_cy`
  (proportional) rather than a bare literal, unless you've confirmed the literal is safe across all
  seven declared products.
- Don't add a product to `manifest.xml` without confirming its `minApiLevel` compatibility and screen
  shape are compatible with the existing drawing code (or that the drawing code was adjusted first).

## Common mistakes to avoid
- Testing only on `venu3` (the `run.sh` default `CIQ_DEVICE`) and assuming other products behave
  identically — explicitly re-run with `CIQ_DEVICE=venux1` (and at least one of the smaller circular
  devices, e.g. `venu3s`) before claiming a layout change is safe.
- Treating "compiles" as "renders correctly" — Monkey C compilation doesn't catch off-screen or
  overlapping draw calls; only simulator/device visual inspection does.

## How to validate changes
Run the simulator per device via `CIQ_DEVICE=<id> ./run.sh` (requires local SDK) and visually compare
the icon/text/hand layout on at least: one circular device already used as baseline (`venu3`), the
smallest circular device (`venu3s`), and `venux1` (rectangular). This cannot be done in this sandboxed
session — flag it to the user as manual/simulator validation still required.

## Related skills
`garmin-ui` (the drawing code itself), `garmin-build` (`CIQ_DEVICE` env var).
