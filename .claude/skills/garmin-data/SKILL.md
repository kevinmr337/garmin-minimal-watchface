---
name: garmin-data
description: Use when adding, removing, or reading a user-configurable setting/property, or asked how the watch face's persistence/configuration works.
---

# garmin-data

## When to use this skill
Before editing `resources/settings/properties.xml` or `settings.xml`, or before adding a new
`getApp().getProperty(...)` call in `source/minimal-venu3-faceView.mc`.

## What it covers
The settings/properties system, which is the **only** persistence mechanism in this repo —
`Application.Storage` is not used anywhere, so there is no runtime-written/cached state, no migration
concern, and no corrupt-state-on-upgrade risk to design around today.

## Important files
- `resources/settings/properties.xml` — declares each property's id, type, and **default value**:
  `BackgroundColor` (`number`, default `0x000000`), `ForegroundColor` (`number`, default `0xFF0000`),
  `UseMilitaryFormat` (`boolean`, default `false`). This is the source of truth for defaults on first
  install.
  - Note: `App.mc`'s hardcoded default is 0x000000 black background / 0xFF0000 red foreground; the
    `settings.xml` list-picker default selection may differ from what a first-time user sees rendered if
    you change one file without the other — keep them in sync.
- `resources/settings/settings.xml` — the Garmin Connect companion-app UI: two 4-option color lists
  (`listEntry value="0x..."` mapped to `@Strings.Color*`) and one boolean toggle
  (`MilitaryFormatTitle`). Every `settingConfig` here must reference a `propertyKey` that exists in
  `properties.xml`, and every `@Strings.*`/`@Properties.*` reference must resolve in
  `resources/strings/strings.xml` / `properties.xml` respectively — a mismatch here is a build-time
  resource-resolution error, not a runtime one.
- `source/minimal-venu3-faceView.mc` `onUpdate()` — reads all three properties once per frame:
  `getApp().getProperty("BackgroundColor") as Number`, `"ForegroundColor" as Number`,
  `"UseMilitaryFormat" as Boolean`. This is the pattern to follow for any new property — read via
  `getApp().getProperty(...)`, cast with `as <Type>` matching the `properties.xml` `type` attribute.
- `source/minimal-venu3-faceApp.mc` `onSettingsChanged()` — calls `WatchUi.requestUpdate()`; this is
  what makes a Garmin-Connect-app edit show up on the watch without waiting for the next natural minute
  tick. Any new property doesn't need its own handler here — this one callback covers all of them.

## Invariants that must remain true
- Every `propertyKey` in `settings.xml` must have a matching `<property id="...">` in `properties.xml`
  with the same id and a compatible `type`.
- `onSettingsChanged()` must keep calling `requestUpdate()` — removing it would make settings changes
  silently not-apply until the next minute-boundary redraw.
- Color properties are raw `0xRRGGBB` numbers with **no alpha channel** — passed directly to
  `dc.setColor(fg, bg)`. If you introduce transparency/alpha blending, do it explicitly at the call site
  (e.g. `Graphics.createColor`), don't change the property type.

## Common mistakes to avoid
- Adding a new `<setting>` in `settings.xml` without a matching `<property>` in `properties.xml` (build
  error) — or vice versa (a property with no UI to change it, which may be intentional for
  internal/computed values but should be a deliberate choice, not an oversight).
- Forgetting the `as Number`/`as Boolean` cast when reading a property — `getProperty` returns an
  untyped value in Monkey C's type system.
- Renaming a property `id` without also updating every `getProperty("...")` call site (string literal,
  not a compiler-checked symbol reference) — do a full grep for the old id before renaming.

## How to validate changes
XML structure can be validated without the SDK (`xmllint`/`ElementTree`, as done in this repo's audit).
Confirm every `propertyKey`/`@Properties.*`/`@Strings.*` cross-reference resolves by eye (grep both
files). Actual in-simulator behavior (does the Garmin Connect settings UI show the right picker, does an
edit take effect) needs the SDK/simulator — not available in this sandbox.

## Related skills
`garmin-ui` (how `fg`/`bg` are consumed), `garmin-connect-iq` (`onSettingsChanged` lifecycle hook).
