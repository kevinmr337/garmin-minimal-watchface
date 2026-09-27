# minimal-venu3-face — Repository Map

A single **Garmin Connect IQ Watch Face** (`iq:application type="watchface"`), not a widget, data field,
or device app. It draws its own analog dial + hands and a digital time/date/activity readout entirely by
hand in `onUpdate()` — it does **not** use the Connect IQ layout/drawable system, despite two leftover
files from that system still sitting in the tree (see "Known dead code" below).

## Entry points & lifecycle

- `source/minimal-venu3-faceApp.mc` — `minimal_venu3_faceApp extends Application.AppBase`. Manifest
  `entry="minimal_venu3_faceApp"`. `getInitialView()` returns a single view, no input delegate (watch
  faces don't need one — Garmin's system chrome owns buttons/touch outside the face).
- `source/minimal-venu3-faceView.mc` — `minimal_venu3_faceView extends WatchUi.WatchFace`. All real work
  happens here:
  - `initialize()` — preloads all bitmap resources once (correct: do this once, never per-frame).
  - `onLayout(dc)` — caches width/height/center; does **not** call `setLayout()`.
  - `onUpdate(dc)` — reads `BackgroundColor`/`ForegroundColor`/`UseMilitaryFormat` properties, clears the
    screen, draws the dial (`drawDial`), date/time/activity text, then hands (`drawHands`) last so they
    sit on top.
  - `onPartialUpdate(dc)` — currently just calls `onUpdate(dc)` (see Performance skill: this is a
    known battery cost during low-power/always-on seconds ticks).

## Known dead code (do not build on top of it — remove or finish it deliberately)

- `resources/layouts/layout.xml` (a `Background` drawable + `TimeLabel`) and
  `source/minimal-venu3-faceBackground.mc` (`class Background extends WatchUi.Drawable`) are **never
  referenced** — `onLayout` never calls `WatchUi.View.setLayout()`, so neither is ever instantiated.
  Confirmed via full-repo grep for `setLayout`, `Rez.Layouts`, `TimeLabel`. Left in place only because
  file deletion was withheld pending explicit user approval — flag this to the user before removing.
- `iconSun` / `iconMoon` are loaded in `initialize()` and a day/night bitmap is computed in `onUpdate`,
  but the actual `drawBitmap` call is commented out (`source/minimal-venu3-faceView.mc:64`) — the feature
  is unfinished, not broken. Either finish it or stop loading the bitmaps.

## Data flow / state

- **Settings → rendering**: `resources/settings/settings.xml` exposes `BackgroundColor`, `ForegroundColor`
  (color pickers), `UseMilitaryFormat` (boolean) to the Garmin Connect companion app. Defaults live in
  `resources/settings/properties.xml`. `onUpdate()` reads them every frame via
  `getApp().getProperty(...)` — there is no other persistence layer (`Application.Storage` is unused).
  `onSettingsChanged()` in the App class calls `WatchUi.requestUpdate()` so edits apply immediately.
- **Sensor data**: only `Toybox.ActivityMonitor.getInfo()` for steps/calories, wrapped in `try/catch`
  (tolerant of missing data). Heart rate and notification count are explicit placeholders (`"--"` / `0`)
  — see the Spanish comments in `onUpdate` marking them as unimplemented, not accidental.
- No networking (`Toybox.Communications` unused), no background service (`Toybox.Background` unused, and
  the manifest permission for it was removed — see git history), no complications/glances.

## Build & run

No Garmin Connect IQ SDK is available in this container — builds/simulator runs must happen on a machine
with the SDK installed. See the `garmin-build` skill for exact commands and `run.sh` usage
(`CIQ_SDK_BIN`, `CIQ_DEV_KEY`, `CIQ_DEVICE` env vars). There is no CI/CD, no automated test suite, and no
linter configured in this repo.

## Supported devices & compatibility constraints

`manifest.xml` targets `venu3`, `venu3s`, `venu441mm`, `venu445mm`, `venux1`, `vivoactive5`,
`vivoactive6` at `minApiLevel="3.0.0"`. **Critical constraint**: `venux1` (Venu X1) is a rectangular
display, while the rest are circular — the dial/hand math in `drawDial`/`drawHands` scales off
`min(width, height)` (device-agnostic), but the icon/text block in `onUpdate` uses hardcoded absolute
pixel coordinates (`70, 100`, `320, 100`, etc.) tuned for one circular screen size. See the
`garmin-device-compatibility` skill before touching layout coordinates.

## Coding conventions actually in use

- Comments and variable names are a mix of Spanish and English; the codebase is not English-only —
  don't "fix" this as a drive-by change.
- Colors are read as raw `Number` properties (`0xRRGGBB`) and passed straight to `dc.setColor(fg, bg)` —
  no `Graphics.createColor` alpha-blending is used for the main palette (a leftover alpha-blend hack was
  removed; see git log).
- Only `Graphics.FONT_XTINY` is used for all text — no custom font resources exist in this repo.

## Safety rules for modifications

1. **You cannot compile Monkey C in most sandboxed/cloud sessions** (no SDK). Keep `.mc` edits small,
   mechanical, and pattern-matched against already-working code in the same file before pushing. Always
   tell the user validation was not performed if you couldn't run `monkeyc`/the simulator.
2. Don't reintroduce large (>~50KB) bitmap resources without checking actual device memory budgets —
   this repo previously shipped an unused 1024×1024 (1.27MB) `test.png`; see `garmin-performance`.
3. Don't add manifest permissions without a corresponding `Toybox.*` API call that needs them.
4. Don't assume circular-screen math is safe for `venux1` — verify against its actual resolution before
   changing pixel-coordinate layout code.
5. `bin/` is build output (gitignored) — never commit it. `build/` is also gitignored.

## Deeper references

- `.claude/skills/garmin-connect-iq/SKILL.md` — project structure, lifecycle, Toybox APIs actually used.
- `.claude/skills/garmin-build/SKILL.md` — exact build/run commands, SDK expectations, `run.sh` env vars.
- `.claude/skills/garmin-device-compatibility/SKILL.md` — supported devices, screen-shape risk, API level.
- `.claude/skills/garmin-ui/SKILL.md` — rendering architecture, resource wiring, the dead layout system.
- `.claude/skills/garmin-performance/SKILL.md` — memory/battery-sensitive code, hot paths, what to check.
- `.claude/skills/garmin-data/SKILL.md` — settings/properties system, how to add a new user setting.
