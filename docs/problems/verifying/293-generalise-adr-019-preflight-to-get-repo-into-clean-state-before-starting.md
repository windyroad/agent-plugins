# Problem 293: Generalise ADR-019 preflight from "fetch + ff-only divergence" to "get the repo into a clean state before starting"

**Status**: Verifying
**Reported**: 2026-05-25
**Priority**: 6 (Medium) — Impact: 2 (Minor — the current preflight handles the divergence case correctly; the gap is that it doesn't cover the broader "repo isn't clean" situations, so an orchestrator can start work on an untidy tree; recoverable, not breaking) × Likelihood: 3 (Possible — every AFK orchestrator start; uncommitted-work and messy-tree states occur regularly)
**Effort**: M — ADR-019 amendment generalising the preflight + reconciling with P109 (session-continuity detection) + the work-problems Step 0 implementation
**WSJF**: 6/2 = **3.0** (Open multiplier 1.0)

## Description

Surfaced during the P283/ADR-066 ADR-oversight drain (2026-05-25). When ADR-019 (AFK orchestrator preflight: fetch-origin and divergence handling) was presented for human-oversight confirmation, the user declined to confirm it as-recorded and directed a generalisation:

> User direction 2026-05-25 (drain): *"what I really want is to get the repo into a clean state before starting. Sometimes that's a pull, sometimes that needs some commits. Sometimes it's in a mess and needs decision input via AskUserQuestion."*

ADR-019 currently decides a narrow slice: mandatory `git fetch` + `ff-only` pull on trivial divergence, stop-and-report on non-fast-forward. The user wants the preflight reframed as **"get the repo into a clean state before starting,"** with (at least) three branches:

1. **Pull** — origin moved, trivial fast-forward (the current ADR-019 case).
2. **Commit** — there is uncommitted work that should be committed before starting (e.g. a prior session left staged/working-tree changes that belong in a commit).
3. **AskUserQuestion** — the tree is genuinely messy (ambiguous uncommitted state, non-fast-forward divergence, partial prior-session work) and needs human decision input on how to clean it up.

This overlaps and should reconcile with **P109** (session-continuity detection pass — already in work-problems Step 0, which enumerates prior-session partial-work signals and halts/prompts). The generalised ADR-019 is the umbrella "clean-state preflight" that P109's detection feeds into.

ADR-019 is **left unoversighted** (P283/ADR-066 marker withheld) until this generalisation lands and the amended decision is re-confirmed — mirroring P287/P289/P290/P292's pattern.

## Symptoms

(deferred to investigation)

- ADR-019 Decision Outcome only covers fetch + ff-only divergence + stop-on-non-ff; no branch for "uncommitted work should be committed first" or "messy tree → AskUserQuestion."
- work-problems Step 0 already has a P109 session-continuity detection pass that halts on prior-session partial work (AFK) / prompts via AskUserQuestion (interactive) — but ADR-019 (the decision) doesn't frame the broader clean-state goal these implement.

## Root Cause Analysis

### Investigation Tasks

- [ ] Amend ADR-019 to reframe the decision as "get the repo into a clean state before starting," enumerating the branches: trivial-pull (ff-only), commit-existing-work, and messy-tree → AskUserQuestion (interactive) / halt-with-report (AFK).
- [ ] Reconcile with P109 (session-continuity detection): P109's signal enumeration feeds the clean-state branch decision; ADR-019 is the umbrella decision, P109 the detection mechanism. Avoid duplication / contradiction.
- [ ] Define the "needs commit" branch precisely: when is uncommitted work auto-committable vs needs-user-decision? (Likely: clean it only when provenance is unambiguous; otherwise AskUserQuestion / halt per ADR-013 Rule 6.)
- [ ] Verify consistency with the work-problems Step 0 implementation (fetch/divergence + session-continuity + README reconcile + auto-migrate) — the amend should describe the live behaviour, generalised.
- [ ] Re-confirm amended ADR-019 via `/wr-architect:review-decisions` → write `human-oversight: confirmed`.

## Dependencies

- **Blocks**: ADR-019 human-oversight confirmation (held until generalisation lands).
- **Blocked by**: none.
- **Composes with**: P109 (session-continuity detection — the detection mechanism this umbrella decision frames), work-problems Step 0 (the live preflight implementation), ADR-013 Rule 6 (non-interactive fail-safe / AskUserQuestion routing), P283/ADR-066 (the drain that surfaced this).

## Related

(captured 2026-05-25 during the P283/ADR-066 oversight drain)

- **P109** — session-continuity detection pass (work-problems Step 0); the detection mechanism the generalised ADR-019 frames.
- **P287 / P289 / P290 / P291 / P292** — sibling drain-surfaced reworks (same "withhold marker + capture rework" pattern).
- **ADR-019** (`docs/decisions/019-afk-orchestrator-preflight.proposed.md`) — amendment target.
- **ADR-013** Rule 6 — the interactive-vs-AFK routing the messy-tree branch uses.

## Fix Released

**Released**: 2026-06-08 (AFK work-problems iter — P293 worked)

**Shape**: ADR amendment (in-place, ADR-066 P301 marker-only-diff exemption since substance changed; oversight marker reset to `unconfirmed` for next drain promotion per ADR-066 substance-change clearance) + SKILL.md Step 0 prose framing + JTBD-006 desired-outcomes alignment.

**Changes landed:**

- `docs/decisions/019-afk-orchestrator-preflight.proposed.md` — full reframe. Context and Problem Statement now names the umbrella "get the repo into a clean state before starting" goal. Decision Drivers cite JTBD-006 (existing — broadened to audit-trail + graceful-stop on Branch 3 surface), JTBD-001 (new — Branch 2 gate composition), and JTBD-008 (new — RFC-trace invariant). Decision Outcome enumerates 3 branches: Branch 1 (Pull, ff-only — existing); Branch 2 (Commit, deferred — discriminator = provenance unambiguous AND risk within appetite; current implementation conservatively routes Branch 2 → Branch 3 until follow-up auto-commit mechanism lands); Branch 3 (AskUserQuestion / AFK-halt, with deliberate carve-out note from the 2026-06-06 Rule 6 queue-and-continue default). Session-continuity signal enumeration preserved verbatim under Branch 3 detection mechanism subsection (architect Condition 2 — protects the contract-assertion bats). Audit-trail commit-subject convention for Branch 2: `chore(preflight): recover prior-session in-flight work — <ticket-ref>` (JTBD Condition 3). Frontmatter flipped to `human-oversight: unconfirmed` with `oversight-date` removed (architect Condition 3 — `oversight-date` semantics pair with the active `confirmed` marker; carrying it alongside `unconfirmed` is malformed).
- `packages/itil/skills/work-problems/SKILL.md` Step 0 — added a leading 3-branch prose framing naming the umbrella goal and the discriminator. Existing fetch/divergence table re-labelled as Branch 1 mechanism; existing P109 session-continuity detection pass re-labelled as Branch 3 detection mechanism. Non-Interactive Decision Making table — origin-diverged row tagged Branch 1 / Branch 3; new Branch 2 (deferred) row added; session-continuity row tagged Branch 3 with the AFK-halt carve-out note.
- `docs/jtbd/developer/JTBD-006-work-backlog-afk.proposed.md` — Desired Outcomes preflight bullet rewritten to reflect the 3-branch umbrella shape (JTBD Condition 5).
- `docs/decisions/README.md` — compendium regenerated per ADR-077 (architect Condition 4); reflects the `human-oversight: unconfirmed` flip + chosen-option summary update.

**Investigation tasks resolution:**

- [x] Amend ADR-019 to reframe as "clean state before starting" with 3 branches.
- [x] Reconcile with P109 — positioned as Branch 3 detection mechanism; P109 closure preserved (architect Condition 2 retains the 5-signal enumeration verbatim).
- [x] Define the "needs commit" branch precisely — discriminator encoded (provenance unambiguous AND risk within appetite). Auto-commit implementation deferred to follow-up ticket (to be captured separately); current behaviour conservatively routes Branch 2 → Branch 3.
- [x] Verify consistency with work-problems Step 0 — SKILL.md prose framing updated to match the reframed ADR; the live implementation matches the reframed contract (Branch 1 + Branch 3 fully implemented; Branch 2 deferred per Condition 1).
- [ ] Re-confirm amended ADR-019 via `/wr-architect:review-decisions` — VERIFICATION GATE: this is the verification step. Next interactive drain promotes `human-oversight: unconfirmed` → `confirmed` once the user reviews the amended substance.

**Gates**: architect + JTBD reviews approved the amendment shape before the edits (APPROVE-WITH-CONDITIONS; all five architect conditions and all five JTBD conditions were incorporated into the landed amendment).

**Verification criterion**: the next interactive `/wr-architect:review-decisions` drain presents the amended ADR-019 substance; the user either confirms (→ Closed) or amends further (→ back to Open / Known Error with new scope captured).

**Follow-up**: Branch 2 auto-commit implementation — a separate problem ticket should be captured covering (a) the auto-commit mechanism, (b) JTBD-001 gate composition wiring (architect/JTBD/style/voice-tone/TDD/risk-scorer pre-existing-edit re-gate), (c) the commit-subject convention enforcement, (d) the contract-assertion bats. Out of scope for P293 per architect Condition 1 + JTBD Condition 1's "documentation-shape, not blockers" verdict.
