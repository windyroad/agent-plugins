---
status: proposed
rfc-id: bundler-based-shared-code-replacing-duplicate-and-sync
reported: 2026-06-16
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P304]
adrs: []
jtbd: []
stories: []
---

# RFC-023: Bundler-based shared-code approach replacing duplicate-and-sync

**Status**: proposed
**Reported**: 2026-06-16
**Problems**: P304
**ADRs**: (none)
**JTBD**: (none)

## Summary

Replace the current duplicate-and-sync model for `packages/shared/` helpers with a
single-source + build/bundle step that produces the self-contained per-plugin artefact
at publish time. The duplicate-and-sync model copies each shared helper into every
consuming package and keeps the copies in lockstep with 7 per-helper `sync-<name>.sh`
scripts plus `npm run check:<name>` CI drift gates (visible in root `package.json`). At
~8 canonical helpers × N consuming packages this is significant storage + cognitive + CI
overhead — the exact zone ADR-017 flagged for bundler-vs-duplicate review.

This RFC is the framework-mandated design vehicle (ADR-060) for P304's first Investigation
Task ("Design the bundler approach — likely an RFC per ADR-060"). Its eventual `accepted`
form will reassess ADR-017 (cross-package shared-code sync convention), whose ">5-module
reassessment trigger" was found objectively met (~8 canonical shared helpers under
`packages/shared/`). ADR-017 remains the operative convention until that accepted RFC
lands; this skeleton enacts nothing.

**The bundler-mechanism choice is DEFERRED, not pre-decided.** Which tool/approach
(esbuild / rollup / tsup / a custom build step), and the build-time wiring that preserves
the self-contained-plugin guarantee, are a genuine multi-option architecture decision —
surfaced for human confirmation at the `/wr-itil:manage-rfc accepted` transition and
landed in a dedicated ratified ADR, NOT chosen here. Per ADR-074 (confirm substance before
build) this RFC is born `proposed` / `human-oversight: unconfirmed`, holds no "Considered
Options" decision block, and rides no dependent work ahead of the unconfirmed mechanism. No
duplicate-and-sync machinery is removed until the mechanism is confirmed.

## Driving problem trace

- **P304** — `docs/problems/open/304-move-packages-shared-from-duplicate-and-sync-to-bundler-approach.md`
  (Open). ADR-017's >5-module reassessment trigger objectively met at ~8 canonical shared
  helpers. User-directed 2026-05-26 (P283/ADR-066 oversight drain): "move to a bundler-based
  shared-code approach" — high-level direction confirmed; mechanism unconfirmed.

## Design constraints (carried from P304; for the accepted RFC to satisfy, not enacted here)

The accepted RFC's chosen mechanism MUST satisfy all of:

- Preserve the adopter-installs-a-single-self-contained-plugin guarantee — no runtime
  cross-plugin dependency; each published plugin remains independently installable.
- Replace the `sync-<name>.sh` + `npm run check:<name>` CI-drift-gate machinery rather than
  layer on top of it.
- Subsume P026 (`install-utils.mjs` duplicated across all packages) — a specific instance
  of this duplicate-and-sync overhead that the bundler approach closes.
- Reconcile ADR-017 — amend or supersede it once the mechanism lands (record the
  reassessment outcome + the new convention). ADR-017 stays operative until then.
- **Coordinate with RFC-025 markdown-toggle tool choice (user direction 2026-06-17 drain).**
  RFC-025 is selecting a `markdown source → variant markdown` tool (leading candidate:
  `remark` / `unified` ecosystem with `remark-directive`) for build-time feature
  toggling on SKILL.md and other shipped markdown. This RFC's JS/TS bundler choice
  and RFC-025's markdown-toolchain choice operate on different source surfaces but
  ship into the same `@windyroad/*` plugin tarballs — they MUST coexist in one
  coherent build pipeline per plugin. Therefore: defer this RFC's bundler-mechanism
  pick until RFC-025 Slice 1 produces its tool-comparison matrix (or jointly with it),
  and reject any bundler whose plugin ecosystem cannot compose with RFC-025's chosen
  markdown toolchain. User direction verbatim: *"didn't we end up picking a tool
  for feature flagging? Can we use it here too or at the very least, don't they need
  to work well together?"*

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition, after the mechanism choice
is human-confirmed)

## Tasks

- [ ] (deferred — populate at /wr-itil:manage-rfc accepted transition)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)

- ADR-017 — cross-package shared-code sync convention; the decision the accepted RFC reassesses.
- ADR-060 — Problem-RFC-Story framework; RFC is the mandated design vehicle here.
- ADR-074 — confirm substance before build; mechanism choice deferred to human confirmation.
- P026 — install-utils.mjs duplication (subsumed instance).
- P279 — ADR-017 § Consequences housekeeping (two coexisting clustering conventions).
