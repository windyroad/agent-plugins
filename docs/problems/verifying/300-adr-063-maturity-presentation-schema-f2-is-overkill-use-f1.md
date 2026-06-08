# Problem 300: ADR-063 maturity-presentation schema — F2 (rich-record per-surface) is overkill; F1 is sufficient to begin with

**Status**: Verification Pending
**Reported**: 2026-05-25
**Verifying since**: 2026-06-08
**Priority**: 4 (Low-Med) — Impact: 2 (Minor — over-engineering the plugin.json maturity schema adds build + maintenance cost for capability not yet needed; not shipped, so caught before the cost lands) × Likelihood: 2 (Unlikely — affects the Phase-3 maturity-presentation build only)
**Effort**: S — amend ADR-063's chosen schema option F2 → F1; the implementation simplifies (less to build)
**WSJF**: 4/1 = **4.0** (Verifying multiplier — release-verification queue)

## Description

Surfaced during the P283/ADR-066 ADR-oversight drain (2026-05-25). When ADR-063 (plugin maturity presentation layer) was presented for human-oversight confirmation, the user amended the schema choice:

> User direction 2026-05-25 (drain): *"option F2 is overkill. F1 is sufficient to begin with."*

ADR-063 chose **F2** (rich-record per-surface + string rollup `plugin.json` schema) for the maturity presentation layer. The user wants **F1** (the simpler schema) to begin with — YAGNI: start with the minimal schema and only enrich to F2 if a concrete need emerges. The in-suite `wr-itil-plugin-maturity-list` display shim (F9) is fine.

**Badge rendering (user direction 2026-05-25): use a Shields.io URL badge**, NOT the recorded F5 (markdown prose-woven text badge). The README maturity badge should be a hosted `https://img.shields.io/badge/...` image badge (the standard OSS-README badge convention — renders a recognisable shield image, links to the maturity detail) rather than inline markdown text. So ADR-063 changes on TWO axes: schema F2 → F1, and badge F5 → Shields.io URL badge.

ADR-063 is **left unoversighted** (P283/ADR-066 marker withheld) until amended.

## Symptoms

(deferred to investigation)

- ADR-063 Decision Outcome pins F2 (rich-record per-surface schema) as the `plugin.json` maturity shape; the user judges this over-engineered for the starting point.
- The Phase-3a population script + the README badge renderer would build against the richer F2 schema unnecessarily.

## Root Cause Analysis

### Investigation Tasks

- [x] Amend ADR-063: change the chosen schema option F2 → F1 (the simpler schema). Confirm what F1's exact shape is (re-read ADR-063 Considered Options) and that the badge + F9 (display shim) still compose with F1. **Landed 2026-06-08 — §Amendment 2026-06-08 (P300) defines the F1 string-only per-surface shape.**
- [x] Amend ADR-063 badge rendering F5 → **Shields.io URL badge**: the README maturity badge is a hosted `https://img.shields.io/badge/<label>-<band>-<color>` image badge, not an inline markdown text badge. Per-band colour mapping picked: Experimental=orange, Alpha=yellow, Beta=blue, Stable=brightgreen, Deprecated=red. URL shape: `https://img.shields.io/badge/maturity-<band-lowercase>-<colour>`. **Landed 2026-06-08.**
- [x] Reconcile with ADR-053 (the maturity taxonomy) + ADR-058 (the measurement mechanism feeding the schema) — F1 must still carry enough to render the five-band badge + rollup. **ADR-053 §Bootstrapping clause sunsetted 2026-06-06 (sixty days after 2026-04-07); compound-rendering requirement is dormant; band-only F3 rendering is compliant under steady-state. ADR-058 Phase 2 NDJSON output unchanged — F1 is downstream-of-Phase-2 schema simplification only.**
- [x] Note the YAGNI reassessment trigger: enrich F1 → F2 only when a concrete consumer needs the per-surface rich record. **Captured in ADR-063 §Reassessment Triggers (P300 amendment 2026-06-08).**
- [x] Re-confirm amended ADR-063 via human-oversight marker (architect-mark-oversight-confirmed shim per ADR-066) using verbatim user direction as substance-confirm evidence. `human-oversight: confirmed`, `oversight-date: 2026-06-08`.

### Verification

The ADR amendment landed 2026-06-08 (this iter). Verification follows on the Phase 3 build-side implementation:

- [ ] Sibling Phase 3a iter: re-simplify `packages/itil/scripts/plugin-maturity-populate.sh` to write F1 (band-string per surface) instead of F2 (rich-record per surface).
- [ ] Sibling Phase 3b iter: re-simplify `packages/itil/scripts/plugin-maturity-render.sh` to write a Shields.io URL badge (F3) instead of prose-woven text (F5).
- [ ] Sibling Phase 3c iter: re-simplify per-plugin bats fixtures to assert F1 shape + F3 badge URL.
- [ ] Touch up ADR-069 lines 76 + 109 to drop stale "prose-weaving citations" phrasing (low-priority; not load-bearing — captured here as follow-up).
- [ ] Verify the F1 + F3 implementation through a release of `@windyroad/itil` (and the other 10 plugins consuming the maturity pipeline).

## Dependencies

- **Blocks**: ADR-063 human-oversight confirmation (held until amended).
- **Blocked by**: none.
- **Composes with**: ADR-053 (maturity taxonomy), ADR-058 (measurement mechanism), P087 (the maturity-signal master ticket), P283/ADR-066 (the drain that surfaced this).

## Related

(captured 2026-05-25 during the P283/ADR-066 oversight drain)

- **P287 / P289–P299** — sibling drain-surfaced reworks.
- **ADR-063** (`docs/decisions/063-plugin-maturity-presentation-layer.proposed.md`) — amendment target.
- **ADR-053** + **ADR-058** — the maturity taxonomy + measurement neighbours.
