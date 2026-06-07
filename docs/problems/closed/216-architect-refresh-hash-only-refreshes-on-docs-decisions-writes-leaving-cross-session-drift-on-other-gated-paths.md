# Problem 216: architect-refresh-hash.sh only refreshes hash on docs/decisions/* writes, leaving cross-session drift on other gated paths

**Status**: Closed (Superseded)
**Reported**: 2026-05-15
**Closed**: 2026-06-08 (work-problems AFK iter — investigation found ticket premise was incorrect by design)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The `architect-refresh-hash.sh` PostToolUse hook only fires for Edit/Write tool calls whose path matches `*/docs/decisions/*|docs/decisions/*`. Edits to other gated paths (e.g. `.claude/skills/`, `.claude/agents/`, source files) do not refresh the stored hash, so any prior session's hash persists. When the next session attempts a gated edit, the hash check fires deny on drift that the prior session legitimately introduced.

## Resolution

**Closed as Superseded 2026-06-08.** Investigation found the ticket's premise was incorrect when written — the design is internally consistent and the proposed fix would be a no-op.

**Why the premise does not hold**:

1. **The drift hash is scoped to `docs/decisions/` only**, not over all gated paths. `packages/architect/hooks/lib/architect-gate.sh` line 40 computes `_substance_hash_path "$PROJECT_DIR/docs/decisions"`. `_substance_hash_path` (in `lib/gate-helpers.sh`) over a directory hashes `find <path> -name '*.md' -not -name 'README.md'` — i.e. ADR files only. Edits to `.claude/skills/`, `.claude/agents/`, or arbitrary source files cannot change the value of this hash because those files are not part of the hashed content.

2. **The refresh hook fires on exactly the paths whose edits CAN change the hash** — writes under `docs/decisions/`. Broadening the refresh trigger to all gated paths (the second Investigation Task) would compute and rewrite the SAME hash on every non-`docs/decisions/` write, which is wasteful but produces no behavioural change. There is no drift the broadening would catch that the current trigger misses.

3. **The "any prior session's hash persists" symptom is not real either.** Marker files are session-scoped: `/tmp/architect-reviewed-${SESSION_ID}` (architect-gate.sh line 20) and `/tmp/architect-reviewed-${SESSION_ID}.hash` (line 36). A new session starts with no marker; the architect must be delegated fresh, which creates a new marker + hash pair anchored on the new SESSION_ID. There is no cross-session persistence of a stale hash to worry about.

**Within-session safety walk-through**:

- T0: session A architect-reviewed. Marker + hash pair set with `HASH(docs/decisions @ T0)`.
- T1: agent edits `docs/decisions/foo.md`. Enforce gate: stored hash equals current hash, allow. Write happens. PostToolUse refresh fires (path matches `*/docs/decisions/*`), updates hash to `HASH(docs/decisions @ T1)`.
- T2: agent edits `.claude/skills/some-skill.md`. Enforce gate: stored hash equals current hash (no `docs/decisions/` change since T1), allow. Write happens. PostToolUse refresh does NOT fire (path does not match). Hash stays at T1 — correct, because docs/decisions/ is unchanged.
- T3: agent edits another gated path. Enforce gate: stored hash still equals current hash. Allow. The design is internally consistent.

**Adjacent hardening already shipped (independent of this ticket)**:

- **P191 Phase 2** (`159dbcd`) anchored the `docs/decisions/` lookup on `CLAUDE_PROJECT_DIR` instead of the hook's runtime CWD, closing a separate silent-deactivation bug.
- **P353 + P303** (`e197424`, 2026-06-06 ADR-009 amendment) introduced `_substance_hash_path` (normalises CRLF / trailing whitespace before hashing) and `_atomic_mark_with_hash` (atomic mktemp + mv verdict-write), closing the hash-marker brittleness class on the docs/decisions/-anchored hash.

Neither of these touched the path-scope question P216 raised because the path scope is correct as-is.

**No code change**. Closed without a release.

## Workaround

N/A — no underlying defect.

## Impact Assessment

- **Severity**: None — ticket premise was incorrect; no behavioural defect existed.

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — n/a, closed as superseded.
- [x] Broaden hook's path filter to all gated paths (mirror the architect-enforce-edit.sh path-match rules) — investigated; would be a no-op because non-`docs/decisions/` writes cannot change a hash scoped to `docs/decisions/`. Not implemented; rejected as superseded.

### Misread design that drove the original capture

The ticket conflated **the set of paths the architect gate ENFORCES on** (broad: all project files minus the exemption list in `architect-enforce-edit.sh`) with **the set of paths the drift hash COVERS** (narrow: `docs/decisions/` markdown files only, excluding README.md). The refresh hook is correctly scoped to the latter set. The enforce hook's broad scope is about WHERE to require a review marker; the hash's narrow scope is about WHAT can invalidate a valid marker. Conflating the two looks like a missing refresh on edits to broadly-gated paths; the design actually decouples them.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/79 — upstream issue should be closed as superseded with this resolution body.
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/architect.
- **Hardened by**: [[P191]] (project-root anchoring), [[P353]] + [[P303]] (substance-aware hash + atomic verdict-write).
