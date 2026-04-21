# Problem 088: run-retro cannot see the full session context when invoked as a subagent, subprocess, or from any non-parent-session surface — P086's fix is partially blind

**Status**: Open
**Reported**: 2026-04-21 (user observation post-AFK-iter-7, mid-direction-update commit)
**Priority**: 12 (High) — Impact: Significant (3) x Likelihood: Almost Certain (4)
**Effort**: L — requires (a) an ADR (or ADR-032 amendment) defining the retro-context-layer taxonomy (what each retro-invocation surface can see vs cannot), (b) a mechanism for combining per-iteration + session-level retro views (likely a retro-findings artefact that subprocesses emit and the orchestrator aggregates), (c) extending run-retro's SKILL.md to handle multiple invocation surfaces (per-iteration, orchestrator-at-ALL_DONE, user-parent-session-ad-hoc), (d) potentially extending run-retro with a session-log parser so it can reach back into `~/.claude/projects/*/sessions/*.jsonl` for cross-iteration context when invoked from a limited-context surface.
**WSJF**: 3.0 — (12 × 1.0) / 4 — High severity (retro findings are the primary feedback loop for the whole suite's improvement; partial coverage means patterns go uncaught across sessions); L effort because it touches run-retro SKILL.md + ADR-032 + work-problems SKILL.md + likely a new per-iteration retro-artefact contract.

## Description

User observation 2026-04-21 (verbatim): *"I just realised run-retro cannot be done as an subagent, because it won't have the context"*.

The observation is correct and applies more broadly than the subagent surface:

**Retro-context matrix by invocation surface**:

| Retro invocation surface | Has parent-session tool-call history? | Has per-iteration subprocess internals? | Has cross-iteration patterns? | Has release/drain events? |
|---|---|---|---|---|
| **Subagent** (Agent-tool-spawned) | No | No | No | No |
| **Subprocess** (`claude -p` per-iteration, the P086 implementation) | No | Yes (this iteration only) | No | No |
| **Orchestrator's main turn at ALL_DONE** | Yes (orchestrator's own activity) | No (opaque `ITERATION_SUMMARY` only) | Partial (from summaries) | Yes |
| **User's parent session, ad-hoc** | Yes | No (subprocesses long gone) | Partial (from orchestrator's ALL_DONE summary + git log) | Yes |
| **Session-log parser** (reads `~/.claude/projects/*/sessions/*.jsonl`) | Yes | Yes (if the log captures subprocess tool calls — to be confirmed) | Yes | Yes |

**No single context today combines per-iteration depth with cross-iteration visibility.** P086 (shipped this session in `@windyroad/itil@0.16.0`) extends the AFK iteration prompt to invoke `/wr-retrospective:run-retro` inside the subprocess. That captures per-iteration observations (architect review rounds, hook TTL expiries, TDD hook re-runs, specific tool-call patterns during this one iteration) — but the subprocess CAN'T see:

- Whether the same pattern fired in iter 2, 4, and 7 (cross-iteration).
- Drain events the orchestrator handled between iterations (Step 6.5).
- Release cadence, install events, BRIEFING updates.
- The orchestrator's own context shape (which other tickets were considered, which were skipped with what reason).

## Symptoms

- Iter 7 of this session's AFK run reported *"Retro surfaced no new briefing entries, tickets, or pipeline-instability signals this iteration"* — correct for a single-iteration view, but uninformed about the session-level patterns (5 releases, 2 drain events, 2 hook TTL expiries, 1 permission-denial in iter 3's subprocess-probe).
- The previous AFK iter-6 session's orchestrator-side retro captured "hook TTL expired once" but only because the user's main context was running the retro with session visibility. A subprocess-only retro would not have caught that.
- BRIEFING.md lines 35 + 61 reference the hook-TTL-expiry pattern — discovered repeatedly across sessions because retro context is partial at every layer. A comprehensive retro would have catalogued it once and proposed a structural fix.
- P086's Candidate Fix section lists "extend iteration prompt to run run-retro before ITERATION_SUMMARY" as option (1, recommended) — shipped — but the ticket didn't flag that this only gives per-iteration coverage and leaves session-level retro uncovered. That gap is what this ticket closes.

## Workaround

**Today**: the user runs `/wr-retrospective:run-retro` in their parent session at session-wrap, with full-session visibility (but limited to what tool calls the orchestrator's main turn actually captured — subprocess internals are still opaque). This is what happened at the end of AFK-iter-6 and produced useful findings. The workaround is "manual user-initiated retro in the parent session" — works, but defeats the AFK autonomy promise.

## Impact Assessment

- **Who is affected**:
  - **JTBD-006 (Progress the Backlog While I'm Away)** — "clear summary on return" is supposed to include session-level retro findings, not just ticket-completion state. Partial retro coverage leaves the summary blind to session-level patterns.
  - **JTBD-101 (Extend the Suite with Clear Patterns)** — new friction patterns in skills/hooks/agents should route to tickets via retro. Partial coverage means patterns compound across sessions (see hook TTL pattern above).
  - **JTBD-001 (Enforce Governance Without Slowing Down)** — sustained improvement of the governance layer depends on retro catching cross-iteration patterns. A per-iteration-only view misses structural issues.
- **Frequency**: every AFK loop run post-P086. Compounds across sessions.
- **Severity**: High. Retro is the feedback loop that drives suite improvement; a blind feedback loop means the suite accumulates invisible structural friction.

## Root Cause Analysis

### Structural

P086's fix shipped fast (same-session observation → same-session ship) and was framed narrowly around "subprocess discards its context on exit, let's add retro-on-exit". It did the narrow thing correctly. But the retro-context problem has more layers than one retro invocation point can cover:

1. **Per-iteration retro** (P086's current implementation) — catches what happens INSIDE a single iteration.
2. **Session-level retro** (what's missing) — catches what happens ACROSS iterations at the orchestrator layer.
3. **Full-trace retro** (what would be ideal) — catches everything including subprocess internals, orchestrator activity, and user-parent-session activity, by reading session logs.

Each layer has a different context window. No single invocation surface covers all three.

### Candidate fixes

1. **Extend run-retro to support multiple invocation surfaces with declared scope** (Recommended — foundational). Add a `--scope` flag or frontmatter option: `iteration` (P086 default), `session` (orchestrator-at-ALL_DONE), `full-trace` (parses `~/.claude/projects/*/sessions/*.jsonl`). Each surface has defined visibility and emits findings accordingly. Retro at each layer produces artefacts the next layer can aggregate.

2. **Per-iteration retro-findings artefact + orchestrator aggregation** — each subprocess iteration writes a structured `iteration_findings` block alongside `ITERATION_SUMMARY`. Orchestrator aggregates across iterations and runs session-level retro at ALL_DONE on the aggregate. Covers per-iteration depth AND cross-iteration pattern detection without needing session-log parsing.

3. **Session-log parser for full-trace retro** — run-retro gains a `--scope full-trace` mode that parses `~/.claude/projects/*/sessions/*.jsonl` for the specific session. Reveals subprocess-internal tool calls even when run from a limited-context surface. Cross-plays with P087 (session-log parsing for maturity signal — same infrastructure).

4. **Three-stage retro pipeline** — iteration retro (P086, subprocess) → session aggregation retro (orchestrator at ALL_DONE) → user-ad-hoc retro (parent session, full context). Each stage has defined responsibilities. Most complete coverage; most implementation surface.

Recommended: **(1) + (2) combined**. Declared-scope flag on run-retro + per-iteration findings artefact for aggregation. Ships without requiring session-log parsing infrastructure. Option (3) is a natural extension once P087's session-log parser lands. Option (4) describes the end-state once (1), (2), and (3) all ship.

### Relationship to P086

P086 is NOT wrong — it solved a real gap (subprocess discards its context on exit). This ticket (P088) extends P086's scope to cover the cross-iteration and full-session retro views that a subprocess-only retro can't reach. P086 continues to ship the per-iteration retro surface; P088 adds the session-level surface on top. The two are complementary, not competing.

P086's ticket description and `## Fix Strategy` should be updated to note that P086's shipped fix covers the "iteration" scope per this ticket's taxonomy, with "session" and "full-trace" scopes deferred to P088.

## Related

- **P086** (`docs/problems/086-*.verifying.md`) — shipped the per-iteration retro-on-exit surface. This ticket is the acknowledged follow-up covering session-level + full-trace coverage.
- **P087** (`docs/problems/087-*.open.md`) — session-log parsing infrastructure overlaps: option (3) above is the same mechanism P087 would use for the invocation-count signal.
- **P084** (`docs/problems/084-*.verifying.md`) — subprocess-boundary variant is the parent surface this ticket extends.
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — subprocess-boundary sub-pattern; may need an amendment pinning the retro-context-layer taxonomy.
- **JTBD-006** (Progress the Backlog While I'm Away) — primary beneficiary.
- **JTBD-101** (Extend the Suite with Clear Patterns) — structural-friction-pattern capture depends on this.
- `packages/retrospective/skills/run-retro/SKILL.md` — primary implementation target.
- `packages/itil/skills/work-problems/SKILL.md` Step 5 — P086's current iteration prompt; target for the per-iteration findings artefact addition.
- `~/.claude/projects/*/sessions/*.jsonl` — evidence source for full-trace retro.

### Investigation Tasks

- [ ] Architect review on the fix shape: which combination of candidates (1)+(2), (1)+(2)+(3), or all four.
- [x] Confirm `~/.claude/projects/*/*.jsonl` logs DO capture subprocess tool calls when parent was Claude Code. **CONFIRMED 2026-04-21 (empirical).** Each `claude -p` subprocess gets its own `.jsonl` file in the parent's project log directory (`~/.claude/projects/-<project-path>/`). Observed after AFK-iter-7's wrap: orchestrator session `0743ae45-...jsonl` (3.3MB, 259 tool_uses) plus seven per-iteration subprocess sessions `908c95d8-...` (iter 1, 24 tool_uses), `85f7d4cc-...`, `4bfc0268-...`, `dfad148e-...`, `33419254-...`, `6e478b4c-...`, `b459f048-...` (iter 7, 90 tool_uses). Session IDs align with the `session_id` values emitted in each subprocess's JSON response. Full-trace retro is feasible by reading orchestrator + subprocess jsonls in chronological order; the parser needs to associate subprocess sessions with their orchestrator via mtime sequencing (or by correlating with the orchestrator's Bash tool calls that spawned each `claude -p`).
- [ ] Decide retro-findings-artefact schema for option (2): structured fields alongside `ITERATION_SUMMARY`, or a separate artefact file.
- [ ] Update run-retro SKILL.md with the `--scope` flag and three-scope taxonomy.
- [ ] Update work-problems SKILL.md Step 5 iteration prompt to emit iteration-findings artefact (option 2).
- [ ] Update work-problems SKILL.md ALL_DONE output to run session-level retro on aggregated findings.
- [ ] Amend ADR-032 subprocess-boundary variant with the retro-context-layer taxonomy.
- [ ] Bats contract assertions covering the new scope flag + artefact emission.
