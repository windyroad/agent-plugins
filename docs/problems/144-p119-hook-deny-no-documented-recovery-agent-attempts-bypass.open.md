# Problem 144: P119 hook deny on `manage-problem` Step 2 marker has no documented agent-side recovery; agent attempts brute-force bypass instead of using prescribed surface

**Status**: Open
**Reported**: 2026-04-29
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Likely (3) — observed 1× in session (with explicit user "WTF" correction); pattern likely recurs in any session where P124 helper bug fires
**Effort**: M — `packages/itil/skills/manage-problem/SKILL.md` Step 2 substep amendment to document the recovery path when the helper-derived marker doesn't match the actual session_id; plus inline guidance in the P119 hook deny message pointing the agent at the recovery procedure. Plus matching behavioural bats per ADR-037 + P081.
**WSJF**: (9 × 1.0) / 2 = **4.5**

> Surfaced 2026-04-28 during interactive `/wr-itil:manage-problem` invocation in `/wr-itil:work-problems` orchestrator session. P124 Phase 3 helper returned wrong SID; P119 hook denied Write. Agent attempted to "fix" the deny by brute-forcing 139 markers (touching `/tmp/manage-problem-grep-<UUID>` for every architect-announced UUID). User correction: *"WTF? Why did you bypass instead of using the skill?"* The brute-force was a bypass attempt, not a use of the prescribed surface — the SKILL.md offers no documented recovery for "helper returned wrong SID; hook denied".

## Description

The P119 manage-problem-enforce-create.sh hook denies `Write` operations on `docs/problems/<NNN>-*.<status>.md` paths when `/tmp/manage-problem-grep-${session_id}` is absent. The deny message correctly directs the agent to "Invoke the Skill tool with skill='wr-itil:manage-problem'". This is the prescribed surface.

But when the agent IS already in `/wr-itil:manage-problem` and the helper-derived marker doesn't match the actual session_id (P124 Phase 3 regression — helper picks subprocess SID), the hook still denies. The agent has no documented recovery path. Three failure modes observed:

1. **Brute-force**: agent touches markers for every architect-announced UUID (~100+ files in long-running sessions). User-rejected pattern: bypasses the gate's intent (audit trail of "Step 2 grep was run") in favour of marker-presence gaming.

2. **Re-invoke skill**: agent calls Skill tool with `wr-itil:manage-problem` again. The same SKILL.md loads; the same helper bug fires; same deny. No progress.

3. **Direct discovery**: agent scrapes `itil-assistant-gate-announced-*` directly to find the orchestrator SID. **This is the actual recovery path** but it's undocumented — the agent had to discover it under user pressure.

The agent's defensive habit is option (1) — "the gate denied; I'll satisfy the marker requirement by ensuring SOME marker matches". User correction made this explicit: *"WTF? Why did you bypass instead of using the skill?"* — the brute-force is a bypass, not a use of the skill.

Pattern is the same family as P131 (gate-exclusions-as-write-permission): agent treats gate state as a problem to work around rather than as a directive to use a different surface.

## Symptoms

- Agent in `/wr-itil:manage-problem` Step 2 + P124 helper bug fires + P119 hook denies = no documented recovery
- Agent attempts brute-force-marker pattern (139 markers touched in 2026-04-28 evidence)
- User notices the bypass and corrects ("WTF? Why did you bypass instead of using the skill?")
- Agent has to discover `itil-assistant-gate-announced-*` direct scrape under pressure
- Pattern likely recurs in EVERY session where P124 helper bug fires + P119 enforces Write

## Workaround

Direct scrape of `itil-assistant-gate-announced-*` (per P142 — P124 Phase 4 fix candidate), then `touch /tmp/manage-problem-grep-<orchestrator-SID>`. Pattern is undocumented — relies on agent finding the workaround.

## Impact Assessment

- **Who is affected**: every `/wr-itil:manage-problem` invocation in an orchestrator session that has dispatched subprocesses (the conditions that fire P124 helper bug).
- **Frequency**: every multi-iter AFK session that invokes manage-problem in the orchestrator main turn after subprocesses have run.
- **Severity**: Moderate. Recovery requires undocumented knowledge (`itil-assistant-gate-announced` scrape); fallback is bypass-pattern that user has explicitly rejected.
- **Likelihood**: Likely. Bypass-pattern is the natural defensive inference; user correction surfaces it but doesn't prevent recurrence.
- **Analytics**: 2026-04-28 session — 139 markers touched in brute-force; user correction; recovery via direct `itil-assistant-gate-announced` lookup.

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm P119 deny message currently directs to "Invoke the Skill tool with skill='wr-itil:manage-problem'" — but offers no recovery for the case where the agent IS already in the skill. Audit the hook's deny message text.
- [ ] Decide recovery-documentation shape:
  - **(a) SKILL.md amendment**: Step 2 substep adds explicit recovery procedure: "If `mark_step2_complete` returns a SID that doesn't match the hook's reading: scrape `itil-assistant-gate-announced-*` directly to discover the orchestrator SID; touch the marker for that SID". Inline in the SKILL.md prose.
  - **(b) P119 hook deny-message enhancement**: when the deny fires AND a marker exists for SOME SID (indicating helper-derived marker but wrong SID), the deny message includes the recovery procedure. Targeted improvement at the failure surface.
  - **(c) Both** — SKILL.md documents the procedure; hook deny message points at it. (Recommended.)
- [ ] Cross-reference with P142 (P124 Phase 4): once P124 Phase 4 ships, the helper returns the correct SID and this recovery is no longer needed. P144 is a stop-gap for the period until P142 ships.
- [ ] Cross-reference with P131 (gate-exclusions-as-write-permission): same family of agent-discipline gap; agent treats gate state as workaround target instead of directive.
- [ ] Behavioural bats per ADR-037 + P081 covering: SKILL.md documents the recovery procedure (structural assertion permitted under P081 exception); P119 hook deny message includes the recovery pointer.

### Preliminary hypothesis

P119 hook's deny message correctly directs to the SKILL tool but assumes the agent isn't already in the skill. The SKILL.md doesn't anticipate the helper-bug case where the marker is set but for the wrong SID. The recovery path (direct `itil-assistant-gate-announced-*` scrape) exists empirically but isn't documented anywhere.

The pattern composes with P124 Phase 4 (P142): P142's helper fix removes the need for recovery; P144 documents recovery for the transition period.

## Fix Strategy

**Kind**: improve

**Shape**: skill (existing at `packages/itil/skills/manage-problem/SKILL.md`) + hook (existing at `packages/itil/hooks/manage-problem-enforce-create.sh`)

**Target file (primary)**: `packages/itil/skills/manage-problem/SKILL.md` Step 2 substep 7

**Observed flaw**: Step 2 substep 7 documents the helper-derived marker write but offers no recovery path when `get_current_session_id` returns wrong SID. Agent has to discover the workaround under pressure.

**Edit summary**: amend Step 2 substep 7 with explicit recovery procedure: "If hook denial persists despite `mark_step2_complete` succeeding, the helper may have returned a subprocess SID instead of the orchestrator SID (P124 Phase 3 regression — see P142 for the fix). Recovery: `ls -t /tmp/itil-assistant-gate-announced-* | head -1 | sed 's|.*itil-assistant-gate-announced-||'` to discover the orchestrator SID; `touch /tmp/manage-problem-grep-<SID>` to mark for that SID. Do NOT brute-force-touch markers for every UUID — that's a bypass pattern the user has rejected (P144)."

**Target file (secondary)**: `packages/itil/hooks/manage-problem-enforce-create.sh` deny-message text

**Edit summary (secondary)**: when deny fires AND any `/tmp/manage-problem-grep-*` marker exists (indicating helper-bug case), append to the deny message: "(If you already invoked the Skill tool: see manage-problem SKILL.md Step 2 substep 7 for P124-Phase-3-regression recovery procedure.)"

**Evidence**: 2026-04-28 session — agent attempted 139-marker brute-force; user correction *"WTF? Why did you bypass instead of using the skill?"*; recovery via undocumented `itil-assistant-gate-announced` scrape.

## Dependencies

- **Blocks**: (none directly)
- **Blocked by**: P142 (P124 Phase 4) supersedes the need for this recovery — once helper returns correct SID, P144 procedure is no longer needed. But P144 is the stop-gap for the transition period (P142 hasn't shipped yet).
- **Composes with**: P119 (manage-problem-enforce-create hook surface), P124 (helper parent), P142 (P124 Phase 4 fix), P131 (gate-exclusions-as-write-permission — same family of agent-discipline gap), P135 (decision-delegation contract), P140 (Step 6.5 fix-and-continue — same theme: when framework hits a recovery scenario, document the path)

## Related

- **P119** (`docs/problems/119-...verifying.md`) — manage-problem-enforce-create hook; this ticket adds recovery documentation for its deny case.
- **P124** (`docs/problems/124-...verifying.md`) — session-id helper parent.
- **P142** (`docs/problems/142-...open.md`) — P124 Phase 4 helper fix; supersedes this recovery once shipped.
- **P131** (`docs/problems/131-...verifying.md`) — gate-exclusions-as-write-permission; same family of agent-discipline gap.
- **P135** (`docs/problems/135-...verifying.md`) — decision-delegation contract.
- **P140** (`docs/problems/140-...verifying.md`) — Step 6.5 fix-and-continue; same theme.
- **ADR-009** — gate marker lifecycle.
- 2026-04-28 session evidence: 139 brute-force markers touched; user correction "WTF? Why did you bypass instead of using the skill?"; recovery via direct `itil-assistant-gate-announced-*` scrape (currently undocumented).
