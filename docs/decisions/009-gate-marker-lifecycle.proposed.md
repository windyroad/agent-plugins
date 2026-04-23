---
status: "proposed"
date: 2026-04-15
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-15
---

# Gate Marker Lifecycle: TTL + Drift, Not Stop-Hook Reset

## Context and Problem Statement

The five review plugins (`architect`, `jtbd`, `voice-tone`, `style-guide`, `risk-scorer`) each have a Stop hook that removes the session review marker at the end of every assistant response:

```bash
rm -f "/tmp/${system}-reviewed-${SESSION_ID}"
```

Claude Code's `Stop` event fires when the assistant finishes responding. As a consequence, **every new user prompt forces a fresh review**, even when nothing relevant has changed.

At the same time, the shared gate library already implements two other controls that together can determine when re-review is actually needed:

- **TTL**: 60 minutes (`ARCHITECT_TTL=3600`, etc.), sliding window on each check via `touch "$MARKER"`
- **Drift detection**: hash of the plugin's policy files (`docs/decisions/*.md`, `docs/jtbd/**/*.md`, etc.); mismatch invalidates the marker

The Stop-hook reset **overrides** these controls, forcing re-review even when TTL is fresh and no drift has occurred. This directly conflicts with JTBD-001's documented desired outcome: *"Reviews complete in under 60 seconds so they don't break flow."* In practice, every prompt turn with any file edit routinely triggers a fresh 30–60s review.

Tracked as P001 (`docs/problems/001-architect-gate-marker-consumed-too-quickly.open.md`).

## Decision Drivers

- **JTBD-001 compliance**: reviews must not break flow; current behaviour adds 30–60s to every prompt
- **Existing controls are sufficient**: TTL + drift detection already correctly identify when re-review is needed
- **Drift coverage is comprehensive**: each plugin hashes its policy files; any change triggers re-review
- **Symmetry across plugins**: the 5 review plugins should share a consistent lifecycle policy
- **Existing users' expectations**: removing the reset is the lighter option but must not silently degrade governance

## Considered Options

### Option 1: Keep Stop-hook reset (status quo)

Every new prompt requires a fresh review. Safest (no chance of stale approvals persisting), but highest friction.

### Option 2: TTL + drift only

Remove the Stop-hook reset from all 5 review plugins. Rely on the gate library's TTL (60 min) + drift detection to invalidate markers when they are actually stale.

### Option 3: Hybrid — reset ephemeral markers, keep review markers

Keep the Stop-hook reset for ephemeral markers (e.g., `/tmp/jtbd-verdict` — already removed on read) but not for the long-lived session review markers. More nuanced but more surface area to reason about.

### Option 4: Shorter TTL

Reduce TTL to e.g. 5 minutes instead of removing the Stop-hook reset. This would technically allow repeat edits within a short window, but doesn't match typical dev flow (longer than 5 min between edits is common).

## Decision Outcome

**Chosen option: Option 2 — TTL + drift only.**

Remove the Stop-hook reset across all 5 review plugins. The TTL (30 min default) and drift detection already cover the two conditions that warrant re-review:

1. Time has passed (review is stale)
2. Policy files have changed (review context is stale)

Neither condition is inherently tied to end-of-response. A long assistant response with no relevant changes shouldn't invalidate a just-completed review.

TTL remains configurable per-plugin via existing envvars (`ARCHITECT_TTL`, `RISK_TTL`, etc.), default 3600s (60 minutes). Extended from 1800s via P107 to cover long multi-file edit batches.

## Plugin Scope

Hooks to remove (one per plugin):

- `packages/architect/hooks/architect-reset-marker.sh` (registered in `architect/hooks/hooks.json` Stop event)
- `packages/jtbd/hooks/jtbd-reset.sh`
- `packages/voice-tone/hooks/voice-tone-reset-marker.sh`
- `packages/style-guide/hooks/style-guide-reset-marker.sh`
- `packages/risk-scorer/hooks/*-reset.sh` (if any Stop-reset hooks exist)

The Stop hook registration in each `hooks.json` should be removed alongside the script. The scripts themselves can be deleted.

**Out of scope**: TDD plugin's Stop hook (`tdd-reset.sh`) — the TDD state machine has different lifecycle semantics (per-test-file state) and is not governed by this decision. Revisit if it becomes a concern.

## Consequences

### Good

- Reviews persist across prompts within a 60-minute window, matching developer flow
- JTBD-001 "reviews complete in under 60s" outcome becomes achievable for multi-prompt sessions
- Fewer tokens consumed on repetitive re-reviews
- Consistent lifecycle across the 5 plugins

### Neutral

- TTL is still configurable via existing envvars — teams that want stricter behaviour can shorten it
- Drift detection already catches the genuine invalidation condition; no new failure modes introduced

### Bad

- **Stale-marker risk**: if the agent does something within a 60-min window that *should* trigger re-review but doesn't change policy files (e.g., the agent's own context evolves in ways not captured by file hashes), the previous review remains valid. Mitigated by drift detection covering the canonical policy files.
- **Backward compatibility**: existing users upgrade to new behaviour on the next plugin release. Those relying on "fresh review every prompt" will notice. Change log / release notes must call this out.
- **Debugging**: if a stale marker does produce a false pass, diagnosis is harder than with Stop reset (need to examine marker mtime + hash).

## Confirmation

- [ ] `architect-reset-marker.sh` removed and its Stop hook entry removed from `architect/hooks/hooks.json`
- [ ] Same for `jtbd-reset.sh`, `voice-tone-reset-marker.sh`, `style-guide-reset-marker.sh`
- [ ] `grep -rn "reset-marker\|-reset\.sh" packages/` returns only TDD and test references
- [ ] BATS tests verify that: marker persists when no drift occurs, marker is invalidated by policy file change (existing drift tests), marker expires after TTL (existing TTL tests)
- [ ] Existing BATS tests for each plugin's gate continue to pass (113/113 baseline)
- [x] `ARCHITECT_TTL` and equivalents default to 3600s and are documented in the plugin READMEs (changed via P107)

## Pros and Cons of the Options

### Option 1: Keep Stop-hook reset

- Good: Every prompt gets a deterministic fresh review — no risk of stale approvals
- Good: Simple, already implemented
- Bad: Forces 30–60s review on every prompt → violates JTBD-001
- Bad: Duplicates work the gate library already does via TTL+drift

### Option 2: TTL + drift only (chosen)

- Good: Reviews persist across prompts within TTL window
- Good: Drift detection already catches policy changes
- Good: Consistent with existing gate library design
- Good: Aligns with JTBD-001 "under 60s" outcome
- Bad: Relies on drift detection catching all relevant changes
- Bad: Stale marker risk if drift detection misses a change (low likelihood given what's hashed)

### Option 3: Hybrid

- Good: Preserves ephemeral-marker safety while removing long-lived reset
- Bad: More complex — have to categorise each marker type
- Bad: The ephemeral markers (e.g., `/tmp/jtbd-verdict`) already self-clean on read; no Stop reset needed there either

### Option 4: Shorter TTL

- Good: Smallest behavioural change
- Bad: Doesn't address the root cause — Stop reset still fires
- Bad: 5-minute TTL is arbitrarily short for real dev workflow

## Reassessment Criteria

- **Stale-marker false positives reported**: If users report cases where a stale marker caused a bad change to land, reassess. Could tighten TTL or add more drift hashing.
- **Drift detection proves unreliable**: If we discover a class of changes that should invalidate reviews but don't change hashed policy files, reassess what to hash.
- **JTBD-001 outcome measurement**: If reviews still feel slow even after this change, investigate the agent invocation cost itself rather than the gate lifecycle.
- **TDD plugin lifecycle unification**: If the TDD plugin's separate lifecycle becomes inconsistent with the review plugins in practice, reassess bringing it under this policy.

## Related

- P001 (`docs/problems/001-architect-gate-marker-consumed-too-quickly.open.md`) — the problem this ADR resolves
- ADR-005 (plugin testing strategy) — BATS tests must cover the new lifecycle
- JTBD-001 (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — desired outcome driving this change
