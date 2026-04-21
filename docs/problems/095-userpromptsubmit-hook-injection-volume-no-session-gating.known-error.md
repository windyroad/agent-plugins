# Problem 095: UserPromptSubmit hooks across five windyroad plugins re-emit full MANDATORY prose on every prompt

**Status**: Known Error
**Reported**: 2026-04-22
**Priority**: 15 (High) — Impact: Moderate (3) x Likelihood: Almost certain (5)
**Effort**: L
**WSJF**: (15 × 2.0) / 4 = **7.5**

> Split from P091 meta (session-wide context budget) on 2026-04-22 after audit confirmed root cause. This ticket owns the concrete fix for the `UserPromptSubmit` cluster.

## Description

Five windyroad plugins each register a `UserPromptSubmit` hook that emits a full MANDATORY instruction block on every user prompt. There is no once-per-session gating — the same prose re-enters the conversation context on every turn. The five hooks are:

| Plugin | Hook | MANDATORY block (bytes) | Triggered when |
|--------|------|------------------------:|----------------|
| `wr-architect` | `architect-detect.sh` | 1701 | `docs/decisions/` exists |
| `wr-jtbd` | `jtbd-eval.sh` | 881 | `docs/jtbd/README.md` exists |
| `wr-tdd` | `tdd-inject.sh` | ~1600 (state-dependent) | `package.json` has a test script |
| `wr-style-guide` | `style-guide-eval.sh` | ~860 | `docs/STYLE-GUIDE.md` exists |
| `wr-voice-tone` | `voice-tone-eval.sh` | ~820 | `docs/VOICE-AND-TONE.md` exists |

In a project with three active hooks (this repo: architect + jtbd + tdd): ~4.2KB per prompt. In a project with all five governance docs: ~5.9KB per prompt. Over a 30-turn session: **~125–175KB / ~30–40k tokens** of pure hook preamble, most of it byte-identical to the previous turn.

## Symptoms

- Every user turn's prefix contains the same MANDATORY ARCHITECTURE CHECK / MANDATORY JTBD CHECK / MANDATORY TDD ENFORCEMENT blocks, with identical wording across turns.
- Context-heavy sessions (AFK loops, long retros, batch problem work) compact earlier than expected.
- Direct observation in this session: two `<system-reminder>` tags appeared carrying the architect + JTBD hook output on the very prompt that opened this investigation.

## Workaround

None for end-users. Design-space mitigations (all implementation-side):

1. **Once-per-session gating**: on the first `UserPromptSubmit` of a session, emit the full MANDATORY block AND write a marker file. On subsequent prompts, emit only a terse one-line reminder (or nothing). The marker convention `/tmp/${SYSTEM}-announced-${SESSION_ID}` mirrors the existing `/tmp/${SYSTEM}-reviewed-${SESSION_ID}` pattern already used by `packages/style-guide/hooks/lib/review-gate.sh`.
2. **Prose trimming**: shorten the MANDATORY block to the essential directive (~100 bytes) and let the delegated agent read its full scope when it runs.
3. **Cross-plugin consolidation**: replace N separate per-prompt MANDATORY blocks with a single consolidated "governance gates active: <comma-separated list>" line. Requires cross-plugin coordination; larger scope.

## Impact Assessment

- **Who is affected**: Every user of any windyroad plugin set (current project + 5 siblings in this workspace; unknown downstream adopters).
- **Frequency**: Every prompt of every session.
- **Severity**: High cumulative. ~15% of a 200K context window consumed by per-prompt hook preamble in a typical 30-turn session, before any actual work.
- **Analytics**: Measurement harness deliverable lives on P091 meta. This ticket adds a bats reproduction test (see Fix Strategy) that exercises before/after for each hook.

## Root Cause Analysis

### Confirmed (2026-04-22 audit)

Direct read of the five hook scripts confirms:

1. **No session-marker check in any of the five.** The scripts unconditionally `cat <<'HOOK_OUTPUT'` the full MANDATORY block when their detection condition passes (directory or file exists in the project).
2. **Verbose prose by design** — each block re-states REQUIRED ACTIONS, SCOPE, and exclusions in full. ~80–90% of those bytes are policy reference material that the delegated agent will re-read from its own system prompt when invoked. The hook only needs to remind the assistant *that* the gate is active, not *what the full scope is*.
3. **Existing infrastructure supports once-per-session gating** without new primitives:
   - `packages/style-guide/hooks/lib/review-gate.sh` already uses `/tmp/${SYSTEM}-reviewed-${SESSION_ID}` markers.
   - `packages/risk-scorer/hooks/lib/gate-helpers.sh` already provides `_get_session_id()` + `_risk_dir()`.
   - `packages/tdd/hooks/lib/tdd-gate.sh` already owns a per-session state dir.
   A shared `packages/shared/lib/session-marker.sh` with `has_announced "$SYSTEM" "$SESSION_ID"` + `mark_announced "$SYSTEM" "$SESSION_ID"` functions is a clean extraction of the common pattern.

### Investigation tasks

- [x] Audit all five `UserPromptSubmit` hooks for the "emit on every prompt" pattern (2026-04-22 audit)
- [x] Measure MANDATORY block byte sizes per hook (2026-04-22 audit — numbers in Description table)
- [x] Confirm no existing session-marker-based suppression in any of the five hooks (2026-04-22 audit)
- [x] Confirm existing infrastructure supports the marker pattern without new primitives (2026-04-22 audit — reviewed `review-gate.sh`, `gate-helpers.sh`, `tdd-gate.sh`)
- [ ] Draft ADR "Hook injection budget policy" (tracked on P091 meta; authored against this ticket's fix)

## Fix Strategy

Phased landing — two phases, both in the same change-set:

### Phase 1: Shared session-marker helper

- New file: `packages/shared/lib/session-marker.sh`
- Functions:
  - `has_announced "$SYSTEM" "$SESSION_ID"` — returns 0 if `/tmp/${SYSTEM}-announced-${SESSION_ID}` exists, else 1.
  - `mark_announced "$SYSTEM" "$SESSION_ID"` — creates that marker file.
- Empty-session-id fallback: if `$SESSION_ID` is empty (rare but possible in tests / manual invocations), degrade gracefully — emit the full block and do not write a marker. Never crash the hook.
- Bats unit test: `packages/shared/test/session-marker.bats` — covers has_announced-false-then-true flow, empty-session-id fallback, concurrent-session isolation.

### Phase 2: Hook edits

Apply the same pattern to all five `UserPromptSubmit` scripts:

```bash
# Read session_id from stdin (Claude Code hook input)
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

# Source the shared helper
source "${CLAUDE_PLUGIN_ROOT}/../shared/lib/session-marker.sh"

# Detection gate (unchanged — still fires per prompt)
if [ -d "docs/decisions" ]; then
  if has_announced "architect" "$SESSION_ID"; then
    # Subsequent prompt — terse reminder
    echo "Governance gate active: wr-architect (docs/decisions/ present)."
  else
    # First prompt of session — full block + mark announced
    cat <<'HOOK_OUTPUT'
INSTRUCTION: MANDATORY ARCHITECTURE CHECK. ...
HOOK_OUTPUT
    mark_announced "architect" "$SESSION_ID"
  fi
fi
```

Per-hook adjustments for the different trigger conditions (jtbd detects `docs/jtbd/README.md`, tdd detects `package.json` test script, etc.). Note: `tdd-inject.sh` has dynamic state (IDLE / RED / GREEN / BLOCKED) that *does* change between prompts — the terse reminder for TDD must carry the current state, so the hook still emits per-prompt state but the big STATE RULES table drops after first turn.

The five edits are small (each hook adds ~10 lines). Total diff: ~50 lines of hook changes + ~30 lines of shared helper + ~60 lines of bats tests.

### Phase 3: ADR (tracked on P091 meta)

"Hook injection budget policy" — defines the token budget per prompt, the once-per-session rule, the terse-reminder convention, the marker-file path convention. Depends on P096 audit findings for cross-surface budget numbers. Authored as part of this ticket's fix commit; supersedes any implicit "always emit" convention.

### Reproduction test

`packages/architect/test/hooks/architect-detect-once-per-session.bats` (and mirrors for the other four hooks). Asserts:

- First invocation with a given `$SESSION_ID`: output length > 1000 bytes, contains "MANDATORY ARCHITECTURE CHECK".
- Second invocation with the same `$SESSION_ID` (marker now present): output length < 200 bytes, does NOT contain "MANDATORY ARCHITECTURE CHECK".
- Invocation with a different `$SESSION_ID`: full block re-emits (per-session isolation).
- Empty `$SESSION_ID`: full block emits, no marker side effect.

Today this bats suite fails at the first assertion (the hook ignores `$SESSION_ID` and always emits the full block). After Phase 2 it passes. This is the canonical reproduction.

## Related

- **P091 (Session-wide context budget from the windyroad plugin stack — meta)** — parent meta ticket; this ticket is cluster A of the split.
- **P096 (PreToolUse/PostToolUse hook injection — sibling)** — sibling from the same split; audit pending.
- **P097 (SKILL.md runtime size — sibling)** — sibling from the same split; audit pending.
- **P029 (Edit gate overhead disproportionate for governance documentation changes)** — adjacent; P029 is about agent-invocation volume on governance doc edits. Cluster A is about hook-prose volume regardless of edit target. Same scope-exclusion list infrastructure.
- **`packages/style-guide/hooks/lib/review-gate.sh`** — reference pattern for session-marker gating.
- **`packages/risk-scorer/hooks/lib/gate-helpers.sh`** — reference for `_get_session_id()` helper.
- **ADR anchor**: "Hook injection budget policy" (tracked on P091; authored as part of this ticket's fix commit).
