# Problem 297: ADR-047 — governance-artefact scaffolding should be a SessionStart hook (per-project, automatic), not an inline `/install-updates` step

**Status**: Open
**Reported**: 2026-05-25
**Priority**: 9 (Med High) — Impact: 3 (Moderate — the inline-/install-updates mechanism only scaffolds for sibling projects reachable from THIS project's /install-updates run; it completely misses adopter projects on other machines, and any project where /install-updates is never run against it; the scaffold's whole point — that an adopter with a policy file gets its artefact — silently fails for the majority of real adopters) × Likelihood: 3 (Likely — most adopter projects are not reachable from this repo's /install-updates)
**Effort**: M — move the scaffold from an inline /install-updates step to a SessionStart hook (per-plugin, fires per-project-session) + reconcile with the ADR-040 SessionStart precedent
**WSJF**: 9/2 = **4.5** (Open multiplier 1.0) — corrected 2026-05-26: Impact 3 × Likelihood 3 = 9, prior Priority line said 6 in error

## Description

Surfaced during the P283/ADR-066 ADR-oversight drain (2026-05-25). When ADR-047 (install-updates scaffolds governance artefacts when a policy file is present but its artefact is missing) was presented for human-oversight confirmation, the user **rejected the mechanism**:

> User direction 2026-05-25 (drain): *"Inline scaffold step in `/install-updates` is the wrong choice. That happens from within this project for sibling projects. It would completely miss other projects on other machines. SessionStart hook scaffold unless you have a better option."*

ADR-047 chose "Option 1 — inline scaffold step in `/install-updates`". The defect: `/install-updates` runs **from this repo, pushing to sibling projects it knows about** — it is occasional, manual, and machine-local. It cannot reach adopter projects on other machines, and it never fires for projects that don't get `/install-updates` run against them. So the scaffold (policy-file-present-but-artefact-missing → scaffold the artefact) silently fails for the majority of real adopters.

The right mechanism is a **SessionStart hook** (per the cadence principle — memory `feedback_automatic_cadence_or_it_doesnt_happen`): it fires automatically in **every project on every machine** at session start, so any adopter with a policy file but a missing artefact gets it scaffolded locally. (Considered: no better option was identified — SessionStart is the natural per-project automatic trigger, matching ADR-040 / the ADR-066/068 oversight nudges. PreToolUse/edit-gate is edit-triggered, wrong shape; the inline /install-updates step is the rejected one.)

ADR-047 is **left unoversighted** (P283/ADR-066 marker withheld) until amended (mechanism → SessionStart hook) and re-confirmed.

## Symptoms

(deferred to investigation)

- ADR-047's scaffold only fires inside this repo's `/install-updates` run for enumerated sibling projects; adopters on other machines / unreached projects never get the scaffold.
- The scaffold's value (auto-create docs/risks/ when RISK-POLICY.md exists, etc.) is per-adopter-project, but the trigger is centralised-and-manual — a mechanism/intent mismatch.

## Root Cause Analysis

### Investigation Tasks — Phase 1 (landed 2026-06-08)

- [x] Amend ADR-047: changed chosen option from Option 1 (inline /install-updates step) to Option 3 (SessionStart hook nudge). In-place amendment under `## Amendment 2026-06-08 (P297)` heading; original Decision Outcome retained as historical.
- [x] Reconcile with ADR-040 / ADR-066 / ADR-068 / ADR-045: the new hook shape is read-only stderr nudge (not silent write), satisfying ADR-040's read-mostly contract. Hook mirrors the established ADR-066/068 nudge shape; ADR-045 Pattern 1 (silent-on-pass) + Pattern 5 (once-per-session) satisfied.
- [x] Scaffold interactivity decided: **nudge-then-scaffold-on-confirm**. The SessionStart hook emits a one-line stderr advisory pointing at `/wr-risk-scorer:bootstrap-catalog`; the scaffold write happens only when the user invokes the consumer skill. The hook never writes — respects [[feedback_lift_auto_decisions_to_human]] (governance artefact creation requires explicit user action).
- [x] `/install-updates` path retired (already done per the 2026-05-25 stale-reference cleanup in ADR-047 body — the inline step was already removed when install-updates was narrowed to a single global-cache refresh).
- [ ] Re-confirm amended ADR-047 via `/wr-architect:review-decisions` — **deferred to next interactive session**: AFK iter subprocess wrote `human-oversight: unconfirmed` per ADR-066 P348 (no AskUserQuestion access). The drain promotes once a human runs `/wr-architect:review-decisions` and substance-confirms via AskUserQuestion. User direction quote in the amendment body IS the substance, so the drain answer will be a one-step confirm.

### Investigation Tasks — Phase 2 (deferred)

- [ ] Generalise the scaffold-nudge pattern to sibling plugins where a policy-file → artefact-directory pair exists:
  - voice-tone (`docs/VOICE-AND-TONE.md` → `docs/voice-tone/`?) — scope confirmation needed; the pair may not be the right shape because voice-tone artefacts are typically inline in the policy file itself.
  - style-guide (`docs/STYLE-GUIDE.md` → `docs/style-guide/`?) — same scope confirmation.
  - architect (`docs/decisions/`) and jtbd (`docs/jtbd/`) do NOT need a scaffold-nudge: decisions/jobs live IN the directory with no separate policy file; ADR-066/068 oversight nudges cover the analogous gap for ratification, not scaffolding.
- [ ] If sibling pairs are confirmed in scope, extract a shared scaffold-nudge helper (e.g. `packages/shared/hooks/lib/scaffold-nudge.sh`) to avoid drift across plugin instances. The Phase 1 risk-scorer hook is a candidate template for the helper extraction.
- [ ] Decide whether a sibling ADR should generalise the pattern, or whether ADR-047 should grow further amendments to cover each pair.

## Phase 1 deliverables (2026-06-08)

- `packages/risk-scorer/hooks/risk-scorer-scaffold-nudge.sh` — new SessionStart hook.
- `packages/risk-scorer/hooks/hooks.json` — registers the new hook under `SessionStart` matcher `"startup"`.
- `packages/risk-scorer/hooks/test/risk-scorer-scaffold-nudge.bats` — 7-case behavioural fixture.
- `docs/decisions/047-install-updates-scaffolds-governance-artefacts.proposed.md` — Amendment 2026-06-08 (P297) section + frontmatter flipped to `human-oversight: unconfirmed` pending drain promotion.
- `docs/decisions/README.md` — compendium regenerated.

## Dependencies

- **Blocks**: ADR-047 human-oversight confirmation (held until amended).
- **Blocked by**: none.
- **Composes with**: ADR-040 (SessionStart precedent), ADR-045 (hook budget), ADR-066/068 (existing SessionStart oversight nudges — same event), memory `feedback_automatic_cadence_or_it_doesnt_happen` (the per-project-automatic-trigger principle), P283/ADR-066 (the drain that surfaced this).

## Related

(captured 2026-05-25 during the P283/ADR-066 oversight drain)

- **P287 / P289 / P290 / P291 / P292 / P293 / P294 / P295 / P296** — sibling drain-surfaced reworks.
- **ADR-047** (`docs/decisions/047-install-updates-scaffolds-governance-artefacts.proposed.md`) — amendment target.
- **ADR-040** (SessionStart surface), **ADR-045** (hook budget), **ADR-066/068** (SessionStart oversight nudges) — the SessionStart neighbours to compose with.
