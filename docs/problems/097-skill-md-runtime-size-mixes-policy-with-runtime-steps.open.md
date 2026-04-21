# Problem 097: SKILL.md files mix runtime-necessary steps with maintainer-facing rationale, bloating every skill invocation

**Status**: Open
**Reported**: 2026-04-22
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: L
**WSJF**: (12 × 1.0) / 4 = **3.0**

> Split from P091 meta (session-wide context budget) on 2026-04-22. Size data collected during the P091 audit is already damning — the RCA is confirmed on magnitude. What remains unproven is the fix path: whether the "runtime steps vs reference material" split is achievable without runtime support from Claude Code. Hence Open, not Known Error, until the fix path is validated.

## Description

Every `/wr-<plugin>:<skill>` invocation loads the full `SKILL.md` file into the conversation context. Windyroad `SKILL.md` files have grown to carry content for multiple audiences — runtime operators, maintainers, ADR-tracking, deprecation notices, worked examples — and most of that weight loads on every invocation even when only the runtime steps are needed.

Measured sizes across windyroad packages (top 10 by byte count, 2026-04-22 audit):

| Skill | Bytes | Lines | Est. tokens |
|-------|------:|------:|------------:|
| `/wr-itil:manage-problem` | 55032 | 699 | ~14000 |
| `/wr-itil:work-problems` | 39265 | 388 | ~9800 |
| `/wr-retrospective:run-retro` | 36292 | 290 | ~9100 |
| `/wr-itil:report-upstream` | 21489 | 360 | ~5400 |
| `/wr-itil:manage-incident` | 19845 | 302 | ~5000 |
| `/wr-itil:review-problems` | 16566 | 197 | ~4100 |
| `/wr-itil:mitigate-incident` | 14255 | 211 | ~3600 |
| `/wr-itil:restore-incident` | 13362 | 195 | ~3300 |
| `/wr-itil:close-incident` | 12198 | 181 | ~3000 |
| `/wr-itil:work-problem` | 12407 | 130 | ~3100 |

**Windyroad SKILL.md total: 360,686 bytes / ~90k tokens across 46 skills.** Direct observation from this session: invoking `/wr-itil:work-problem` followed by `/wr-itil:manage-problem` loaded ~67KB / ~17k tokens of SKILL.md content. Two skill invocations = ~8% of the 200K context window spent on skill reference material.

Also in scope: the local `.claude/skills/install-updates/SKILL.md` at 13524 bytes / 238 lines — project-local, directly editable here.

## Symptoms

- Invoking any governance skill (especially the ITIL ones) adds thousands of tokens to the conversation before the skill does any work.
- Sessions that invoke multiple skills back-to-back (common in problem work, incident management, retrospectives) burn context on SKILL.md bodies that mostly re-state policy the assistant already knows.
- The largest SKILL.md files (manage-problem, work-problems, run-retro) are the ones most commonly invoked during AFK loops — the cost compounds.

## Workaround

None for end-users. Design-space mitigations:

1. **Runtime-steps vs reference-material split**: each SKILL.md becomes a lean runtime file that carries only the step-by-step instructions needed to execute the skill. Policy, rationale, ADR cross-refs, worked examples, deprecation notices, and historical decisions move to a sibling `REFERENCE.md` (or per-topic files in a `docs/` subdir). The runtime-loaded SKILL.md links to the reference file; Claude reads it on-demand via the Read tool only when the situation needs that context.
2. **Aggressive trimming**: many of the longest blocks in large SKILL.md files are duplicated narrative (e.g. manage-problem's deprecated-argument-forwarders section repeats the same four-forwarder protocol four times, once per subcommand). Collapse duplicated structure using templates, tables, or a single parameterised description.
3. **Skill splitting (already started via P071)**: the P071 phased split of `manage-problem` into dedicated skills (`list-problems`, `review-problems`, `work-problem`, `transition-problem`) started this work. Continuing the split reduces any one skill's runtime footprint. Candidate for further split: `manage-problem` itself still carries all four forwarder blocks + all lifecycle transition logic; could narrow to "create + update only" with transitions fully delegated.

All three are plugin-controllable — no Claude Code runtime support is required. The "lazy-load REFERENCE.md on demand" pattern works today: the skill invocation loads the lean SKILL.md, and the skill's runtime steps include a `Read` of REFERENCE.md only when the situation matches. Today this is manual; tomorrow this is the standard pattern.

## Impact Assessment

- **Who is affected**: Every user invoking any windyroad governance skill. Highest impact: AFK orchestrator loops (`work-problems`, `run-retro`) that fire multiple big skills per iteration.
- **Frequency**: Every skill invocation.
- **Severity**: High on the ITIL skills (manage-problem is the biggest single-file context consumer in the plugin set). Moderate elsewhere.
- **Analytics**: Measurement harness from P091 meta. Can also count skill-invocation frequency across a representative AFK log.

## Root Cause Analysis

### Confirmed on magnitude (2026-04-22 audit — see Description table)

SKILL.md files are large. The measurement is direct.

### Hypothesised on fix path (needs design validation)

The design question is whether `REFERENCE.md` lazy-loading (runtime SKILL.md stays lean, reference material lives elsewhere and is Read on demand) actually preserves skill behaviour. Two risks:

1. **Assistant may not know when to consult REFERENCE.md.** The lean SKILL.md must explicitly flag which situations require reading the reference. If it doesn't, the assistant will try to execute without the context and miss edge cases the full SKILL.md used to carry inline.
2. **Some narrative in the current SKILL.md is essential at every invocation, not optional context.** For example, the "Staging trap (P057)" warning in manage-problem Step 7 is safety-critical — it must fire on every transition, not live behind a Read. Separating "must-always-see" from "read-if-situation-applies" is a judgement call per skill.

### Investigation tasks

- [ ] Pick the top-three offenders (manage-problem, work-problems, run-retro) and line-audit each SKILL.md: tag every section as `[runtime]` (must stay inline), `[reference]` (can move to REFERENCE.md), or `[deprecated]` (can be deleted entirely).
- [ ] Measure the runtime-footprint reduction for each of the three after the split. Target: ≥50% byte reduction per file without losing any `[runtime]`-tagged content.
- [ ] Build a prototype split for manage-problem. Validate that all existing bats contract tests still pass and a real `/wr-itil:manage-problem 091 known-error` flow still works end-to-end.
- [ ] Draft or extend ADR: either a new "SKILL.md runtime budget policy" ADR, or a section in the "Hook injection budget policy" ADR (P091 anchor) covering the same principles for skill content.
- [ ] Apply the same line-audit + split to `.claude/skills/install-updates/SKILL.md` (project-local, ~13.5KB).
- [ ] Roll out the split pattern across the remaining top-10 SKILL.md files.

## Fix Strategy

**Phase 1 (audit + design validation)**: line-tag manage-problem; build a prototype split; confirm contract tests pass.

**Phase 2 (top-3 rollout)**: split manage-problem, work-problems, run-retro. Measure byte reduction.

**Phase 3 (full rollout)**: apply the pattern across the remaining top-10. Project-local `install-updates` gets the same treatment.

**Phase 4 (ADR)**: codify the `[runtime]`/`[reference]`/`[deprecated]` tagging convention and the REFERENCE.md pattern.

## Related

- **P091 (Session-wide context budget — meta)** — parent.
- **P095 (UserPromptSubmit hook injection)** — sibling; different surface but same "verbose prose by default" design flaw.
- **P096 (PreToolUse/PostToolUse hook injection)** — sibling.
- **P071 (Argument-based skill subcommands are not discoverable)** — P071's phased split already reduced manage-problem's size by extracting subcommands into dedicated skills. This ticket continues that trimming pressure.
- **P098 (Project-owned context contributors — global CLAUDE.md, local skills, memory)** — sibling covering non-plugin surfaces. Project-local `install-updates` SKILL.md sits at the boundary — included in P097's Phase 3 because the fix pattern is the same as other windyroad SKILL.md files.
- **ADR anchor**: "Hook injection budget policy" OR a dedicated "SKILL.md runtime budget policy" (TBD during Phase 4).
