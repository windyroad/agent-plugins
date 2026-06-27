# Problem 385: work-problems re-dispatches already-fixed tickets at full iter cost; add a cheap pre-dispatch relevance-close

**Status**: Verification Pending
**Reported**: 2026-06-26
**Priority**: 8 (Medium) — Impact: 2 x Likelihood: 4
**Origin**: inbound-reported (#284)
**Release vehicle**: .changeset/work-problems-pre-dispatch-relevance-gate.md

## Fix Released

Released in `@windyroad/itil` patch 2026-06-27 (release vehicle `.changeset/work-problems-pre-dispatch-relevance-gate.md`, shipped this `/wr-itil:work-problems` session alongside the work-problems eval cohort-coverage extension). The Step 3.6 pre-dispatch relevance gate is now in the published SKILL; its behaviour is covered GREEN by the work-problems promptfoo eval (12/12, P385 case). Transitioned K→V manually because the iter omitted the P330 release-vehicle seed (now backfilled above), so the post-release K→V enumerator skipped it (derive exit 2).

**Awaiting user verification** — confirm a real AFK work-problems run short-circuits an already-shipped selected ticket at Step 3.6 (cheap relevance-close) instead of paying a full iteration dispatch.
**Effort**: M
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

In an AFK `/wr-itil:work-problems` loop, a meaningful fraction of "open" tickets turn out to have been already fixed by later work but never transitioned (observed: 3 of 6 worked tickets in a single session). The orchestrator dispatches a full iteration subprocess per ticket (real time + cost) only to discover the fix already shipped, then transitions the ticket. The rediscovery is correct but expensive.

## Symptoms

- A work iter runs a full subprocess, finds the fix already shipped, and transitions the ticket — paying iter cost for a transition that a cheap check could have made.

## Workaround

None — the rediscovery is correct, just expensive.

## Impact Assessment

- **Who is affected**: anyone running AFK work-problems against a mature backlog.
- **Frequency**: proportional to the stale-but-open fraction of the backlog (observed ~50% in one session).
- **Severity**: wasted iteration time + token cost; no correctness impact.

## Root Cause Analysis

### Root Cause

work-problems selected a ticket (Step 3 / 3.5) and went straight to the Step 5 full `manage-problem` dispatch with no per-ticket relevance pre-check. On a mature backlog the selected ticket is often already-fixed-but-untransitioned, so the full iter only rediscovers the shipped fix and transitions it — paying ~$3-5 + 5-10 min for a conclusion a millisecond shell check already encodes. The existing relevance machinery (`wr-itil-evaluate-relevance` + review-problems Step 4.6, ADR-079) only ran backlog-wide via the Step 0c AND-trigger (count ≥ 3 AND README age > 7 d), so a single already-shipped selected ticket below that trigger slipped through to full dispatch.

### Fix Strategy (implemented)

Added **Step 3.6: Pre-dispatch relevance gate** to `work-problems/SKILL.md`, between Step 3.5 (JTBD predicate) and Step 4 (classify) — the same shift-left insertion point as Step 3.5. It runs `wr-itil-evaluate-relevance` on the **selected ticket only** and routes on its exit code:

- `0` clean `CLOSE-CANDIDATE` → dispatch ONE `/wr-itil:review-problems` relevance-close sweep (reuse Step 0c shape, AFK-by-construction silent-close per ADR-032), set a once-per-session sentinel, loop to Step 1. Sentinel-survivor → user-answerable skip (no re-sweep, no wasteful full dispatch).
- `0` `CLOSE-CANDIDATE-WITH-CAVEAT` → user-answerable skip + queued `outstanding_questions` (caveat short-tag verbatim, P350), loop to Step 3.
- `1`/`2`/`3` (KEEP / SKIP / error) → proceed to Step 4 normal dispatch (fail-soft).

No new script/shim — routing reuses the already-behaviourally-tested evaluator; a SKILL-prose grep would be a structural test (rejected per P081 / ADR-052). Architect APPROVED (subprocess-AFK-by-construction re-anchor + sentinel-survivor fix + P358 inheritance), JTBD PASS (JTBD-006), risk WIP 4/25 Low.

### Investigation Tasks

- [x] Run a cheap pre-dispatch relevance / already-shipped check BEFORE dispatching a work iteration
- [x] Reuse the `review-problems` Step 4.6 relevance-close evaluator (`wr-itil-evaluate-relevance`)
- [x] Transition or close stale tickets cheaply rather than rediscovering at full iter cost (clean CLOSE-CANDIDATE → review-problems sweep)
- [x] Composes with the existing Step 0c deferred-placeholder pre-flight (reuses its dispatch shape; sweep also fires Step 4.6 per ADR-079 composition)
- [x] Behavioural test: covered by the reused evaluator's `packages/itil/scripts/test/evaluate-relevance.bats` (CLOSE-CANDIDATE detection on a shipped-fix ticket); the exit→action routing is irreducible SKILL prose

## Dependencies

- **Blocks**: AFK work-problems cost efficiency on mature backlogs
- **Blocked by**: (none)
- **Composes with**: P344 (work-problems predicate-check cited JTBDs before dispatch — same pre-dispatch insertion point), P346/ADR-079 (Step 4.6 relevance-close evaluator — reused here)

## Related

- **Upstream**: windyroad/agent-plugins#284 — surfaced during an AFK work-problems session against a mature backlog; captured by the session-level retro.
- `packages/itil/skills/work-problems/SKILL.md` — Step 5 dispatch / Step 0c pre-flight is the insertion point.
- `packages/itil/scripts/evaluate-relevance.sh` (`wr-itil-evaluate-relevance` shim) — the reusable evaluator.
- **ADR-079** — Step 4.6 relevance-close evidence shapes.
