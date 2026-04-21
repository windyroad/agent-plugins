# Problem 091: Plugin + hook stack consumes substantial context at session startup

**Status**: Open
**Reported**: 2026-04-22
**Priority**: 15 (High) — Impact: Moderate (3) x Likelihood: Almost certain (5)
**Effort**: L
**WSJF**: (15 × 1.0) / 4 = **3.75**

## Description

When a Claude Code session starts in a project with the standard windyroad plugin set enabled, a large amount of context is consumed *before any user work begins*. The user observation at 2026-04-22:

> we appear to be using up a lot of context just on start up

Evidence captured during this session (just running `/install-updates` immediately after a `/clear`), the following payloads are added to the conversation context:

**At session start (one-off):**
- Global `/Users/tomhoward/CLAUDE.md` — 98 lines of accessibility-first preamble + agent matrix + commands table.
- Memory index (`MEMORY.md`) + any referenced memory files.
- Full available-skills list with long descriptions (30+ skills from windyroad plugins + built-ins).
- Full subagent-types list (50+ agents with multi-line descriptions each — accessibility-lead, design-system-auditor, cognitive-accessibility, etc.).
- Deferred-tools list (~50 tool names).
- MCP server instructions (`mcp__computer-use` block alone is ~3KB of prose).

**On every user prompt (recurring — the larger issue):**
- `UserPromptSubmit` hook output from `wr-architect/hooks/architect-detect.sh` — the MANDATORY ARCHITECTURE CHECK block is ~1.4KB of injected prose per prompt.
- `UserPromptSubmit` hook output from `wr-jtbd/hooks/jtbd-eval.sh` — the MANDATORY JTBD CHECK block is ~0.6KB per prompt.
- `UserPromptSubmit` hook output from `wr-tdd/hooks/tdd-inject.sh` — the MANDATORY TDD ENFORCEMENT block with full STATE RULES table is ~1.5KB per prompt.

Per-prompt windyroad hook injection total: **~3.5-4.4KB of repeated prose on every turn**, re-stating the same scoping rules each time. Over a 30-turn session: ~100-130KB / ~25-30k tokens of pure hook preamble, most of it identical to the prior turn.

This is the cost before any actual work. It compounds with MCP/claude-code-built-in preamble to push the "time remaining until compaction" down materially.

## Symptoms

- Cold-start `/clear` followed by a single skill invocation (like `/install-updates` in this session) already has a meaningful portion of the 200K window consumed before the first assistant response.
- The same three hook instruction blocks are visible in every user turn's prefix — identical text, re-emitted.
- Context-heavy sessions (AFK loops, long retros, batch problem work) compact earlier than expected.
- User perceives "startup cost" as disproportionately high for the value delivered before real work begins.

## Workaround

None for end-users today. Mitigations available in the plugin design space:
- Emit hook injection only once per session (first prompt) instead of every prompt. Scope detection (the `docs/decisions/` / `docs/jtbd/` / TDD-enabled check) still runs per prompt; only the instruction prose would be conditionally suppressed after a session-start marker file is written.
- Shorten the injected prose to the essential directive ("delegate to wr-architect:agent before edits; scope: project files; exclusions: governance docs") and let the agent read the full scope rules when invoked.
- Replace three separate per-prompt hook emissions with a single consolidated gate-reminder (one injection instead of three).

## Impact Assessment

- **Who is affected**: Every user of any windyroad plugin set (current project + 5 siblings in this workspace; unknown downstream adopters of `@windyroad/*` packages).
- **Frequency**: Every session; every prompt within every session.
- **Severity**: High cumulative. Each individual injection looks cheap; the per-session aggregate is large and grows with turn count.
- **Analytics**: Not yet measured in `.risk-reports/` or equivalent. P034 (centralise risk reports) would give us the shape needed to quantify the per-session token cost across projects.

## Root Cause Analysis

### Preliminary hypothesis

Two architectural choices compound:

1. **UserPromptSubmit hooks re-emit the full instruction block on every prompt rather than once per session.** The scripts have no "already-announced this session" check, so the LLM sees the same MANDATORY block text on every turn even though the instruction hasn't changed. The hook's *detection* (whether the scope applies) is correctly per-prompt; the *instruction text* could be once-per-session.

2. **The instruction prose itself is verbose.** Each hook explains the full REQUIRED ACTIONS list, SCOPE rules, exclusion list, and workflow. A terse directive ("Delegate to `wr-architect:agent` before editing project files; full scope in the agent's prompt.") would convey the same enforcement behaviour in ~10% of the tokens — the agent itself can re-read its own scope when it runs.

A second-order factor: **three separate plugins each emit their own MANDATORY block per prompt**. Even if each individual block shrinks, the three-way repetition of "YOU MUST FOLLOW THIS" / "REQUIRED ACTIONS" / "SCOPE" boilerplate is additive. A single consolidated "governance gates active: architect, jtbd, tdd" line would cover all three.

### Investigation tasks

- [ ] Measure actual token consumption at session start for a clean project (current project + 5 siblings): global CLAUDE.md + memory + skills list + subagent list + MCP blocks + first-prompt hook injections. Quantify before recommending cuts.
- [ ] Measure per-prompt hook injection token cost across a representative 30-turn session. Confirm the "~25-30k tokens of pure hook preamble" estimate.
- [ ] Audit each windyroad plugin's `UserPromptSubmit` hooks for the "emit on every prompt" pattern vs the "emit once per session" pattern. Identify candidates for once-per-session emission.
- [ ] Investigate whether session-start marker files (similar to the TDD state or architect-reviewed markers) can gate the hook prose without losing enforcement semantics.
- [ ] Draft an ADR for "Hook injection budget policy" — principles for when an injection is warranted per-prompt vs once-per-session, target token budget for per-prompt preamble, consolidation rules for multi-plugin governance messages.
- [ ] Create a reproduction measurement — a small harness that counts tokens in a fresh session's first assistant turn with / without windyroad plugins enabled, so the "before" and "after" of any fix is auditable.
- [ ] Consider whether memory file injection can be leaner (MEMORY.md is an index — individual memory files should only load when actually relevant to the turn, not all at once at session start).

## Related

- **P029 (Edit gate overhead disproportionate for governance documentation changes)** — adjacent concern; P029 is about agent-invocation volume on governance doc edits, this ticket is about per-prompt injection volume regardless of edit target. Fixes may share infrastructure (scope-exclusion lists) but they are distinct failure modes.
- **P034 (Centralise risk reports for cross-project skill improvement)** — the measurement infrastructure this ticket needs for "quantify the per-session cost" would benefit from that centralisation.
- **P071 (Argument-based skill subcommands are not discoverable)** — split slice 1-4 reduced `/wr-itil:manage-problem` size by moving subcommands into dedicated skills; similar trimming pressure on the UserPromptSubmit hooks is the same pattern applied to a different surface.
- **P087 (No maturity signal for plugin features)** — if hook-injection budget becomes a tunable dimension, it intersects with maturity signalling (experimental plugins could opt out of verbose preambles).
- **ADR candidate**: "Hook injection budget policy" — to be drafted during investigation task 5 if the measurement confirms the problem.
