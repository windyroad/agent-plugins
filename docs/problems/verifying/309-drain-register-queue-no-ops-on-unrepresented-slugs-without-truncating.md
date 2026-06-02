# Problem 309: `wr-risk-scorer-drain-register-queue` no-ops on queued slugs that have no register file — creates 0, appends 0, and does NOT truncate the queue

**Status**: Verifying
**Reported**: 2026-05-26
**Verifying since**: 2026-06-03 (fold-fixed by P171, regression coverage added)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

`/wr-itil:work-problems` Step 6.4 invokes `wr-risk-scorer-drain-register-queue` (→ `packages/risk-scorer/scripts/drain-register-queue.sh`) to materialise `.afk-run-state/risk-register-queue.jsonl` hints into `docs/risks/R<NNN>-<slug>.active.md` register entries. Per the Step 6.4 contract, when `docs/risks/` is scaffolded (it is — 25 files present) the script should dedupe by `risk_slug` and create one register file per unique unrepresented slug (or append Evidence Log lines to slug-matched existing files).

**Observed 2026-05-26**: the queue held **3 entries** (slugs `external-adopter-name-in-public-repo-ticket-prose`, `new-sessionstart-hook-first-landing-no-dogfood-window`, `new-sessionstart-hook-shipped-without-dogfood-window`, dated 2026-05-24/25). The drain returned:

```
entries_drained=0
new_risks_created=0
evidence_appended=0
next_action=none
```

Independent check: **none of the 3 slugs has a register file** under `docs/risks/` (`grep -rl <slug> docs/risks/` → no match for all three). So the drain should have created 3 new entries — but it created 0, appended 0, AND did not truncate the queue. The 3 entries persist and will be re-evaluated (and re-no-op'd) on every subsequent drain, accumulating indefinitely off-ledger.

This is the inverse of the Step 6.4 intent — the queue exists so above-appetite risk hints reach the register; a silent no-op on unrepresented slugs means those risks never get scaffolded and the queue never clears.

Candidate root-cause directions (to investigate):
1. The script's "skip if `docs/risks/` not scaffolded" guard mis-fires (false-negative on the scaffold-detection).
2. The slug-dedup logic treats the 3 slugs as already-represented (false-positive match against some non-`docs/risks/` state).
3. The JSONL parse silently drops entries (schema drift between the queue-writer hook and the drain reader — e.g. a field renamed).
4. The entries' `report_path` references (`.risk-reports/2026-05-2x-...md`) are missing/unreadable and the drain fail-skips them silently.

## Symptoms

(deferred to investigation)

## Workaround

None applied — the no-op is non-blocking for the AFK loop (Step 6.4 failure is non-halting). The 3 entries remain queued; manual `/wr-risk-scorer:create-risk` or `bootstrap-catalog` can scaffold them if needed.

## Impact Assessment

- **Who is affected**: maintainers relying on Step 6.4 to auto-populate the risk register from AFK above-appetite events (ADR-056 Phase 2b).
- **Frequency**: every Step 6.4 drain with these (or similar unrepresented) queued entries — structurally recurring until fixed.
- **Severity**: risk hints never reach `docs/risks/` (ISO 31000 register currency gap); the queue accumulates undrained off-ledger entries. Non-blocking but defeats the register-population contract.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Fold-fixed by P171** (commit 9e91508, 2026-05-31). The 0/0/0 no-op was caused by candidate #1: the script's `[ ! -f "$TEMPLATE_FILE" ]` guard mis-fired against the canonical post-wipe `docs/risks/` state (TEMPLATE.md was removed by the 2026-05-04 wipe direction in commit 8edaf7b, but the drain script kept gating on its presence). P171 removed the vestigial TEMPLATE.md gate.

Reproduction on 2026-06-03 against the live 8-entry queue returned `entries_drained=8 / new_risks_created=7 / evidence_appended=1 / next_action=commit-staged` — the bug class is gone.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — deferred, ticket closing without re-rate per fold-fix scope
- [x] Reproduce against current queue — confirmed working (8/7/1/commit-staged, 2026-06-03)
- [x] Determine which candidate cause holds — candidate #1 (scaffold-guard mis-fire on canonical post-wipe state), fold-fixed by P171
- [x] Decide truncation semantics — resolved by P171: queue truncated on any successful drain (`entries_drained > 0`)
- [x] Create reproduction test — added P309-tagged behavioural test to `packages/risk-scorer/scripts/test/drain-register-queue.bats` (3-entry queue, 3 unrepresented slugs, asserts 3 register files + truncation + `next_action=commit-staged`)

### Verification

- 18/18 `drain-register-queue.bats` GREEN (including new P309 test + the existing P171 test).
- Reproduction against live queue post-fix returned 8/7/1/commit-staged with 7 new register files materialised in-session (reverted from worktree pending the ticket commit; the queue itself was truncated by the drain — see Notes).

**Notes**: the live 8-entry queue was inadvertently truncated during the 2026-06-03 reproduction step (the drain script's `: > "$QUEUE_FILE"` line fires on every successful drain). The 7 newly-minted register files were reverted via `git restore --staged --worktree docs/risks/` but the queue truncation is non-reversible (queue is gitignored). The 8 hint reports remain in `.risk-reports/` and can be re-materialised by `/wr-risk-scorer:bootstrap-catalog` if needed; no information lost.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: ADR-056 Phase 2b (the drain contract this faults)

## Related

- **ADR-056** — risk-register queue + drain (Phase 2a writer hook, Phase 2b drain). The contract this violates.
- `packages/risk-scorer/scripts/drain-register-queue.sh` — the no-op'ing script.
- `/wr-itil:work-problems` Step 6.4 — the invocation surface where the no-op was observed.
- Captured via /wr-retrospective:run-retro Step 4b Stage 1 (pipeline-instability detection); 2026-05-26.
