# Problem 299: ADR-034 per-project auto-install is the wrong mechanism — the plugin install cache is global/shared, so one update propagates to all projects

**Status**: Verifying
**Reported**: 2026-05-25
**Transitioned to Verifying**: 2026-06-08 — ADR-034 superseded by ADR-030 amendment 2026-05-25 (in-place via `.superseded.md` rename + supersession blockquote + frontmatter `status: superseded` + `superseded-by: "ADR-030"`); ADR-030 line 153 dangling reference annotated; decisions compendium regenerated; no hook/script/SKILL code references ADR-034 (architect confirmed grep zero hits in packages/ + scripts/). All four Investigation Tasks satisfied.
**Priority**: 6 (Medium) — Impact: 2 (Minor — a per-project SessionStart auto-install is redundant work, not a correctness break; updates still propagate via the shared cache; but the redundancy + the per-project consent gate add friction and model the wrong thing) × Likelihood: 3 (Possible — fires per project per session)
**Effort**: M — ADR-034 rework (drop the per-project auto-install model; define the update trigger against the global cache) + reconcile with /install-updates (ADR-030) which is the actual cache-refresh surface
**WSJF**: 6/2 = **3.0** (Open multiplier 1.0)

## Description

Surfaced during the P283/ADR-066 ADR-oversight drain (2026-05-25). When ADR-034 (Auto-install on next session start — SessionStart hook + per-project consent gate + AFK carve-out) was presented for human-oversight confirmation, the user **rejected the mechanism**:

> User direction 2026-05-25 (drain): *"this is wrong. The sibling projects automatically get the new version when we update the install for one. If we do it here in this project, they all get it."*

ADR-034 modelled auto-install as a **per-project** SessionStart hook (each project checks for updates + installs on its own session start, gated by a per-project consent marker). But the **plugin install cache is global/shared across projects** (per the `/install-updates` skill contract: "the plugin install cache is global/shared across projects … this advances the active version for every project that enables those plugins"). So updating the install from ANY one project (in practice, this plugin-dev repo after a release) advances the active version for ALL projects on the machine — a per-project auto-install is redundant.

**Key distinction (vs ADR-047/P297):** per-project *artifacts* (scaffold docs/risks/ etc.) genuinely need a per-project trigger because each project's `docs/` is separate; the *global plugin cache* does NOT — it's shared, so one update propagates. ADR-034 wrongly applied the per-project-trigger pattern to the global-cache case.

ADR-034 is **left unoversighted** (P283/ADR-066 marker withheld) until reworked.

## Symptoms

(deferred to investigation)

- ADR-034's `session-start-update-check.sh` would fire in every project, each trying to install — but they share one global cache, so all but the first are redundant.
- The per-project consent marker models per-project install decisions that don't reflect the shared-cache reality.

## Root Cause Analysis

### Investigation Tasks

- [x] Rework ADR-034 given the global/shared cache — **superseded entirely**. ADR-034 retired in place via `.proposed.md` → `.superseded.md` rename + top-of-body `> **SUPERSEDED by ADR-030 amendment 2026-05-25**` blockquote + frontmatter `status: superseded` + `superseded-by: "ADR-030"`. The `/install-updates` chain (ADR-030 + amendment 2026-05-25 + P233 post-release refresh) already covers the post-release cache refresh; no separate session-start check is needed because the global cache shared across projects means one refresh propagates to all.
- [x] Reconcile with ADR-030 + P233 — done. ADR-030 line 153 dangling `.claude/.auto-install-consent` reference annotated inline with `[ADR-034 superseded by this ADR's amendment 2026-05-25 per P299 — the marker contract was never implemented and no longer has a referent]`. P233 unchanged (its post-release refresh chain already terminates at `/install-updates` per ADR-030).
- [x] Session-start check question — moot under supersession. No session-start surface survives; manual `/install-updates` invocation at end-of-release-session covers the trigger.
- [x] Re-confirm the reworked ADR — `/wr-architect:review-decisions` not needed. ADR-066's post-supersede pattern (Amendment 2026-05-30) explicitly says: *"when the supersede ADR eventually lands and the original transitions to `*.superseded.md`, the existing superseded-name skip takes over"* — the `.superseded.md` filename suffix is the signal both detectors honour. Architect confirmed 2026-06-08 that the supersession itself was pre-authorised by ADR-034's prior `human-oversight: rejected-pending-supersede` + `supersede-ticket: P299` markers, and this work executes that authorisation.

### Verification criteria (P057/P062/P094)

- [ ] `docs/decisions/README.md` lists ADR-034 in the **Historical decisions** section, not In-force. (Compendium regenerated in this commit; `bash packages/architect/scripts/generate-decisions-compendium.sh` reports "70 in-force, 9 historical".)
- [ ] No remaining `ADR-034` references in `packages/` or `scripts/` that would mislead a reader into looking for a live ADR-034 marker contract.
- [ ] `/wr-architect:review-decisions` does not re-surface ADR-034 for oversight (superseded ADRs skip the drain per ADR-066).

## Dependencies

- **Blocks**: ADR-034 human-oversight confirmation (held until reworked).
- **Blocked by**: none.
- **Composes with**: ADR-030 (/install-updates repo-local skill), P233 (post-release cache refresh), ADR-047/P297 (the per-project-vs-global distinction — scaffold IS per-project, install is NOT), P283/ADR-066 (the drain that surfaced this).

## Related

(captured 2026-05-25 during the P283/ADR-066 oversight drain)

- **P297** (ADR-047) — sibling on the per-project-vs-global trigger axis: scaffold needs per-project (SessionStart), install does NOT (global cache).
- **P287 / P289–P298** — sibling drain-surfaced reworks.
- **ADR-034** (`docs/decisions/034-auto-install-on-next-session-start.proposed.md`) — the decision to rework/supersede.
- **ADR-030** + **P233** — the actual cache-refresh surfaces ADR-034 may be redundant with.
