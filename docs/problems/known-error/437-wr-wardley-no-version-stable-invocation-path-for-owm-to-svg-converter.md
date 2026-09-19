# Problem 437: wr-wardley exposes no version-stable invocation path for its owm-to-svg converter (consumers pin the cache version and break on bump)

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#325)
**Effort**: S. WSJF = (9 × 2.0) / 1 = 18.0.
**WSJF**: 18 — (9 × 2.0) / 1 (Known Error multiplier applied 2026-09-19; Effort held at S — one generated entry point, one packaging field, one skill dispatch line)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

A downstream consumer plugin invokes wr-wardley's converter, from its own render step, by a version-pinned cache path (`.../cache/windyroad/wr-wardley/0.1.0/skills/generate/owm-to-svg.mjs`), which breaks with `Cannot find module` on every wr-wardley version bump. wr-wardley provides no version-stable invocation path (PATH shim / skill-mediated entry) for its converter — same no-version-pinned-paths class as P137/P317, but on the *consumer-invokes-plugin* axis.

## Symptoms

- Any consumer that renders a Wardley map via the pinned converter path breaks the moment wr-wardley publishes a new version (the cache dir name changes).

## Workaround

Re-pin the cache path to the new version number after each bump. This is what the reporting consumer does today; it restores the render but has to be repeated on every release.

## Impact Assessment

- **Who is affected**: consumers invoking the wr-wardley converter across plugin updates.
- **Frequency**: every wr-wardley version bump.
- **Severity**: Medium — breaks map render until the consumer re-pins.

## Root Cause Analysis

Confirmed 2026-09-19 by reading the package surface.

wr-wardley ships its converter as `skills/generate/owm-to-svg.mjs` and nothing else. It has no `bin/wr-wardley-*` entry, so the plugin contributes no command to `$PATH` when the marketplace install adds its `bin/` directory. Every other plugin in the suite reaches its bundled scripts through that mechanism, so a caller outside the skill has exactly one way in: name the file. Naming the file means naming the version directory the marketplace cache created for it, and that directory name changes on every publish.

Two package-level facts make the gap concrete:

- `packages/wardley/bin/` contains only `install.mjs`. There is no entry following the `wr-<plugin>-<kebab-script-name>` grammar, so `command -v wr-wardley-owm-to-svg` fails in an installed session.
- `packages/wardley/package.json`'s `files` array omits `scripts/`. Adding an entry point alone would not be enough — its dispatch target has to be in the published tarball too, or the shipped command exec-fails at invocation.

The converter body itself is correct and needs no change; the defect is entirely in what the package exposes.

### Investigation Tasks

- [x] Confirm wr-wardley publishes no `$PATH`-resolvable entry for the converter.
- [x] Confirm the packaging manifest would not ship a dispatch target even if an entry existed.
- [x] Expose a version-stable invocation path for the owm-to-svg converter, so consumers never reference a version-pinned cache path.

## Fix Strategy

Give wr-wardley the same entry-point shape every sibling plugin already has, so the converter answers to a name instead of a path.

- A bash entry point at `packages/wardley/scripts/owm-to-svg.sh` dispatches to the existing `.mjs` body, resolving it relative to itself. The body stays beside its `SKILL.md` so the Codex runtime can keep reaching it the way that runtime resolves bundled scripts.
- A generated command at `packages/wardley/bin/wr-wardley-owm-to-svg` puts that entry point on `$PATH` and picks the highest installed version at every invocation, so a consumer that upgrades gets the new code without touching its call.
- The packaging manifest ships the dispatch target alongside the command.
- The skill's own render step and the package README both name the command, so neither a future maintainer nor a consumer has to reverse-engineer one.

**Release vehicle**: `.changeset/wardley-version-stable-converter-entry-point.md`

The fix is proposed as the RFC-095 release row on STORY-MAP-008 ("Have a plugin behave like a guest in my repository"), activity E ("Get a fix on upgrade"), carrying STORY-091. Reproduction and regression coverage is the behavioural bats at `packages/wardley/scripts/test/owm-to-svg-shim.bats`, which packs the workspace and asserts the command and its target both ship and dispatch from a simulated two-version cache — it fails against the pre-fix package.

## Dependencies

- **Composes with**: P137 / P317 (published-artifact path portability — same class, consumer-invocation axis).

## Related

- Inbound issue #325. The SKILL that trips this belongs to a downstream consumer plugin and is not ours to change; the windyroad-side fix is the stable wr-wardley entrypoint.

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-091 | STORY-091: Invoke the Wardley map converter by a name that survives every upgrade | draft |
