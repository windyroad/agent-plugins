# Problem 303: Architect gate deadlocks any multi-decision-file change — verdict-grep + drift-relock + disk-state-review compound into an unbreakable lock

**Status**: Verification Pending
**Reported**: 2026-05-25
**Priority**: 9 (Med High) — Impact: 3 (Moderate) × Likelihood: 3 (Likely)
**Effort**: M
**WSJF**: 9/2 = **4.5** (Verification Pending multiplier 0.0; held for verification only)

## Fix Released

**Released**: 2026-06-06 — drift-relock facet (facet 3) closed.

**Direction**: User ratified the substance-aware drift + atomic verdict-write design on 2026-06-06 during the AFK iteration that produced this fix. Architect (PASS) + JTBD (PASS) + WIP-risk (CONTINUE, 4/25 within appetite) confirmed the same day.

**Fix**:
- ADR-009 amendment 2026-06-06 ("Substance-aware drift + atomic verdict-write") records the ratified contract.
- ADR-028 amendment 2026-06-06 records the external-comms cross-amendment.
- `packages/<architect|jtbd|voice-tone|style-guide|risk-scorer>/hooks/lib/gate-helpers.sh` gains `_substance_hash_path` (normalises CRLF / trailing whitespace / trailing newlines before hashing) + `_atomic_mark_with_hash` (mktemp + atomic rename pair). All five lib copies kept byte-identical.
- `packages/<jtbd|voice-tone|style-guide>/hooks/lib/review-gate.sh` and `packages/architect/hooks/lib/architect-gate.sh` route the drift check through the substance hash; `store_review_hash` and `architect-mark-reviewed.sh` route the verdict-write through the atomic helper.
- `packages/architect/hooks/architect-refresh-hash.sh` uses the substance hash + atomic rename for the in-session hash refresh.
- Behavioural bats at `packages/<architect|jtbd|voice-tone|style-guide>/hooks/test/substance-aware-drift.bats` cover (a) trivial-edit-no-refire, (b) substantive-edit-refires, (c) atomic-write persists, (d) conservative fallback (25 new bats, all green; existing 259 hook bats remain green).

**Scope clarification** (per ADR-009 2026-06-06 amendment Out-of-scope list): this release closes the drift-relock facet specifically. The verdict-grep fragility (facet 1) is tracked by P181/P217. The disk-state-review deadlock (facet 2) remains tracked separately. Drift-relock alone resolves P303's primary failure mode — multi-decision-file changes can now land through the gate's happy path because trivial whitespace edits between decision-file writes no longer invalidate the marker.

**Verification**:
- A multi-ADR change lands without manual `/tmp/architect-reviewed-${SID}` surgery.
- Behavioural bats exercises the failure-mode cases pre-release.
- No `BYPASS_RISK_GATE=1` use required after a legitimate architect PASS for multi-ADR work.

## Description

Recording ADR-069 (P294, supersede ADR-051) required editing five `docs/decisions/` files (create 069; flip 051 to superseded; re-home citations in 063, 060, 053) plus the gated hook/detector/bats/SKILL files. The architect gate (`packages/architect/hooks/`) made this **impossible to land through the gate's own happy path**. Three known facets compounded:

1. **Verdict-grep treats thorough review as FAIL (P181 / P217).** `architect-mark-reviewed.sh` writes the unlock marker only when the agent output contains the literal `Architecture Review: PASS` and does NOT contain `ISSUES FOUND`. A thorough architect review that *approves the design* but enumerates addressable conditions (each prefixed "ISSUES FOUND") is parsed as FAIL, so the marker is never written — even though the review approved the change. Four successive reviews approved the ADR-069 design; none produced an unlock.

2. **Disk-state-review deadlock (new facet).** Once the proposed approach is approved, the architect agent reviews *disk state* to confirm the work landed. But the work cannot land while the gate is locked, and the gate stays locked until a clean PASS — which requires the work to be on disk. The agent correctly reports "the work is not on disk yet" → `ISSUES FOUND` → no marker. Circular.

3. **Drift-relock on every decision edit (P215 / P216 / P226).** `check_architect_gate` stores the `docs/decisions/` content hash at review time and removes the marker on the next gated edit when the hash has changed. So even a single clean PASS unlocks exactly **one** decision-file write before re-locking — a five-decision-file change would need five clean PASS reviews, which facet 1+2 make unobtainable.

Net: there is no gate-happy path for a multi-decision-file change. The change lands only via **manual gate-misfire recovery** (assert `/tmp/architect-reviewed-${SID}` and remove the `.hash` file so `check_architect_gate` takes its "no hash = old marker format, allow" branch), which is what P294 did under explicit user authorisation.

## Symptoms

- `Write`/`Edit` to `docs/decisions/*.md` denied with "Cannot edit ... without architecture review" despite the architect agent having reviewed and approved the change in-session (4×).
- Each `docs/decisions/` write that *does* get through re-locks the gate for the next edit.
- Architect re-reviews after approval report `ISSUES FOUND` solely because the approved work is not yet on disk.

## Workaround

Manual gate-misfire recovery (ADR-048 lineage → ADR-050 runtime-SID discovery): resolve the session SID from `/tmp/itil-runtime-sid-${USER}-${proj_hash}.current` (via `runtime_sid_path()`), `touch /tmp/architect-reviewed-${SID}`, and `rm -f /tmp/architect-reviewed-${SID}.hash`. With the hash file absent, `architect-refresh-hash.sh` is a no-op (it only refreshes an existing hash file) and `check_architect_gate` allows every subsequent edit. Requires explicit user authorisation — it asserts a true fact (these changes WERE architect-reviewed) but defeats the gate's drift-detection automation for the session.

## Root Cause Analysis

### Investigation Tasks

- [ ] Make the three facets compose. The cleanest shape: a per-session "architect-reviewed-this-change" marker that survives `docs/decisions/` drift WITHIN the same review session (the drift-detection is meant to catch *unreviewed cross-session* edits, not the multi-file change the review just approved). Options: (a) refresh the stored hash on each allowed `docs/decisions/` write while the marker is live (extends `architect-refresh-hash.sh` to create-if-live, not only refresh-if-exists); (b) a "review covers the proposed change-set" mode keyed to the reviewed file list rather than a whole-directory hash; (c) verdict parsing that distinguishes "approved with addressable conditions" from "blocking ISSUES FOUND" (folds in P181/P217).
- [ ] Resolve the disk-state-review deadlock: the architect agent should be able to render `PASS` on a *proposed plan* (pre-edit) without conditioning the verdict on disk state, OR the gate should accept a plan-level approval marker distinct from the post-edit drift check.
- [ ] Provide a first-class recovery affordance (P215 asks for this) so manual `/tmp` surgery is not the only escape.

## Dependencies

- **Composes with**: [[181]] (verdict-grep fragility), [[215]] (drift-detection rm marker without recovery), [[216]] (refresh-hash only on docs/decisions writes), [[217]] (strict-verdict-string under-counts affirmative verdicts), [[226]] (TTL forces re-review on multi-file work). P303 is the composite — the three facets together produce a hard deadlock that no single sibling captures.
- **Surfaced by**: P294 / ADR-069 supersession (first multi-ADR change to hit the full compound).

## Related

(captured 2026-05-25 during the P294/ADR-069 supersession, under user authorisation to land via gate-misfire recovery + capture this defect)

- **ADR-048** (`docs/decisions/048-gate-misfire-recovery-procedure.superseded.md`) — original recovery procedure; superseded by **ADR-050** which provides the reliable runtime-SID the recovery now uses.
- **ADR-066** — the human-oversight drain that surfaced P294; ADR-069 is born-confirmed, so the supersession itself needed no drain — the deadlock was purely the edit-gate.
