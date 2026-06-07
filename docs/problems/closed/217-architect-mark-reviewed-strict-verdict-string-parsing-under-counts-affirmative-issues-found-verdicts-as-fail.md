# Problem 217: architect-mark-reviewed.sh strict-verdict-string parsing under-counts affirmative ISSUES FOUND verdicts as FAIL

**Status**: Closed (Superseded)
**Reported**: 2026-05-15
**Closed**: 2026-06-08 (work-problems AFK iter — premise superseded by P181 + P353; residual "affirmative ISSUES FOUND" claim contradicts agent.md verdict doctrine)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The `architect-mark-reviewed.sh` PostToolUse hook only creates the gate-release marker when the architect agent's output contains the literal string `Architecture Review: PASS`. When the architect's verdict is "ISSUES FOUND" but the bottom-line text is affirmative (e.g., "the proposed change is acceptable with the noted issues addressed inline"), the marker is not created and the gate denies the subsequent edit.

## Resolution

**Closed as Superseded 2026-06-08.** The substantive defect classes the ticket described are closed by P181 (anchored verdict-grep) and P353 (atomic verdict-write + substance-aware hash). The residual "affirmative-bottom-line ISSUES FOUND should pass" claim contradicts the agent.md verdict doctrine and the briefing's load-bearing rule, so it is not a defect.

**Substantive fixes already shipped**:

1. **P181 — anchored verdict-grep** (released 2026-06-01 in `@windyroad/architect@0.13.0`, fix commit `a1939e7`). The original P217 symptom — "only the literal string `Architecture Review: PASS` is recognised; everything else falls to default FAIL" — was the same fragility P181 captured. The current hook at `packages/architect/hooks/architect-mark-reviewed.sh` lines 38-42 matches the **canonical heading shape** anchored at column 0 (optional `> ` blockquote prefix tolerated):

   - `^[[:space:]]*>?[[:space:]]*\*\*Architecture Review: PASS\*\*` → `VERDICT=PASS` (marker drops)
   - `^[[:space:]]*>?[[:space:]]*\*\*Architecture Review: ISSUES FOUND\*\*` → `VERDICT=FAIL` (no marker, by design)
   - any other shape (e.g. NEEDS DIRECTION heading, body prose with no canonical heading) → empty `VERDICT` → fallback marker-write to avoid lockout

   The 9 behavioural tests in `packages/architect/hooks/test/architect-mark-reviewed-verdict-grep.bats` pin this contract — including the P181-class case where body prose mentions "ISSUES FOUND" inline without it being the canonical heading (marker drops correctly).

2. **P353 — atomic verdict-write + substance-aware hash** (released 2026-06-06, fix commit `e197424`, ADR-009 amendment 2026-06-06). Closed the "marker doesn't land after PASS" failure mode that previously forced `BYPASS_RISK_GATE=1` after a legitimate PASS. The marker + hash file now write atomically (mktemp + rename pair) via `_atomic_mark_with_hash`; either both land or neither does.

**Why the residual "affirmative ISSUES FOUND" claim is not a defect**:

The P217 ticket's remaining premise — that a `**Architecture Review: ISSUES FOUND**` heading with affirmative body prose ("acceptable with the noted issues addressed inline") should drop the marker — **contradicts the agent.md verdict doctrine and the briefing's load-bearing rule**:

1. `packages/architect/agents/agent.md` "How to Report" (lines 116-148) names exactly three verdict shapes: **PASS**, **ISSUES FOUND**, **NEEDS DIRECTION**. ISSUES FOUND carries per-issue **Action** lines describing what should happen ("document new decision, update existing, etc."). The contract is intentionally three-valued; there is no hypothetical fourth "ISSUES-FOUND-AFFIRMATIVE" shape.

2. If the architect's substantive judgement is "fine to land", the contract requires emitting **PASS** (optionally with non-blocking informational notes) — not ISSUES FOUND with affirmative prose. The P181 anchored-heading fix preserves this: a `**Architecture Review: PASS**` heading whose body narratively mentions ISSUES FOUND correctly narrows to PASS.

3. `docs/briefing/README.md` highest-value entry: *"If the architect reports ISSUES FOUND, resolve the issues and re-run the architect before editing. Do NOT proceed with edits while issues are outstanding."* Treating affirmative-bottom-line ISSUES FOUND as PASS would erode this rule — the gate's safety guarantee would degrade to "the gate is bypassable by adding affirmative prose to an ISSUES FOUND verdict", which the briefing explicitly disallows.

4. The "Investigation Tasks" claim that "PASS-WITH-ISSUES, PASS-WITH-NOTES, ISSUES-FOUND-AFFIRMATIVE all create marker" mixed two distinct things: (a) PASS-with-inline-issues-prose (handled correctly by P181 anchored heading — PASS heading wins), (b) ISSUES-FOUND-with-affirmative-prose (a non-existent verdict shape per the contract).

**Adjacent hardening already shipped (independent of this ticket)**:

- **P181** (`a1939e7`, `@windyroad/architect@0.13.0`, 2026-06-01) anchored the verdict-grep to the canonical heading shape; replaced the literal-substring grep that originally surfaced this ticket.
- **P353 + P303** (`e197424`, 2026-06-06 ADR-009 amendment) introduced `_atomic_mark_with_hash` (atomic verdict-write) and `_substance_hash_path` (substance-aware drift hash), closing the hash-marker brittleness class.

Neither of these implemented the "affirmative ISSUES FOUND should pass" premise because that premise contradicts the contract.

**No code change**. Closed without a release.

**Mirror precedent**: P216 closed 2026-06-08 (`cc1cedf`) as Superseded with the same KE→Closed direct path per ADR-079 lifecycle extension when ticket premise is invalidated by ratified design.

**Upstream**: https://github.com/windyroad/agent-plugins/issues/78 should be closed with this resolution body (the upstream report mirrors the local premise).

**Reversible**: `/wr-itil:transition-problem 217 known-error` reopens if a new defect class is found that the resolution misses.

## Workaround

(Historical — no longer applicable.) Manually re-prompt the architect agent to emit the literal `Architecture Review: PASS` string when the bottom-line is affirmative.

## Impact Assessment

- **Severity**: Moderate — false-deny on affirmative ISSUES FOUND verdicts; recoverable.

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems (resolved at closure; no further re-rate needed)
- [x] Parse verdict semantics: PASS, PASS-WITH-ISSUES, PASS-WITH-NOTES, ISSUES-FOUND-AFFIRMATIVE all create marker. FAIL / ISSUES-FOUND-BLOCKING do not. **Resolved**: the three-shape contract (PASS / ISSUES FOUND / NEEDS DIRECTION) is the correct semantics; PASS-with-non-blocking-notes is the right shape for "issues are advisory only" (P181 anchored heading preserves this); ISSUES-FOUND-AFFIRMATIVE is not a contract shape and would erode the gate.
- [x] Behavioural test covering all verdict shapes. **Resolved**: `packages/architect/hooks/test/architect-mark-reviewed-verdict-grep.bats` pins canonical PASS, canonical ISSUES FOUND, blockquote variants, NEEDS DIRECTION fallthrough, P181-class inline-prose false-positive, lowercase prose ignored (9 tests).

## Related

- **P181** (Verifying) — anchored verdict-grep fix at `a1939e7` released `@windyroad/architect@0.13.0` on 2026-06-01. Closes the substring-anywhere false-positive class.
- **P353** (Verification Pending) — atomic verdict-write + substance-aware hash at `e197424` released 2026-06-06 per ADR-009 amendment. Closes the marker-doesn't-land-after-PASS class.
- **P216** (Closed 2026-06-08 at `cc1cedf`) — precedent KE→Closed-as-Superseded shape when ticket premise is invalidated by ratified design.
- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/78
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/architect.
- **ADR-009** (Edit-gate hook contract) — load-bearing verdict-marker contract; ratified.
- **ADR-022** (Problem lifecycle) — KE→Closed direct path used here; ratified.
- **ADR-026** (Agent output grounding) — cite-and-persist legs satisfied by this closure body.
- `packages/architect/agents/agent.md` lines 116-148 — three-shape verdict doctrine that grounds the closure.
