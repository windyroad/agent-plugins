# Problem 271: `/wr-itil:review-problems` not auto-fired when needed — user has to remember to run it

**Status**: Verification Pending
**Reported**: 2026-05-18
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4
**Effort**: M (re-estimated 2026-05-18 — trigger condition + auto-dispatch wiring across work-problems/manage-problem/capture-problem surfaces + bats fixture)

## Description

> I'm finding that I have to remember to run review-problems. I'm expecting it to run automatically when needed

`/wr-itil:review-problems` is a heavyweight skill that re-rates Priority + Effort for deferred-placeholder tickets, refreshes WSJF Rankings + Verification Queue ordering, and updates `docs/problems/README.md`. Every `/wr-itil:capture-problem` invocation creates tickets with `(deferred — re-rate at next /wr-itil:review-problems)` placeholders that accumulate until the user manually invokes review-problems. The skill never auto-fires.

Worked example evident this session: 7 captures (P266, P267, P268, P269, P270, P271 — this one, plus pre-session P252/P264) all share the deferred-placeholder pattern, all wait for the user to remember to invoke review-problems. The user explicitly highlighted at this iteration mid-loop: "I'm finding that I have to remember to run review-problems. I'm expecting it to run automatically when needed."

**Auto-fire trigger candidates** (any of which could individually justify a review-problems auto-dispatch):

1. **N captures since last review** — e.g. after 3+ tickets accumulate with deferred-placeholder text since the last review, auto-fire at next safe point (loop-end Step 2.5, manage-problem Step 0 preflight, etc.).
2. **README.md `Last reviewed:` annotation older than X days** — e.g. >7 days since last full review (where "full review" means all open + known-error tickets re-rated, not just per-operation refresh).
3. **AFK orchestrator preflight detects stale rankings** — P187 captures this specific surface (orchestrator halts with "recommended next step" instead of auto-dispatching). P271 is the broader umbrella: P187's surface is one example of a class.
4. **Pre-iter dispatch when WSJF scores are deferred-placeholder** — if the top-ranked ticket has placeholder WSJF (just-captured), the orchestrator should re-rate before dispatching the iter (otherwise iter risks working an under-/over-rated ticket).
5. **Pre-release-cadence drain when capture batch ≥ N** — if Step 6.5's classifier would drain N captures whose Priority is uncalibrated, review-problems should fire first to ensure release decisions are well-grounded.

**Recommended fix shape**: trigger-and-route at the orchestrator + manage-problem Step 0 surfaces.

- Trigger condition: count deferred-placeholder tickets via `grep -cl 'deferred — re-rate at next' docs/problems/open/*.md docs/problems/known-error/*.md`. When count ≥ 3 AND last-reviewed annotation older than 7 days, auto-dispatch /wr-itil:review-problems before the next iter.
- Route: in AFK orchestrator main turn, the trigger fires at Step 0a (after auto-migrate, before backlog scan). In manage-problem Step 0 (interactive), the trigger fires before backlog scan. In capture-problem Step 0, the trigger fires AFTER capture (the capture itself shouldn't be gated; the auto-fire is for the NEXT user-action).
- Authorisation: per ADR-013 Rule 5 + ADR-044 framework-resolution boundary — review-problems is policy-authorised silent proceed when accumulated-placeholder threshold met. Same shape as Step 0a auto-migrate (P170 RFC-002 T5a precedent).

## Symptoms

(deferred to investigation)

**Evidence (2026-05-24, work-problems session)**: the deferred-placeholder count reached **83** (`grep -rl 'deferred — re-rate at next' docs/problems/open/ docs/problems/known-error/`). At work-problems loop end the user was asked how to handle the accumulated bulk re-rate and directed: **apply the re-rate in small batches** (preserving the incremental git-visible cadence; auto-decisions have drifted poor) **AND capture a problem ticket for getting into this state** — that meta-ticket is THIS ticket (P271). The ~76→83 accumulation is the concrete witness of the exact gap P271 describes: review-problems never auto-fired, so 83 placeholders piled up across many sessions. The user's "small batches" cadence directive REFINES P271's recommended fix shape — the auto-fire trigger should re-rate incrementally (a bounded batch per fire), NOT bulk-re-rate all 83 at once. Add that constraint to the fix design.

Initial observations:
- 5 pre-existing entries in `.afk-run-state/outstanding-questions.jsonl` queued from session 7 + 3 from session 8 iter 2 = 8 total queued at this point in session 8.
- 8 capture-problem tickets created in last 2 sessions (P252/P264/P266/P267/P268/P269/P270/P271) all carrying `(deferred — re-rate at next /wr-itil:review-problems)` placeholders.
- The user invoked review-problems 0 times across both sessions; the agent invoked it 0 times.
- Top WSJF rankings in README.md may be stale by N% (the 8 deferred-placeholder captures are interleaved at WSJF=9.0/6.0/3.0/1.0 based on framework defaults; real WSJF after review may move them up or down significantly).

## Workaround

User manually invokes `/wr-itil:review-problems` periodically. Friction: user has to know when to invoke (no signal surface), walk through the heavyweight review, then return to whatever they were doing. The signal "deferred placeholders accumulated" is currently invisible to the user.

## Impact Assessment

- **Who is affected**: (deferred to investigation) — likely both maintainers (deferred-placeholder accumulation invisible) and AFK orchestrator (iters dispatch against potentially-stale WSJF rankings).
- **Frequency**: (deferred to investigation) — every session that creates ≥ 3 captures without invoking review-problems.
- **Severity**: (deferred to investigation) — initial: moderate. Compounds with capture-problem usage growth.
- **Analytics**: (deferred to investigation) — count of `(deferred — re-rate at next /wr-itil:review-problems)` substrings in `docs/problems/open/*.md` + `docs/problems/known-error/*.md`.

## Root Cause Analysis

review-problems was designed as user-invoked; no auto-trigger surface exists. The deferred-placeholder pattern presupposes a NEXT review invocation that never happens autonomously. Existing trigger surfaces in work-problems (Step 0a auto-migrate per P170, Step 0b inbound-discovery staleness per ADR-062) demonstrate the precedent: a helper-in-lib + run-wrapper + bin-shim + behavioural bats fixture, with AFK auto-dispatch via `claude -p` subprocess + interactive advisory shape per the surface.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems (meta-recursive ✓)
- [x] Investigate root cause — review-problems was designed as user-invoked; no auto-trigger surface exists. The deferred-placeholder pattern presupposes a NEXT review invocation that never happens autonomously.
- [x] Survey existing trigger surfaces — work-problems Step 0a (auto-migrate) + Step 0b (inbound-cache staleness) are the precedent shape; mirror at Step 0c.
- [x] Sibling P187 (orchestrator preflight unblock) composes — Step 0c addresses the broader umbrella P271 names; P187's specific surface is a special case of Step 0c's two-axis trigger.
- [ ] Sibling P110 (risk register has no passive trigger) — analogous pattern at risk-register surface; document the pattern at meta level. **Deferred** to a sibling Investigation Task; P271's fix shape is generalisable but P110's scope is its own ticket.
- [x] Create reproduction test (bats fixture) — `packages/itil/skills/work-problems/test/work-problems-step-0c-deferred-placeholder-staleness-behavioural.bats` covers 12 cases (5-outcome enum + dual-tolerant glob + defensive fallbacks + exclusion of closed/verifying tickets).

### Bounded-batch refinement (future work)

The user direction on the 2026-05-24 incident ("apply the re-rate in small batches") refines the auto-fire trigger toward incremental re-rate (bounded batch per fire), NOT bulk-re-rate all N placeholders at once. `/wr-itil:review-problems` currently processes all open + known-error tickets in one pass (no explicit batch-size cap). The P271 fix lands the **trigger** as scoped by the ticket Effort line; the bounded-batch refinement (cap N per fire; resume on next dispatch) is an orthogonal enhancement to review-problems itself and warrants its own ticket. Architect Condition 5 + JTBD Note 2 flag this as follow-on.

## Fix Strategy

**Mirror the Step 0b inbound-discovery-staleness precedent across three SKILL surfaces** (architect verdict: APPROVED-WITH-CONDITIONS — no new ADR required; composition of ADR-013 Rule 5 + ADR-044 cat 4 + ADR-062 Step 0b precedent is sufficient):

1. **Helper at `packages/itil/lib/check-deferred-placeholder-staleness.sh`** — exports `should_promote_review_problems_dispatch <repo-root>`. Two-axis AND trigger: count of deferred-placeholder tickets ≥ 3 AND `docs/problems/README.md` "Last reviewed" line-3 age > 7 days. Returns one of five outcomes:
   - `no-deferred-placeholders` — count is 0; silent-pass.
   - `below-threshold count=<N> threshold=3` — count > 0 but < 3; silent-pass.
   - `no-readme count=<N>` — count ≥ 3 + README absent OR malformed; dispatch trigger.
   - `fresh-readme count=<N> age=<X>s threshold=<Y>s` — count ≥ 3 + README age ≤ 7 days; silent-pass.
   - `stale-readme count=<N> age=<X>s threshold=<Y>s` — both axes met; THE dispatch trigger.

   Dual-tolerant glob per ADR-031 RFC-002 migration window — covers BOTH flat `docs/problems/<NNN>-*.<state>.md` AND per-state `docs/problems/<state>/<NNN>-*.md`. Closed and verifying tickets EXCLUDED per ADR-022.

2. **Wrapper at `packages/itil/scripts/run-check-deferred-placeholder-staleness.sh`** — adopter-safe wrapper sourcing the lib relative to the script (P317/RFC-009).

3. **Shim at `packages/itil/bin/wr-itil-check-deferred-placeholder-staleness`** — regenerated by `scripts/sync-shim-wrappers.sh` from the canonical template per ADR-049 + ADR-080.

4. **Wire-in surface 1 — `/wr-itil:work-problems` SKILL.md Step 0c** (AFK auto-dispatch): immediately after Step 0b. On `no-readme` / `stale-readme`, dispatch `/wr-itil:review-problems` via the standard `claude -p` subprocess wrapper (reuses the Step 5 dispatch shape verbatim). Silent-pass on the other three outcomes. ADR-013 Rule 5 + ADR-044 cat 4 — policy-authorised silent proceed (work-problems is AFK by construction).

5. **Wire-in surface 2 — `/wr-itil:manage-problem` SKILL.md Step 0.5** (interactive advisory): after Step 0 reconcile. On `no-readme` / `stale-readme`, emit an advisory note + actionable directive (NOT auto-dispatch — interactive surface; ADR-013 Rule 1; auto-dispatch would break JTBD-001's 60-second flow contract). Silent-pass on other outcomes.

6. **Wire-in surface 3 — `/wr-itil:capture-problem` SKILL.md Step 7** (conditional trailing pointer): refine the existing trailing pointer. Default (low-priority) shape on `no-deferred-placeholders` / `below-threshold` / `fresh-readme`. **Highlighted (actionable)** shape on `no-readme` / `stale-readme` — names the placeholder count + age + escalates the signal. No auto-dispatch (capture is intentionally lightweight per ADR-032 P155).

7. **Behavioural bats fixture** at `packages/itil/skills/work-problems/test/work-problems-step-0c-deferred-placeholder-staleness-behavioural.bats` — 12 cases covering the 5-outcome enum + dual-tolerant glob (per-state + flat + mixed) + defensive fallbacks (malformed README line 3) + exclusion of closed/verifying tickets.

8. **Contract-source markers** at all four surfaces (helper + 3 SKILLs) — `<!-- DEFERRED-PLACEHOLDER-STALENESS-CONTRACT-SOURCE: packages/itil/lib/check-deferred-placeholder-staleness.sh -->` so future threshold edits (3 → N, 7 days → M days) update all four surfaces in the same commit.

9. **Changeset** per P141 multi-commit slice discipline.

**Release vehicle**: `.changeset/wr-itil-p271-auto-fire-review-problems.md`

**Composition with sibling tickets**:
- P187 — orchestrator preflight unblock — Step 0c closes P187's specific surface as the umbrella case.
- P110 — risk-register passive trigger — analogous pattern, different artefact; deferred to sibling ticket.
- P246 / P247 — evidence-based-not-time-based deferrals — Step 0c uses TWO axes (count + age) where age alone would be the calendar-defer anti-pattern; the AND-rule is the evidence guard.
- P190 — framework-derive surface — Step 0c IS a framework-derive (the helper resolves the dispatch decision; no `AskUserQuestion`).

**Release vehicle**: .changeset/wr-itil-p271-auto-fire-review-problems.md

## Fix Released

Shipped 2026-06-04 (`@windyroad/itil` patch pending — P143-class fold-fix per ADR-022 amendment; Open → Verification Pending in single commit because root cause + Fix Strategy + workaround were documented inline).

**Files shipped:**
- `packages/itil/lib/check-deferred-placeholder-staleness.sh` — new helper exporting `should_promote_review_problems_dispatch` (5-outcome enum: `no-deferred-placeholders` / `below-threshold` / `no-readme` / `fresh-readme` / `stale-readme`).
- `packages/itil/scripts/run-check-deferred-placeholder-staleness.sh` — adopter-safe wrapper.
- `packages/itil/bin/wr-itil-check-deferred-placeholder-staleness` — ADR-049/ADR-080 PATH shim (regenerated from canonical template).
- `packages/itil/skills/work-problems/SKILL.md` — new Step 0c between Step 0b (inbound-discovery) and Step 1 (backlog scan). AFK auto-dispatch via `claude -p` subprocess on `no-readme` / `stale-readme`.
- `packages/itil/skills/manage-problem/SKILL.md` — new Step 0.5 between Step 0 (reconcile) and Step 1 (parse request). Interactive advisory shape (NOT auto-dispatch per ADR-013 Rule 1 + JTBD-001 60-second flow contract).
- `packages/itil/skills/capture-problem/SKILL.md` — Step 7 trailing pointer refined with conditional highlight on `no-readme` / `stale-readme` (escalates the signal without forcing auto-dispatch — ADR-032 lightweight contract preserved).
- `packages/itil/skills/work-problems/test/work-problems-step-0c-deferred-placeholder-staleness-behavioural.bats` — 12 behavioural test cases covering the 5-outcome enum + dual-tolerant glob (per-state + flat + mixed RFC-002 migration shapes) + defensive fallbacks (malformed README line 3) + exclusion of closed/verifying tickets.

**Contract-source markers** (`<!-- DEFERRED-PLACEHOLDER-STALENESS-CONTRACT-SOURCE -->`) placed at the helper + all three SKILL surfaces so future threshold edits (3 placeholders, 7 days) update all four surfaces in the same commit.

**Verification path**: on next interactive session that captures ≥3 deferred-placeholder tickets, the manage-problem Step 0.5 advisory should fire; if the README is also >7 days stale, the advisory escalates with the actionable directive. The work-problems orchestrator should pre-flight `/wr-itil:review-problems` at Step 0c when both axes hit threshold; bats fixtures 8/8 green confirm the 5-outcome enum + dual-tolerance + exclusions.

**Recovery**: revert the fix commit if the trigger over-fires in adopter trees; the threshold constants (`count_threshold=3`, `age_threshold_seconds=604800`) can be tuned in the helper if the AND-rule needs calibration.

Awaiting user verification.

## Dependencies

- **Blocks**: any reliable WSJF-driven prioritisation when captures accumulate — orchestrator may dispatch iters against stale rankings.
- **Blocked by**: (none observed yet)
- **Composes with**:
  - P187 — orchestrator detects review-problems unblock, halts with "recommended next step" instead of auto-dispatching (specific surface of the same class P271 captures)
  - P110 — risk-register has no passive trigger (analogous pattern at different artefact)
  - P246 — agent waits on calendar trigger for held-cohort graduation (analogous defer-anti-pattern; user direction: "evidence-based not time-based")
  - P247 — run-retro Step 3 Tier 3 Branch B "leave-as-is" encodes fictional defer (analogous; same calendar-defer class)
  - P190 — agent designs schemas with user-asked classification fields when framework should derive silently (deeper generalisation — review-problems auto-fire is the framework-derive shape)
  - ADR-013 Rule 5 — policy-authorised silent proceed (the trigger-and-route IS Rule 5 behaviour)
  - ADR-044 — framework-resolution boundary (when to auto-fire IS framework-resolved, not user-asked)
  - JTBD-006 — Progress the Backlog While I'm Away (auto-fire ensures the backlog rankings stay live during AFK loops)

## Related

(captured via /wr-itil:capture-problem mid-loop — orchestrator main turn while iter 3 P268 was running in background subprocess; user-initiated capture per CLAUDE.md MANDATORY capture-on-correction rule; description shape matches user explicit direction "I'm expecting it to run automatically when needed" — class-of-behaviour signal for framework auto-trigger)

- P187 — sibling at orchestrator preflight surface
- P110, P246, P247, P190 — sibling pattern cluster (defer / auto-fire / framework-resolution)
- ADR-013, ADR-044 — authorisation framework
- JTBD-006 — AFK persona constraint
- `packages/itil/skills/review-problems/SKILL.md` — target skill that needs an auto-fire trigger surface
- `packages/itil/skills/work-problems/SKILL.md` Step 0/0a/0b — candidate trigger sites for the orchestrator surface
- `packages/itil/skills/manage-problem/SKILL.md` Step 0 — candidate trigger site for interactive surface
- `packages/itil/skills/capture-problem/SKILL.md` Step 7 trailing-pointer — current placeholder mechanism (the "Run /wr-itil:review-problems next" trailing pointer signals stale README but does NOT auto-dispatch; P271 closes the gap between signal and action)
