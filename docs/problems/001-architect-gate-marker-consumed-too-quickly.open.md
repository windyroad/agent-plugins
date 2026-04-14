# Problem 001: Architect Gate Marker Consumed Too Quickly

**Status**: Open
**Reported**: 2026-04-14
**Priority**: 8 (Medium) — Impact: Minor (2) x Likelihood: Likely (4)

## Description

The architect gate marker gets consumed or expires between tool calls within a single prompt turn, requiring the architect agent to be re-invoked multiple times for what is logically a single review cycle. This adds latency and token cost to every session that involves multiple file edits.

## Symptoms

- After one architect review, the first Edit/Write succeeds but subsequent edits in the same turn are blocked with "BLOCKED: Cannot edit ... without architecture review"
- The developer must re-invoke the architect agent before each additional edit, even though the architectural context hasn't changed
- Sessions with 4+ file edits require 2-3 architect agent invocations per prompt turn

## Workaround

Batch all Write/Edit calls together after a single architect review. If the marker expires mid-turn, re-invoke the architect agent with a brief prompt referencing the prior review.

## Impact Assessment

- **Who is affected**: All developers using the architect plugin
- **Frequency**: Every session with multiple file edits
- **Severity**: Medium — adds ~30-60s and token cost per re-invocation
- **Analytics**: N/A

## Root Cause Analysis

### Preliminary Hypothesis

The marker file at `/tmp/architect-reviewed-${SESSION_ID}` is likely being consumed (deleted) by the PostToolUse hook after the first successful edit, or the TTL (default 1800s) is not being refreshed correctly between rapid sequential edits. The `check_architect_gate` function in `packages/architect/hooks/lib/architect-gate.sh` does `touch "$MARKER"` to slide the TTL window, but the drift detection (`find docs/decisions ... | _hashcmd`) may be invalidating the marker if any decision file was written as part of the same batch.

### Investigation Tasks

- [ ] Investigate whether the PostToolUse hook (`architect-refresh-hash.sh`) is deleting the marker
- [ ] Check if drift detection triggers on decision files written in the same session
- [ ] Determine if the marker is single-use by design or if this is a bug
- [ ] Create reproduction test
- [ ] Create INVEST story for permanent fix

## Related

- `packages/architect/hooks/lib/architect-gate.sh` — gate logic with TTL and drift detection
- `packages/architect/hooks/architect-mark-reviewed.sh` — PostToolUse marker creation
- `packages/architect/hooks/architect-refresh-hash.sh` — PostToolUse hash refresh
