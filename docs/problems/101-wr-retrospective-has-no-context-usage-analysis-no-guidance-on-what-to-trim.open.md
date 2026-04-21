# Problem 101: `wr-retrospective` has no context-usage analysis — opaque where session tokens are consumed; no guidance on what to trim

**Status**: Open
**Reported**: 2026-04-22
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: L
**WSJF**: (12 × 1.0) / 4 = **3.0**

> User direction 2026-04-22: *"context tends to bloat over time. It would be nice if the retrospective plugin could analyse where tokens are being consumed (maybe the same way that https://github.com/getagentseal/codeburn does) and suggest improvements or flag problems, either as part of the run-retro skill or as part of a new skill. I'd prefer it to be part of run-retro, but if it's really heavy and consumes lots of tokens to execute, then I don't want to do it every retro as that would be its own bloat."*

## Description

Context-budget problems (P091 and its cluster P095/P096/P097/P098/P099/P100) are detected and addressed **reactively** — the user notices bloat, opens a ticket, the cluster audits a specific surface, fixes land per surface. There is no **proactive measurement** baked into the normal workflow. Each retro session ends without the assistant ever computing "where did the tokens go this session" and without suggesting "these files / hooks / skills ate the largest budget this session — consider trimming."

Codeburn (user reference: https://github.com/getagentseal/codeburn) is the conceptual model: analyze token consumption, attribute to source, suggest improvements. The windyroad suite's equivalent would live in `wr-retrospective` since retros already reflect on "what hurt this session" — token bloat is a natural axis to add.

**User's delivery-mode preference**:
1. **Preferred**: integrate into `run-retro` as a new Step. Output a per-surface breakdown (hooks, skills, memory, BRIEFING, MCP preamble, framework listings) + top-N offenders + actionable suggestions.
2. **Fallback**: if the analysis itself is expensive enough to be its own bloat source (e.g. > 5% of session budget per invocation), factor out to a separate skill `/wr-retrospective:analyze-context` (or similar) invoked on demand, and have `run-retro` emit only a lightweight summary line pointing at it.
3. **Rejected shape**: running expensive analysis on every retro. The whole point is reducing context bloat; if the analyzer is itself bloat, the feature is self-defeating.

## Symptoms

- Every session pays preamble cost (~30–40% of 200K window per P091's estimate); users only find out where it went by reverse-audit after bloat becomes visible (e.g. early compaction, slow turns).
- Each P091-cluster child ticket (P095/P097/P098/P099/P100) was identified by human observation, not by automated measurement.
- The P091 meta's investigation task *"Build a measurement harness (`packages/shared/bin/measure-context-budget.sh` or equivalent) that counts hook output bytes per firing, totals a representative N-turn session's injections, and reports before/after deltas"* is unimplemented — this ticket supersedes that task with a broader analyzer + suggestion layer.
- No metric is reported at retro time for "hook preamble bytes this session", "SKILL.md bytes loaded this session", "memory files loaded this session", etc.

## Workaround

Manual audit on user observation. Examples this session: user noticed bloat on CLAUDE.md pointers; user flagged BRIEFING.md accumulator pattern; user identified `wr-retrospective` missing session-start announcement. Each required human pattern-spotting to start.

## Impact Assessment

- **Who is affected**: Every session in every adopter project. Primary signal: long retrospective-heavy or AFK-loop sessions that hit compaction earlier than expected.
- **Frequency**: Every session contributes context cost; the absence of measurement means the cost compounds before it's noticed.
- **Severity**: Moderate. Reactive audits have worked so far but don't scale — as the plugin surface grows, more context sources will silently accumulate. Proactive measurement catches issues before the user has to notice.
- **Analytics**: This ticket is itself the analytics layer for the P091 cluster.

## Root Cause Analysis

### Confirmed (2026-04-22)

- `packages/retrospective/skills/run-retro/SKILL.md` has no step that measures or reports context usage. Steps cover: read BRIEFING, reflect on the session, scan pipeline instability (Step 2b), update BRIEFING (Step 3), create / update tickets (Step 4), verification housekeeping (Step 4a), codification (Step 4b), summary (Step 5). None measure tokens.
- `packages/retrospective/hooks/` contains one hook (`retrospective-reminder.sh`) — a Stop hook reminding the user to run retro. No measurement hook.
- P091 meta explicitly names the measurement harness as an investigation task but hasn't acted on it. The broader analyzer-and-suggestion shape this ticket proposes subsumes that task.
- Codeburn's design (cited by the user) — treating token consumption as a first-class observable with attribution + recommendations — is the right conceptual frame. Claude Code exposes session-level cost/token metadata via `claude -p --output-format json` (per BRIEFING line 50: `total_cost_usd`, `duration_ms`, `usage.{input,output,cache_creation,cache_read}_tokens`) and per-iteration `.jsonl` logs (BRIEFING line 53). The raw measurement surface exists; `wr-retrospective` just doesn't use it yet.

### Investigation tasks

- [x] Confirm no existing context-usage analysis step in run-retro (2026-04-22 audit).
- [ ] Fetch and study https://github.com/getagentseal/codeburn — understand its analysis axes (per-file, per-tool, per-turn), suggestion shapes, and whether it measures by static-source-size-count or by LLM-side reported usage.
- [ ] Enumerate the measurement surfaces available in a Claude Code session: `claude -p --output-format json` fields, `.jsonl` log format, hook output byte counts, SKILL.md byte counts per skill invocation, memory file byte counts, framework-listing byte counts (available-skills, subagent-types, deferred-tools).
- [ ] Decide analysis layer granularity: per-source bucket (hooks / skills / memory / briefing / ADRs / problems / MCP / framework / user-project-owned) vs per-file vs per-turn vs per-tool-call. Codeburn comparison informs the choice.
- [ ] Decide integration surface: (a) new run-retro Step 2c (cheap analysis always runs), (b) new standalone skill `/wr-retrospective:analyze-context` (expensive analysis on demand), (c) layered — cheap in run-retro + deep on demand. User preference: (a) if cheap enough; (c) otherwise; explicitly reject "expensive always-on".
- [ ] Design the suggestion / flagging heuristic. Candidates: top-N-largest-contributors table, delta-from-last-session (highlight growth), violation-against-policy (budget-breach detection), per-plugin attribution.
- [ ] Decide reporting shape: inline retro summary section vs a separate `docs/retros/<date>-context-analysis.md` artefact. Inline means the retro report itself grows (self-referential bloat concern); separate means the report lives long-term and can itself bloat.
- [ ] Architect review at design-time: does this need its own ADR? Likely yes — the measurement contract + sampling policy + report shape are all design decisions worth recording. Candidate title: "Progressive context-usage analysis for retrospective sessions."
- [ ] JTBD review: which job does this serve? Candidates: JTBD-001 (enforce governance without slowing down — measurement catches bloat before it slows), JTBD-006 (progress the backlog while I'm away — AFK loops benefit most from shorter context turns), potentially a new JTBD for "know what's eating my context."

## Fix Strategy

**Two-layer design (reflects user's A-then-C preference chain)**:

1. **Cheap layer — integrated into `run-retro`**. A new Step 2c that runs every retro, costs < 5% of session budget, and reports:
   - Per-source bucket byte/token totals (rough attribution).
   - Top-5 offenders by size.
   - Simple delta-from-last-retro if available.
   - A pointer to the deep analyzer when anything looks anomalous.

2. **Deep layer — standalone skill `/wr-retrospective:analyze-context`**. On-demand analyzer that runs richer heuristics — per-turn attribution, suggestion generation, policy-breach detection, per-plugin deep-dive. Invoked by the user when the cheap layer surfaces a concern, or periodically (every Nth retro, user choice). Output shape: a markdown report saved to `docs/retros/<date>-context-analysis.md` (lives long-term; composes with P099's bloat rules — the report itself must follow progressive-disclosure conventions).

3. **Frequency guard on the cheap layer**: if the cheap layer's own cost exceeds the budget (< 5% of session), the layer is unfit — move it entirely to on-demand. User's explicit rejection: "I don't want to do it every retro as that would be its own bloat."

4. **Architectural amendment**: the ADR anchor on P091 ("Progressive disclosure for governance tooling context") grows to cover this ticket too, or a sibling ADR is authored specifically for context-usage measurement. Architect decides at implementation time.

## Dependencies

- **Blocks**: (none directly; but once this ships, P091's investigation-task "Build a measurement harness" gets checked off as subsumed)
- **Blocked by**: (none)
- **Composes with**: P091 (parent meta — this ticket subsumes its measurement-harness task), P099 (BRIEFING bloat — analysis would flag it; report output must itself obey P099 discipline), P100 (artifact surfacing — analysis could trigger surfacing recommendations), P088 (run-retro context visibility — the deep layer needs to see the full session context, matching P088's concern)

## Related

- **P091** (Session-wide context budget — meta) — parent meta. This ticket subsumes P091's measurement-harness investigation task with a broader analyzer-and-suggestion shape.
- **P095 / P097 / P098 / P099 / P100** — sibling P091 children. P101 is the proactive-detection layer; the others were reactive-remediation for specific surfaces. Once P101 ships, similar future surfaces should get caught at retro time rather than requiring human observation.
- **P088** (run-retro cannot see full context when invoked as subagent/subprocess) — adjacent run-retro quality issue. The deep analyzer in this ticket needs to see full session context, making P088's resolution a soft prerequisite for option (b)/(c) delivery modes.
- **P050 / P044** (run-retro codification axes) — adjacent. This ticket adds a new reflection axis ("context usage") alongside the existing ones.
- **Codeburn** (https://github.com/getagentseal/codeburn) — user reference for the conceptual shape. Investigate at implementation time for analysis axes + suggestion patterns + measurement approach.
- **ADR-038** (progressive disclosure for governance tooling context) — the pattern anchor. A sibling ADR (or amendment) will govern the measurement contract, sampling policy, and report shape for P101.
- **ADR-023** (wr-architect performance review scope) — byte-budget glob (`performance-budget-*`) is the existing precedent for making performance metrics discoverable. This ticket's analyzer should emit findings in a format compatible with that glob so the architect review can consume them.

## Fix Strategy — self-contained-work vs recurring-pattern classification

Per run-retro Step 4b Stage 2 / P075: this ticket is not a one-shot bounded edit; it introduces a new analytic surface with measurement, heuristics, reporting, and delivery-mode options. Marked as `create` Kind, `skill` shape (for the deep layer) + `skill — improvement` (for the cheap layer embedded in run-retro). Stage 2 recording: `Other codification shape` is also implicated if the ADR and report-output conventions land as their own files. Free-text fix-strategy recording is captured inline in the Fix Strategy section above.
