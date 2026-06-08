# Problem 295: ADR-043 deep layer (`analyze-context`) needs an automatic cadence — on-demand-only means it never runs

**Status**: Known Error
**Reported**: 2026-05-25
**Root cause confirmed**: 2026-06-08 (this commit lands the fix; pending release)
**Priority**: 6 (Medium) — Impact: 2 (Minor — the deep context analysis exists but, being on-demand-only, effectively never fires; the cheap layer carries all the load and the deep insights are never realised; no breakage, just an un-exercised capability) × Likelihood: 3 (Likely — every retro runs the cheap layer; the deep layer's zero-cadence means zero runs)
**Effort**: M — ADR-043 amendment (add a proactive lower-frequency cadence to the deep layer) + run-retro trigger wiring + the analyze-context skill
**WSJF**: 6/2 × 2.0 = **6.0** (Known Error multiplier 2.0)

## Description

Surfaced during the P283/ADR-066 ADR-oversight drain (2026-05-25). When ADR-043 (Progressive context-usage measurement for retro sessions) was presented for human-oversight confirmation, the user amended it:

> User direction 2026-05-25 (drain): *"the second layer should happen proactively as well with less frequency than the first layer. Generally speaking, if there is no automatic cadence, it does not happen."*

ADR-043 ships two layers: a **cheap layer** (Step 2c in `run-retro`, runs every retro) and a **deep layer** (`/wr-retrospective:analyze-context`, **user-invoked only**). The user wants the deep layer to ALSO fire **proactively at a lower cadence** than the cheap layer (e.g. every Nth retro, or periodically) — because an on-demand-only surface, in practice, never runs.

**General principle (user, 2026-05-25): "if there is no automatic cadence, it does not happen."** This is broader than ADR-043 — it is the same root cause behind P291 (ADRs never reach `accepted` because no acceptance cadence fires) and is why the P283/P288 oversight drains needed a session-start nudge rather than relying on the user to remember the drain skill. On-demand-only governance/maintenance surfaces get forgotten; they need an automatic cadence (even a low-frequency one) to actually happen. See memory `feedback_automatic_cadence_or_it_doesnt_happen`.

ADR-043 is **left unoversighted** (P283/ADR-066 marker withheld) until this amendment lands and the amended decision is re-confirmed.

## Symptoms

(deferred to investigation)

- `/wr-retrospective:analyze-context` (the deep layer) has no automatic trigger — it fires only when the user explicitly invokes it, which means in practice it rarely/never runs.
- The cheap Step 2c layer runs every retro, so all context-measurement load falls on it; the deep layer's richer analysis (per-turn attribution, per-plugin decomposition, suggestion generation) is never realised.

## Root Cause Analysis

**Confirmed root cause** (2026-06-08): the original ADR-043 (Progressive context-usage measurement and reporting for retrospective sessions) shipped the deep layer (`/wr-retrospective:analyze-context`) as **on-demand-only** — `packages/retrospective/skills/analyze-context/SKILL.md` line 20 (pre-fix) carried *"Never auto-fires. Per ADR-043 + ADR-013 Rule 6 (AFK fallback), this skill is invoked only by explicit user direction."* and `packages/retrospective/skills/run-retro/SKILL.md` Step 2c only EMITTED an advisory line (*"Deep analysis recommended — invoke /wr-retrospective:analyze-context"*) without auto-invoking. The Amendment 2026-05-26 named the requirement (deep layer MUST have automatic trigger) but deferred mechanism settlement to a follow-up ticket — this ticket — and the cheap-layer trigger condition was already being computed (line 232: *"older than 14 days OR a bucket's delta exceeds +20%"*) but only surfaced as an advisory, not as an auto-invocation.

The same root cause class drives P291 (ADRs never reach `accepted` because no acceptance cadence fires). The general principle (user direction 2026-05-25 verbatim: *"the second layer should happen proactively as well with less frequency than the first layer. Generally speaking, if there is no automatic cadence, it does not happen."*) is captured in the user memory `feedback_automatic_cadence_or_it_doesnt_happen`. The fix lifts the existing trigger detection from advisory-only to auto-invocation, with a once-per-day guard via the snapshot artefact itself.

### Fix Strategy

Settled mechanism (architect + JTBD reviewed PASS, 2026-06-08):

1. **Combined whichever-comes-first trigger** in `run-retro` Step 2c step 4 (cheap layer):
   - **Calendar-elapse**: most recent `docs/retros/*-context-analysis.md` older than 14 days OR no prior report.
   - **Delta-breach**: any bucket's byte total changed by >20% since prior snapshot (HTML-comment trailer).
2. **Once-per-day guard**: skip auto-fire when `docs/retros/<TODAY>-context-analysis.md` already exists. The snapshot artefact itself is the state — no new persistent state file needed (mirrors ADR-009's explicit non-use in ADR-043).
3. **Auto-invoke** `/wr-retrospective:analyze-context` via the Skill tool when trigger holds AND once-per-day guard not satisfied. Identical behaviour in interactive and AFK modes (deep layer is silent — never invokes `AskUserQuestion`).
4. **Threshold grounding** per ADR-026 line 92: 14 days + 20% are `not estimated — chosen as initial values, reassess after 6 months of cross-project use`. Comparable-prior anchors: ADR-040 session-start refresh envelope (calendar) + ADR-040 Tier 3 briefing-budget breach grain (delta percentage).

### Investigation Tasks

- [x] Amend ADR-043 with the trigger choice + rationale (Amendment 2026-06-08).
- [x] Flip "Never auto-fires" / "never auto-routes" prose in both run-retro Step 2c and analyze-context SKILL.md (3 sites + frontmatter description).
- [x] Wire the auto-invoke in run-retro Step 2c step 4 (replaces the advisory-line branch).
- [x] Behavioural bats fixtures: extend `run-retro-context-usage-step-2c.bats` + `analyze-context-skill-contract.bats` with new trigger-condition, once-per-day-guard, auto-fire, and supersession-guard assertions (10 new tests; 187 / 187 pass).
- [x] Architect + JTBD review (both PASS 2026-06-08).
- [ ] Re-confirm amended ADR-043 via `/wr-architect:review-decisions` after this commit lands.
- [ ] Reconcile with the general cadence principle — consider whether other on-demand-only governance surfaces (oversight drains' deep passes, maturity assessment per ADR-053, etc.) need the same treatment (separate ticket per surface — out of scope here).

## Fix Status

Fix implemented and landed in this commit. Awaiting release — on next `push:watch` + `release:watch` cycle the ticket transitions Known Error → Verification Pending per ADR-022 (file renamed to `.verifying.md`, `## Fix Released` section added with version + commit SHA).

## Dependencies

- **Blocks**: ADR-043 human-oversight confirmation (held until amended).
- **Blocked by**: none.
- **Composes with**: P291 (same root cause — no cadence means the action doesn't happen; ADRs never accepted), ADR-040 (session-start cadence precedent), the run-retro cadence, P283/ADR-066 (the drain that surfaced this).

## Related

(captured 2026-05-25 during the P283/ADR-066 oversight drain)

- **P287 / P289 / P290 / P291 / P292 / P293 / P294** — sibling drain-surfaced reworks.
- **P291** — same "no automatic cadence" root cause (ADRs stuck in proposed because no acceptance cadence fires).
- **ADR-043** (`docs/decisions/043-progressive-context-usage-measurement.proposed.md`) — amendment target.
- memory `feedback_automatic_cadence_or_it_doesnt_happen` — the generalised principle.
