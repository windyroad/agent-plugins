---
status: draft
story-id: invoke-the-wardley-converter-by-a-name-that-survives-upgrades
reported: 2026-09-19
decision-makers: [Tom Howard]
problems: [P437]
jtbd: [JTBD-101]
rfcs: [RFC-095]
story-maps: [STORY-MAP-008]
estimated-effort: S
---

# STORY-091: Invoke the Wardley map converter by a name that survives every upgrade

**Reported**: 2026-09-19
**Problems**: P437
**JTBD**: JTBD-101
**RFCs**: RFC-095
**Story Maps**: STORY-MAP-008
**Estimated effort**: S — one generated entry point, one packaging field, one skill dispatch line; no new mechanism.

## User value (required, INVEST Valuable)

In order to keep rendering Wardley maps after the plugin updates, without hunting
through a cache directory for the version number that moved, as a developer whose
own workflow calls the converter, I want to invoke it by a stable name that the
install puts on my path, so an upgrade delivers the fix instead of breaking the call.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A published `@windyroad/wardley` install exposes an executable named `wr-wardley-owm-to-svg` that converts an OWM file to SVG.
- [ ] The packed tarball carries both that entry point and the file it dispatches to, so the call works from an install rather than only from this checkout.
- [ ] The entry point resolves its target relative to itself, so no caller names a version directory and no shipped file names a repository path.
- [ ] Invoking it from a second installed version keeps working — the resolution picks the highest installed version rather than the one the caller happened to name.

## Driving problem trace (required — I6 invariant)

P437: a downstream consumer reached the converter through a version-pinned cache
path and broke with `Cannot find module` on every version bump, because the plugin
published no version-stable way in.

## JTBD trace (required — I9 invariant)

JTBD-101 (Extend the Suite with New Plugins) wants every plugin to follow the same
structure and to install correctly for users. Wardley is the one plugin whose
bundled executable had no entry point in the shared shape, so a consumer had to
reverse-engineer one from the cache layout.

## Implementation notes (optional)

(deferred — populate at /wr-itil:manage-story accepted transition or during implementation)

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

(captured via /wr-itil:capture-story; expand at next /wr-itil:manage-story invocation)
