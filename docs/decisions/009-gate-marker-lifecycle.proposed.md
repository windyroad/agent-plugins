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

### Three-band TTL refinement (P090, risk-scorer only)

The TTL primitive is interpreted inside `packages/risk-scorer/hooks/lib/risk-gate.sh` as a three-band policy:

- **Band A** — age < TTL/2 → pass silently.
- **Band B** — TTL/2 ≤ age < TTL → consult the pipeline state-hash. If the hash is invariant since the scorer ran, pass and slide the marker forward via `touch`; if the hash drifted, halt with the existing drift message. Bounded by a 2×TTL hard-cap from the scorer-run birth time stored in `<action>-born` so an unchanged-but-idle tree cannot ride a single score indefinitely.
- **Band C** — age ≥ TTL → halt unconditionally (stale-session guard; explicit rescore required).

This preserves stale-session protection while eliminating round-trips when the scoring input is invariant. Currently scoped to the risk-scorer; the architect/JTBD/voice-tone/style-guide markers remain on the binary TTL model until a future amendment decides whether symmetric adoption is warranted.

### Subprocess-boundary refresh (P111, 2026-04-25)

The TTL slide on `PreToolUse:Edit|Write` (the `touch "$MARKER"` in `gate-helpers.sh`) keeps a marker fresh when the parent agent runs a sequence of in-band tool calls. It does NOT keep the marker fresh when the parent delegates to a long-running subprocess: an Agent-tool subagent (matching or non-matching subagent_type), a `claude -p` iteration subprocess (the canonical AFK pattern per ADR-032 P084 amendment), or any `run_in_background: true` Agent invocation. Inside the subprocess the parent is silent — its `PreToolUse` hooks never fire. The parent's marker mtime stays frozen at the moment the parent last ran a gated tool, and a sufficiently long subprocess pushes the next post-subprocess `PreToolUse` past TTL even though the parent agent was actively orchestrating the whole time. P107 papered over this with a 1800s → 3600s TTL bump; the symptom returns at the new threshold (P111).

The fix is **subprocess-completion refresh**: a new PostToolUse hook (`*-slide-marker.sh`) per plugin, registered on `Agent|Bash`, calls a shared `slide_marker_on_subprocess_return` helper that:

1. Touches the parent's marker if (and only if) it already exists. NEVER creates a marker — creation requires a real gate review with verdict parsing (preserved in `*-mark-reviewed.sh`).
2. Skips the touch when `tool_response.is_error` is `true`. A failed subprocess MUST NOT extend the parent's trust window (the gate's design intent: trust requires successful policy review, and a subprocess crash is not a successful review).
3. Fail-safe on parse error: if the hook input cannot be parsed as JSON, treat as error and skip the touch.
4. No-op when the marker path is empty or the marker file does not exist.

**Why this is NOT cross-process marker sharing.** ADR-032 line 123 forbids contributors from "wir[ing] cross-process marker sharing" — an explicit isolation invariant for `claude -p` subprocesses. Subprocess-boundary refresh does NOT violate it: the parent's PostToolUse hook touches the parent's OWN marker. The subprocess never reads, writes, or sees the parent's marker. The subprocess's own session id, marker, and gate state remain independent. This is identical in shape to the existing `PreToolUse:Edit` slide; only the trigger expands to subprocess return.

**Composition with the three-band TTL refinement (P090).** Both slides touch the same `<action>` mtime. Band B's slide is in-band (fires when the gate checks); subprocess-completion slide is on subprocess return (fires from PostToolUse). They compose orthogonally. The 2×TTL hard-cap from `<action>-born` still bounds total marker life regardless of which slide fired — the born marker is deliberately **not** slid by `risk-slide-marker.sh` for exactly this reason (an unchanged-but-idle tree riding a single score indefinitely is the failure mode the hard-cap exists to prevent).

**Plugin coverage.** The five review plugins each register one slide hook:

- `packages/architect/hooks/architect-slide-marker.sh` — slides `/tmp/architect-reviewed-${SESSION_ID}` and `/tmp/architect-plan-reviewed-${SESSION_ID}`.
- `packages/jtbd/hooks/jtbd-slide-marker.sh` — slides `/tmp/jtbd-reviewed-${SESSION_ID}` and `/tmp/jtbd-plan-reviewed-${SESSION_ID}`.
- `packages/style-guide/hooks/style-guide-slide-marker.sh` — slides `/tmp/style-guide-reviewed-${SESSION_ID}` and `/tmp/style-guide-plan-reviewed-${SESSION_ID}`.
- `packages/voice-tone/hooks/voice-tone-slide-marker.sh` — slides `/tmp/voice-tone-reviewed-${SESSION_ID}` and `/tmp/voice-tone-plan-reviewed-${SESSION_ID}`.
- `packages/risk-scorer/hooks/risk-slide-marker.sh` — slides the score files `${RDIR}/{commit,push,release}` only. The `*-born` markers, `state-hash`, presence-only `{plan,wip,policy}-reviewed`, and bypass markers (`{reducing,incident}-*`) are deliberately NOT slid (see file header for rationale).

**Behavioural test contract.** Each plugin's `hooks/test/slide-marker-on-subprocess-return.bats` asserts the helper contract. The architect plugin additionally carries `hooks/test/architect-slide-marker.bats` as a hook-level integration test. The canonical P111 reproduction case — a marker backdated to 50 minutes (within default 60-min TTL but close) followed by a successful subprocess return — must leave the marker mtime ≈ NOW so the next `PreToolUse` check sees a fresh marker.

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
- P107 (`docs/problems/107-architect-jtbd-edit-gate-markers-expire-mid-batch.closed.md`) — the symptom-treatment that bumped TTL 1800s → 3600s; rooted by P111
- P111 (`docs/problems/111-subprocess-tool-calls-do-not-refresh-parent-gate-markers.open.md`) — driver for the Subprocess-boundary refresh subsection above
- P090 (`docs/problems/090-risk-scorer-commit-gate-ttl-expires-mid-session-forcing-manual-rescore.open.md`) — driver for the Three-band TTL refinement subsection
- ADR-005 (plugin testing strategy) — BATS tests must cover the new lifecycle
- ADR-032 (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — line 123 cross-process marker isolation invariant; subprocess-boundary refresh respects it (see subsection above)
- JTBD-001 (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — desired outcome driving this change
- JTBD-006 (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — AFK iteration reliability beneficiary of the subprocess-boundary refresh
