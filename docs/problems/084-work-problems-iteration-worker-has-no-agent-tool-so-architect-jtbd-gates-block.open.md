# Problem 084: work-problems iteration-worker has no Agent tool so architect + JTBD edit gates AND risk-scorer commit gate block all progress

**Status**: Open
**Reported**: 2026-04-21 (AFK iter 6, during P071 slice 5 attempt)
**Priority**: 16 (High) — Impact: High (4) x Likelihood: Likely (4)
**Effort**: M
**WSJF**: 8.0 — (16 × 1.0) / 2 — High-severity discoverability/progress block on every edit-gated iteration; moderate effort to fix (wire Agent tool into the worker subagent's allowed tool surface, or provide a Skill-tool-compatible path to set the architect/jtbd markers).

## Description

The `/wr-itil:work-problems` AFK orchestrator's Step 5 (shipped in P077 — commit `a0ec231`) correctly delegates each iteration to a spawned subagent via the Agent tool with `subagent_type: general-purpose` for isolation (per ADR-032 AFK iteration-isolation wrapper sub-pattern). The orchestrator side is correct.

However, the iteration-worker subagent inherits a tool surface that does NOT include the Agent/Task tool. This blocks the worker from satisfying the architect + JTBD PreToolUse edit gates (packages/architect/hooks/architect-enforce-edit.sh and packages/jtbd/hooks/jtbd-enforce-edit.sh), because:

1. The `/tmp/architect-reviewed-<SESSION_ID>` and `/tmp/jtbd-reviewed-<SESSION_ID>` markers that unlock the PreToolUse gate are set **only** by the Agent-tool PostToolUse hook (architect-mark-reviewed.sh + the analogous jtbd hook), which reads `subagent_type` and matches `*architect*` / `*jtbd*`.
2. The Skill tool does NOT trigger those PostToolUse hooks — invoking `/wr-architect:review-design` or `/wr-jtbd:review-jobs` via the Skill tool runs the skill's own Steps 1–6 but the Steps 5 ("Delegate to wr-architect:agent") actually require the Agent tool to produce the marker.
3. Without the Agent tool in the worker's allowed tool surface, steps 5 of both review skills are un-executable. The worker can reason about the design inline but cannot set the marker.
4. Every Write/Edit on gate-covered paths (anything outside the excluded list — docs/problems/, docs/BRIEFING.md, .changeset/, memory/, etc.) is BLOCKED.
5. The same Agent-tool-dependency also blocks `git commit` via `packages/risk-scorer/hooks/risk-score-commit-gate.sh`, which requires a bypass marker set by the `wr-risk-scorer:pipeline` subagent's PostToolUse hook. Invoking `/wr-risk-scorer:assess-release` via the Skill tool runs the prose steps but can't spawn the subagent — so the marker isn't written, and `git commit` is blocked even for docs-only commits that were supposed to be exempt. Effective result: the iteration worker cannot commit AT ALL, even changes to `docs/problems/` which are edit-gate-excluded.

Observed 2026-04-21 during P071 slice 5 (list-incidents split) attempt: the iteration worker wrote the architect and JTBD review verdicts inline (PASS on both), but could not persist markers, and every Write attempt to `packages/itil/skills/list-incidents/test/list-incidents-contract.bats` was blocked by both hooks in sequence. Falling back to docs-only work: the worker WAS able to Write the P084 ticket and Edit the P071 ticket (both excluded from edit gates), but `git commit` was then blocked by the risk-scorer commit gate for the same reason — no Agent tool, no bypass marker. **The block is total: the worker cannot land ANY persistent work, even the diagnosis ticket.**

This is the iteration-worker counterpart of P077 (which addressed the orchestrator→worker dispatch). P077 is shipped and correct; this ticket addresses the NEXT gap down: the worker→subagent dispatch surface is incomplete.

## Symptoms

- AFK iteration worker attempting to work any gate-covered ticket (i.e. most tickets — list-incidents in packages/itil/skills/, ADRs, SKILL.md files, hooks, agent definitions, bats tests outside docs/problems/) gets blocked at every Write/Edit.
- The worker correctly invokes `/wr-architect:review-design` and `/wr-jtbd:review-jobs` via the Skill tool per manage-problem Step 1's architect-review instruction, but those skills delegate to subagents via the Agent tool — which is absent.
- No error message surfaces to the orchestrator unless the worker returns with explicit diagnosis; silent halt risk is material.
- The worker CAN edit docs/problems/*.md (excluded from both gates per P004 / P009) — so diagnosis can be written to a ticket. Everything else is blocked.

## Workaround

- The worker can edit docs/problems/*.md unblocked (both gates exclude that path) — so it can document the block and return `outcome: skipped` with `skip_reason_category: upstream-blocked`.
- The user can run the iteration synchronously in the main session (where Agent tool IS available) instead of spawning a subagent.
- The worker cannot progress any gate-covered ticket without either (a) the Agent tool appearing in its surface, or (b) a Skill-tool-compatible path that sets the marker.

## Impact Assessment

- **Who is affected**:
  - **Solo-developer persona (JTBD-001)** — AFK mode promises iteration-by-iteration progress. When the worker hits gate-covered paths, progress halts silently.
  - **Every P071 slice 5+ attempt** — list-incidents, mitigate-incident, restore-incident, close-incident, link-incident are all gate-covered (packages/itil/skills/ paths). The entire remaining P071 phased plan is blocked until this is fixed.
  - Any AFK iteration working ADRs, SKILL.md edits, hook edits, or anything outside the gate-exclusion list.
- **Frequency**: every AFK iteration that touches gate-covered paths, which is most iterations. Only the `docs/problems/` editing axis (ticket updates, README refresh) works unblocked.
- **Severity**: High. AFK mode's value proposition depends on sustained unattended progress. This gap turns most iterations into silent halts or skipped-with-diagnosis cycles.

## Root Cause Analysis

### Structural

The three-layer gate architecture (PreToolUse deny by default → Agent-tool PostToolUse marker → sliding-TTL allow) was designed for the main session where the Agent tool is always available. P077 added the AFK iteration-isolation wrapper but did not audit the spawned worker's tool surface against the gate-satisfaction requirements.

The worker's surface (as observed this session): Bash, Edit, Glob, Grep, Read, Write, ToolSearch, ScheduleWakeup, Skill — plus deferred tools findable via ToolSearch. Agent/Task does not appear in the deferred list either (confirmed via `select:Agent` and `select:Task` searches returning "No matching deferred tools found").

### Three candidate fixes

1. **Add Agent tool to the worker's allowed surface.** The cleanest — subagent can spawn sub-subagents, architect/jtbd PostToolUse hook fires, markers set, edits unblock. Risk: nested-subagent resource cost and reasoning-chain depth.
2. **Extend the PostToolUse marker hook to also fire on Skill-tool invocations of `wr-architect:review-design` / `wr-jtbd:review-jobs`.** The skills already do the right work (reading diff, constructing prompt, delegating); the hook could parse the Skill tool's output for the same "Architecture Review: PASS" / "ISSUES FOUND" verdict the current hook looks for. Risk: skill-level review may be shallower than subagent review; verdicts in free-text output may be harder to parse reliably.
3. **Add a "worker-issued inline review" mode** that the worker can call via a thin skill (`/wr-governance:mark-reviewed`) which takes a PASS/FAIL verdict and writes the marker directly. Risk: bypass path that could be abused; needs audit-trail discipline.

Recommended: (1) + (3). (1) is the right long-term fix; (3) is the AFK fast path that doesn't spawn more subagents. (2) risks verdict-parsing brittleness.

## Related

- **P071** (argument-based skill subcommands not discoverable) — this ticket blocks P071 slices 5+. The P071 phased plan cannot progress via AFK iterations until this is fixed or worked around.
- **P077** (work-problems Step 5 does not delegate to subagent) — shipped; fixes the orchestrator→worker dispatch. This ticket addresses the NEXT gap (worker→sub-subagent).
- **ADR-032** (governance skill invocation patterns) — AFK iteration-isolation wrapper sub-pattern added by P077. This ticket identifies that the sub-pattern's worker-side contract is incomplete.
- **ADR-010 amended** (Skill Granularity) — the decision the P071 slices implement.
- **ADR-013** (structured user interaction for governance decisions) — Rule 1 names user control; Rule 6 AFK fallback path. This ticket reveals a new AFK fallback gap: architect/jtbd verdict cannot currently be expressed by the worker.
- `packages/architect/hooks/architect-enforce-edit.sh` + `packages/architect/hooks/architect-mark-reviewed.sh` — the gate code to amend.
- `packages/jtbd/hooks/jtbd-enforce-edit.sh` + `packages/jtbd/hooks/lib/review-gate.sh` — sibling gate code.
- `packages/architect/skills/review-design/SKILL.md` + `packages/jtbd/skills/review-jobs/SKILL.md` — the on-demand review skills that currently cannot set the marker.
- **JTBD-006** (Work the backlog AFK) — the persona outcome this ticket directly degrades.

### Investigation Tasks

- [ ] Confirm the worker's tool-surface limitation by reproducing in a fresh AFK iteration with a different skill (e.g. work-problem singular) against a non-docs/problems path.
- [ ] Decide between fixes (1), (2), (3) or combination — architect review on the fix.
- [ ] Design the marker mechanism for the chosen fix (Skill-tool hook extension vs thin skill vs Agent-tool in worker surface).
- [ ] Implement + bats contract assertions.
- [ ] Amend ADR-032's AFK iteration-isolation wrapper sub-pattern with the worker-tool-surface contract.
