# Problem 288: New Jobs To Be Done and new personas need human-oversight confirmation (sibling of P283)

**Status**: Verification Pending
**Reported**: 2026-05-25
**Priority**: 9 (Med High) — Impact: 3 (Moderate — auto-made JTBDs/personas drift from user intent exactly as auto-made ADRs do; documented jobs/personas are load-bearing governance artifacts the JTBD gate reviews every edit against, so a poorly-auto-derived job/persona propagates wrong alignment verdicts) × Likelihood: 3 (Likely — every `wr-jtbd:update-guide` run and every agent-derived job/persona that lands without a confirm pass)
**Effort**: M — direct mirror of the ADR-066 architect mechanism onto the wr-jtbd plugin (marker + detector + nudge + drain + born-confirmed update-guide + tests); the pattern is already built once
**WSJF**: 9/2 = **4.5** (Open multiplier 1.0)
**Release vehicle**: `@windyroad/jtbd` — surfaces 1 & 2 (marker + detector + nudge + `/wr-jtbd:confirm-jobs-and-personas` drain + born-confirmed `update-guide`) shipped via commit `0077bacf` (2026-05-25, "feat(jtbd): JTBD/persona human-oversight mechanism (P288, ADR-068)"); surface-3 completion (build-upon guard, P323) shipped `@windyroad/jtbd@0.8.4` (changeset `115b2f2`). All deliverables present in current published `@windyroad/jtbd@0.12.7`.

## Fix Released

Fully shipped via ADR-068 + commit `0077bacf` (2026-05-25). The fix commit is an ancestor of HEAD and of the latest `@windyroad/jtbd` version-packages bump; all five named deliverables exist on disk and are published in `@windyroad/jtbd@0.12.7` (npm latest). Verified this iter:

- **Marker** — `human-oversight: confirmed` + `oversight-date` on JTBD + persona frontmatter (ADR-068 field verbatim; `unconfirmed` AFK-fallback enum added by the 2026-06-02 amendment).
- **Detector** — `packages/jtbd/scripts/detect-unoversighted.sh` + bin shim `packages/jtbd/bin/wr-jtbd-detect-unoversighted` (ADR-049). 12/12 bats green.
- **SessionStart nudge** — `packages/jtbd/hooks/jtbd-oversight-nudge.sh`, registered in `hooks.json` (matcher `startup`); honours the shared `WR_SUPPRESS_OVERSIGHT_NUDGE` AFK guard. 6/6 bats green (guard controlled).
- **Drain skill** — `/wr-jtbd:confirm-jobs-and-personas` (`packages/jtbd/skills/confirm-jobs-and-personas/SKILL.md`).
- **Born-confirmed** — `packages/jtbd/skills/update-guide/SKILL.md` writes the marker via `wr-jtbd-mark-oversight-confirmed`, gated by the `jtbd-oversight-marker-discipline.sh` PreToolUse hook. 10/10 marker-discipline bats green. Single-artifact predicate `is-job-or-persona-unconfirmed.sh` 17/17 bats green.
- **Supporting** — `scripts/` dir + `bin/`/`scripts/` in `package.json#files`; AFK guard reuse confirmed (no orchestrator change needed).

Transitioned Open→Verifying 2026-06-27 by the work-problems orchestrator — the ticket was mis-filed as Open after the fix shipped (the "fixed-by-later-work, never transitioned" stranded-shipped class). No build this iter; verify-and-transition only.

**Note (separate defect, flagged for retro capture):** the two oversight-nudge bats suites (`jtbd-oversight-nudge.bats` AND the architect sibling `architect-oversight-nudge.bats`) are non-hermetic against an inherited `WR_SUPPRESS_OVERSIGHT_NUDGE=1` — the AFK orchestrator exports it (work-problems Step 5), so the count-emitting tests self-suppress and fail spuriously when run inside an AFK iter. CI is green (the guard is unset there). This is a test-hermeticity flake class, NOT a P288 mechanism defect — the hook is correct (all 6 pass with the guard unset). Fix: `unset WR_SUPPRESS_OVERSIGHT_NUDGE` in each suite's `setup()` so the guard is test-controlled.

**Awaiting user verification** — confirm in an interactive session that the SessionStart nudge surfaces the unoversighted job/persona count and `/wr-jtbd:confirm-jobs-and-personas` drains it.

## Description

User direction 2026-05-25: *"similar to how we are saying ADRs need human confirmation, new jobs to be done and new personas need human confirmation too."*

P283 / ADR-066 established that recorded **decisions** (ADRs) must carry human oversight: a `human-oversight: confirmed` + `oversight-date` frontmatter marker (orthogonal to `status:`), a token-cheap grep detector, a session-start nudge (AFK-self-suppressed), a `/wr-architect:review-decisions` drain skill, and born-confirmed recording via `create-adr`. The same risk applies to the **other auto-made governance artifacts**: JTBDs (`docs/jtbd/<persona>/JTBD-NNN-*.md`) and personas (`docs/jtbd/<persona>/persona.md`) can be agent-derived without a human confirming they reflect real user/business need — and the JTBD gate reviews every project edit against them, so a drifted job/persona propagates wrong alignment verdicts.

This ticket ships the symmetric **JTBD/persona human-oversight mechanism** in the `wr-jtbd` plugin, mirroring ADR-066:

1. **Marker** — `human-oversight: confirmed` + `oversight-date` on JTBD files AND persona.md files (same field as ADR-066; orthogonal to `status:`).
2. **Detector** — `wr-jtbd-detect-unoversighted` shim (ADR-049) over `docs/jtbd/**/*.md` frontmatter (persona.md + JTBD-*.md; excludes README).
3. **Session-start nudge** — a wr-jtbd SessionStart hook reporting `N jobs/personas lack human oversight — run <drain skill>`; self-suppresses on `WR_SUPPRESS_OVERSIGHT_NUDGE=1` (REUSE the architect AFK guard — work-problems Step 5 already exports it, so no orchestrator change needed).
4. **Drain skill** — confirms unoversighted jobs/personas in batches via AskUserQuestion (confirm/amend/reject), writing the marker on confirm.
5. **Born-confirmed** — `wr-jtbd:update-guide` writes the marker when the user confirms a new/edited job or persona.

## Symptoms

(deferred to investigation)

- `wr-jtbd:update-guide` and agent-derived JTBD/persona authoring land files with `status: proposed` but no record a human confirmed the job/persona reflects real need.
- The JTBD edit gate (`jtbd-enforce-edit.sh`) reviews every project edit against `docs/jtbd/` — a drifted auto-made job/persona propagates wrong alignment verdicts suite-wide.
- No detection / nudge / drain surface for unoversighted jobs/personas (the architect plugin has all three post-ADR-066; the jtbd plugin has none).

## Workaround

Confirm jobs/personas verbally at `update-guide` time; no persistent marker, no drift detection.

## Root Cause Analysis

### Investigation Tasks

- [x] Decided: **separate ADR-068** (JTBD/persona oversight, citing ADR-066 as the precedent pattern), per the lean — mechanisms are plugin-specific (`@windyroad/architect` vs `@windyroad/jtbd`).
- [x] Confirmed the marker reuses the ADR-066 field (`human-oversight: confirmed` + `oversight-date`) verbatim; cross-surface consistency driver in ADR-068.
- [x] Decided the drain skill name: **`/wr-jtbd:confirm-jobs-and-personas`** (user via AskUserQuestion 2026-05-25) — distinct "confirm" verb, names both surfaces it drains.
- [x] Built: detector (`detect-unoversighted.sh`) + shim (`bin/wr-jtbd-detect-unoversighted`), SessionStart nudge (`jtbd-oversight-nudge.sh`) + hooks.json `startup` registration, drain skill (`confirm-jobs-and-personas`), update-guide born-confirmed write (+ `mark-oversight-confirmed.sh` + `jtbd-oversight-marker-discipline.sh` PreToolUse gate), `scripts/` dir + `package.json#files` (`scripts/`, `bin/`), bats (detect 12/12, nudge 6/6, marker-discipline 10/10, predicate 17/17).
- [x] Verified the AFK guard reuse (`WR_SUPPRESS_OVERSIGHT_NUDGE`) — the jtbd nudge honours the shared var; no orchestrator edit needed.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none — investigation can begin immediately)
- **Composes with**: P283 / ADR-066 (the precedent mechanism this mirrors), the wr-jtbd plugin (`update-guide`, `review-jobs`, the edit gate), ADR-049 (shim grammar), ADR-040 (SessionStart nudge precedent).

## Related

(captured 2026-05-25 — user direction extending the ADR-066 human-oversight principle to the JTBD surface)

- **P283** / **ADR-066** — the precedent: human-oversight marker + detector + nudge + drain for ADRs. This ticket is the JTBD/persona sibling.
- `packages/jtbd/skills/update-guide/` — born-confirmed write site.
- `packages/jtbd/skills/review-jobs/` — existing alignment-review skill (name collision to resolve for the drain).
- `packages/jtbd/hooks/` — SessionStart nudge target (no SessionStart event yet).
- `packages/architect/scripts/detect-unoversighted.sh` + `architect-oversight-nudge.sh` + `skills/review-decisions/` — the templates to mirror.
