---
name: garmin-build
description: Use when asked to build, compile, or run this watch face in the simulator, or when troubleshooting run.sh / monkeyc / monkeydo invocations.
---

# garmin-build

## When to use this skill
Before running `run.sh`, before telling the user a build "passed" or "failed", or when asked to add a
CI workflow for this project (none exists today).

## What it covers
The local build/run flow only. This repo has no CI/CD, no Docker build, no packaging-for-release script
beyond what's described here.

## Important files
- `run.sh` — compiles via `monkeyc` then launches the simulator via `monkeydo`. Reads three env vars
  (all optional, with OS-aware defaults):
  - `CIQ_SDK_BIN` — path to the Connect IQ SDK's `bin/` folder (must contain `monkeyc`, `monkeydo`,
    `connectiq`).
  - `CIQ_DEV_KEY` — **required**, path to your developer key (`monkeyc --generate-key <path>` to create
    one; no default is guessed since it's user/machine-specific).
  - `CIQ_DEVICE` — simulator device id/alias, defaults to `venu3`.
  - `CIQ_DEVICES_DIR` — override for where `.sim` profiles live.
- `monkey.jungle` — points at `manifest.xml`; no custom source/resource path overrides.
- Output goes to `build/face.prg` (gitignored).

## How it works
1. `monkeyc -o build/face.prg -f monkey.jungle -y <dev key>` compiles all of `source/` +
   `resources/` per the jungle/manifest.
2. The script opens the Connect IQ simulator app if not already running, then `monkeydo build/face.prg
   <device>` loads the compiled `.prg` into it.

## Invariants that must remain true
- `run.sh` must keep working with **no hardcoded machine-specific paths** — it previously hardcoded one
  developer's macOS home directory and is now parameterized via env vars; don't reintroduce absolute
  personal paths.
- The script must fail fast with a clear message when the dev key or `monkeyc` binary is missing, rather
  than producing a confusing downstream error.

## Common mistakes to avoid
- Assuming a Garmin SDK is present in a cloud/sandbox session — check with `which monkeyc` or
  `command -v monkeyc` first. If absent, say so explicitly rather than claiming a build succeeded.
- Editing `manifest.xml`'s generated-file comment header away — it's harmless, but the file itself is
  meant to be hand-editable (there is no VS Code extension available outside the developer's own
  machine); just validate it's well-formed XML after edits (`xmllint --noout manifest.xml` or
  `python3 -c "import xml.etree.ElementTree as ET; ET.parse('manifest.xml')"`).
- Committing `build/` or `bin/` (SDK-generated compiler cache/output) — both are gitignored; if you see
  either reappear in `git status`, that's a sign a build was run without the ignore rules in effect, not
  something to fix by hand-editing the generated files.

## How to validate changes
- **XML resources**: validate well-formedness with `xmllint`/`ElementTree` even without the SDK — this
  catches most structural mistakes before a real compile.
- **`run.sh`**: `bash -n run.sh` checks shell syntax without executing it.
- **Actual compile**: only possible with the real SDK; ask the user to run `./run.sh` locally and report
  `monkeyc` errors/warnings back if you can't compile yourself.

## Related skills
`garmin-connect-iq` (what's being compiled), `garmin-device-compatibility` (which device to pick for
`CIQ_DEVICE` when testing a specific screen shape).
