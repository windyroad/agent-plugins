---
status: proposed
rfc-id: p344-work-problems-step-3-5-jtbd-ratification-predicate
reported: 2026-06-03
decision-makers: [Tom Howard]
problems: [P344]
adrs: [ADR-068, ADR-074, ADR-071, ADR-076, ADR-049, ADR-080]
jtbd: [JTBD-006]
stories: []
---

# RFC-016: P344 — `/wr-itil:work-problems` Step 3.5 JTBD ratification predicate-check (orchestrator-layer mirror of ADR-068 surface 3)

**Status**: proposed
**Reported**: 2026-06-03
**Problems**: P344
**ADRs**: ADR-068 (JTBD + persona human-oversight marker — surface 3 single-artifact predicate mirrored to orchestrator layer), ADR-074 (Confirm decision substance before building dependent work — enforcement-surface 2 names `/wr-itil:work-problems` as the propose-fix process guard locus; JTBD-as-driver is the symmetric sibling to ADR-as-driver), ADR-071 (every fix goes through an RFC — why this RFC exists), ADR-076 (tier-first Step 3 selection — preserved by the Step 3.5 loopback), ADR-049 (plugin-bundled scripts resolve via bin/ on $PATH — new helper + shim follow the PATH-shim grammar), ADR-080 (highest-version-wins shim wrapper — new shim regenerated from the canonical template)
**JTBD**: JTBD-006 (Progress the Backlog While I'm Away — wasted-iter-dispatch class against unratified-JTBD tickets closes when the predicate fires at the orchestrator layer instead of after iter dispatch)

> **Problem-traced thin RFC (ADR-071 unconditional compliance).** This RFC carries the P344 fix under the RFC-first framework per ADR-071 / ADR-072 / ADR-073. It carries **no independent decisions** (per ADR-070 + the user-pinned `feedback_no_shortcuts_no_softening`): the locus choice (per-ticket Step 3.5 vs. preflight Step 0c) was user-direction-pinned in the driving iter prompt ("amend SKILL.md Step 3 (selection)… after picking the highest-WSJF actionable ticket"); the per-JTBD predicate polarity inversion is mechanical re-use of the canonical `is-job-or-persona-unconfirmed.sh` contract (ADR-068 surface 3); the `outstanding_questions` schema mapping (`category: "direction"`) is the ADR-044 category-1 default the existing SKILL.md schema already provides. Pattern modelled on RFC-015 (the P333 retro-fit) and RFC-007 (the P260 retro-fit). Status transitions `proposed → in-progress → verifying` alongside the P344 ticket per ADR-022 fold-fix.

## Summary

P344: `/wr-itil:work-problems` Step 3 selects the highest-WSJF actionable ticket in the highest non-empty tier (ADR-076) using a deterministic WSJF + Known-Error-first + effort + reported-date + ID ladder, then dispatches the iter-subprocess (Step 5). Selection has no check for "are the JTBDs this ticket cites in a ratifiable state". The check happens only *inside* the iter subprocess via the `wr-jtbd:agent` `[Unratified Dependency]` verdict (ADR-068 surface 3). When the selected ticket cites an unratified JTBD, the iter spends discovery cost (~$3–5, 5–10 min per iter) re-confirming substrate the orchestrator could check for the cost of a `grep` + per-JTBD predicate call. Witnessed 2026-05-31 session 9 iter 5: P082 dispatched against unratified JTBD-001 + JTBD-006 → iter correctly skipped per ADR-074 substance-confirm-before-build, but the per-dispatch cost was wasted.

The fix adds a pre-dispatch predicate-check at Step 3.5 (new substep between Step 3 selection and Step 4 classification): grep the ticket for cited `JTBD-NNN` IDs, invoke the canonical per-JTBD predicate (the ADR-068 surface 3 `wr-jtbd-is-job-or-persona-unconfirmed` shim) per cited JTBD, aggregate unratified IDs. If any unratified JTBD is detected, route the ticket to Step 4's user-answerable skip path + queue an `outstanding_questions` entry (`category: "direction"`) naming the unratified JTBDs + ticket ID + remedy (run `/wr-jtbd:confirm-jobs-and-personas`); loop back to Step 3 to re-run the tier-first selection over the remaining backlog minus the skipped ticket. If every actionable ticket is filtered out, Step 2 stop-condition #1 (no actionable problems) fires naturally and the accumulated queue entries surface at Step 2.4 gate (a) per the existing batched-`AskUserQuestion` contract.

## Driving problem trace

- **P344** (`docs/problems/open/344-work-problems-orchestrator-should-predicate-check-cited-jtbds-of-selected-ticket-before-iter-dispatch.md`) — work-problems orchestrator should predicate-check the cited JTBDs of the selected ticket BEFORE dispatching the iter-worker. Status: Open → Verification Pending (fold-fix per ADR-022 P143 lands the verifying transition in the same commit as the fix).

## Scope

Single fold-fix commit (post the capture-rfc skeleton commit per ADR-014 capture-grain) — helper script + shim + SKILL.md amendment + behavioural bats + ticket fold-fix transition + changeset:

- `packages/itil/scripts/check-ticket-jtbd-ratification.sh` (NEW) — orchestrator-layer wrapper that extracts cited `JTBD-NNN` IDs from a ticket file and delegates per-JTBD ratification to the ADR-068 surface 3 predicate. Polarity inverted: outer exit 0 = all ratified, exit 1 = ≥1 unratified (one ID per stdout line, `(unresolved)` tag for exit-2 cases). Silent-pass on missing per-JTBD shim (degenerate adopter case per ADR-031 dependency).
- `packages/itil/bin/wr-itil-check-ticket-jtbd-ratification` (NEW) — ADR-049 PATH shim regenerated from `packages/shared/lib/shim-wrapper-template.sh` via `scripts/sync-shim-wrappers.sh` (ADR-080).
- `packages/itil/skills/work-problems/SKILL.md` — amend Step 3 region (between current Step 3 selection and Step 4 classification) to add Step 3.5 JTBD ratification predicate-check. Pin: `category: "direction"` schema mapping, tier-preserving loopback, natural stop-condition #1 fall-through.
- `packages/itil/skills/work-problems/test/work-problems-step-3-5-jtbd-ratification-predicate.bats` (NEW) — behavioural bats fixture asserting: all-ratified → exit 0; ≥1 unratified → exit 1 + ID on stdout; unresolved JTBD ID → exit 1 + `(unresolved)` tag; no JTBDs cited → exit 0; missing ticket file → exit 2; missing per-JTBD shim → silent-pass exit 0.
- `docs/problems/verifying/344-*.md` — fold-fix ticket transition (Open → Verification Pending; renamed `docs/problems/open/` → `docs/problems/verifying/`) per ADR-022 P143.
- `.changeset/wr-itil-p344-jtbd-ratification-predicate.md` — `@windyroad/itil` patch changeset; on release advances the P344 status to Verifying-by-release and this RFC `proposed → verifying`.

## Decisions carried (none — all choices below-ADR-bar or pinned by existing ADRs)

This RFC carries no independent architectural decisions. The substantive choices are pinned by existing decisions or by user direction:

1. **Locus (per-ticket Step 3.5 vs. preflight Step 0c)** — user-direction-pinned in the driving iter prompt. Architect advisory lean was Step 0c (preflight, mirroring Step 0b); per-ticket shape is defensible (cheaper amortisation when iter count is low; matches Step 3 selection locus). Captured as out-of-scope dogfood-revisit candidate per the architect review.
2. **Per-JTBD predicate polarity** — mechanical re-use of `is-job-or-persona-unconfirmed.sh` (ADR-068 surface 3). Outer-script polarity inversion documented verbatim in the helper docstring + bats coverage.
3. **`outstanding_questions` schema mapping** — `category: "direction"` (no schema change) per ADR-044 category-1; question template names unratified JTBDs + remedy; context lists the IDs.
4. **Loopback tier preservation** — re-run tier-first selection (ADR-076 Tier 0 → Tier 1 → Tier 2; within-tier WSJF ladder) over remaining backlog minus skipped ticket. If none remains, Step 2 stop-condition #1 fires naturally.

## Deferred (advisory, captured for follow-up)

1. **Sibling-class predicate for ADRs cited as Decision Drivers** — same gap exists for ADRs (ADR-074 master class). P344 Investigation Task 5 already notes this. Out of scope for this RFC; defer to a follow-on ticket after Step 3.5 dogfoods.
2. **Option-B preflight-at-Step-0c revisit** — if the per-ticket shape's amortisation cost surfaces as a friction signal across dogfood iters, revisit as a deviation candidate.

## Tasks

- [ ] Helper script `packages/itil/scripts/check-ticket-jtbd-ratification.sh`.
- [ ] PATH shim `packages/itil/bin/wr-itil-check-ticket-jtbd-ratification` (regenerated via `scripts/sync-shim-wrappers.sh` per ADR-080).
- [ ] SKILL.md Step 3.5 amendment.
- [ ] Behavioural bats fixture `packages/itil/skills/work-problems/test/work-problems-step-3-5-jtbd-ratification-predicate.bats`.
- [ ] P344 ticket fold-fix transition (Open → Verification Pending; `docs/problems/open/` → `docs/problems/verifying/`).
- [ ] `@windyroad/itil` patch changeset queued.
- [ ] Release the held changeset → P344 `Verifying → Closed` (release-gated; this RFC `proposed → verifying`).

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Verification

The held `@windyroad/itil` changeset `wr-itil-p344-jtbd-ratification-predicate.md` is the release marker. On release, P344 transitions `Verifying-by-fold-fix → Closed-by-release-evidence` (per ADR-022) and this RFC transitions `proposed → verifying`. User-side verification: a `/wr-itil:work-problems` AFK invocation in a working tree where the highest-WSJF ticket cites an unratified JTBD should skip that ticket at Step 3.5, queue the JTBD-ratification entry to `outstanding_questions`, loop back to the next-WSJF actionable; loop-end Step 2.4 gate (a) surfaces the queued entry via batched `AskUserQuestion`. Behavioural bats fixture asserts the predicate contract at the helper-script level.

## Related

- **P344** — driving problem ticket (Open → Verification Pending; fold-fix landed alongside this RFC).
- **ADR-068** — JTBD + persona human-oversight marker; surface 3 single-artifact predicate (`is-job-or-persona-unconfirmed.sh`) is mirrored to the orchestrator layer here.
- **ADR-074** — Confirm decision substance before building dependent work; enforcement-surface 2 names `/wr-itil:work-problems` as the propose-fix process guard locus (JTBD-as-driver is the symmetric sibling to ADR-as-driver).
- **ADR-071** — every fix goes through an RFC; this RFC is the unconditional-trace compliance instance for the P344 fix.
- **ADR-076** — tier-first Step 3 selection; preserved by the Step 3.5 loopback contract.
- **ADR-049 / ADR-080** — PATH shim grammar + highest-version-wins shim wrapper; the new shim follows.
- **RFC-015** — P333 retro-fit RFC; structural template this RFC follows (thin problem-traced retro-fit, no independent decisions).
- **RFC-007** — P260 retro-fit; second structural template.
- **JTBD-006** — Progress the Backlog While I'm Away; the AFK-persona job the predicate sharpens.
