# Problem 098: Project-owned and user-owned context contributors — global `~/CLAUDE.md`, local `.claude/skills/`, and memory index

**Status**: Open
**Reported**: 2026-04-22
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: M
**WSJF**: (12 × 1.0) / 2 = **6.0**

> Split from P091 meta (session-wide context budget) on 2026-04-22 after user direction: "you can fix THIS project itself if there is wasteful context usage". This ticket owns the non-plugin-source surfaces that are nonetheless within this repo's editable reach.

## Description

Context is consumed at session start not only by windyroad plugin output (P095/P096) or by windyroad SKILL.md files (P097), but also by files the user and project own directly:

1. **Global `~/CLAUDE.md`** (98 lines / 6163 bytes / ~1540 tokens) — loads on every Claude Code session regardless of project. Its current content is an accessibility-first preamble tailored to web UI work: agent decision matrix, 16-row commands table, non-negotiable standards. For a plugin-development project like this one (no web UI, no HTML/CSS/JSX), the entire block is irrelevant but still injected.
2. **Project-local `.claude/skills/install-updates/SKILL.md`** (238 lines / 13524 bytes / ~3400 tokens) — loads only when the skill is invoked. Follows the same verbose-prose pattern as the windyroad SKILL.md files P097 audits, but this one is stored in this repo's `.claude/` tree per ADR-030 (repo-local skill).
3. **Memory index injection** (`MEMORY.md` at 1786 bytes / ~450 tokens) — loads on every session. The index itself is small, but each *referenced* memory file balloons the footprint when read: the current 9 memory files total ~22KB / ~5500 tokens if all loaded. Per the auto-memory instructions, files should load only when relevant — but the rule is only as tight as the assistant's discipline.
4. **Project-level `CLAUDE.md`** (absent today) — if added, it would become a new context contributor. Worth calling out here so that future additions are lean by construction.

These surfaces are not published plugin source — they're user/project configuration — but they are fully editable from this repository's working tree (global `~/CLAUDE.md` is outside the repo but still the user's file). A plugin fix does not touch them; a targeted trim and a set of conventions does.

## Symptoms

- Session-start preamble includes the full global `~/CLAUDE.md` accessibility block even when the project is a plugin marketplace with no web UI.
- Invoking `/install-updates` pulls its 13.5KB SKILL.md into the turn.
- Memory files loaded ad-hoc during a session accumulate — no explicit eviction or summarisation.

## Workaround

None automatic. User-driven mitigations:

1. **Trim `~/CLAUDE.md`** — move project-type-specific content out of the global file. Keep the global file to truly-universal guidance (≤20 lines). Web-UI-specific content moves to a project-level `CLAUDE.md` in web repos; plugin-dev-specific content moves to a project-level file here (if one is warranted).
2. **Trim `.claude/skills/install-updates/SKILL.md`** — apply the same progressive-disclosure pattern from P097 (runtime steps inline; policy / rationale / examples in a sibling reference file read on demand).
3. **Memory index discipline** — audit `MEMORY.md` entries periodically; delete stale feedback/project memories; ensure descriptions are tight enough that Claude can decide when each file is relevant without reading all of them at once.

## Impact Assessment

- **Who is affected**: This user directly. Secondary: any downstream adopter who mirrors the global `CLAUDE.md` + `.claude/` conventions from this workspace.
- **Frequency**: Global `CLAUDE.md` and `MEMORY.md` load every session; install-updates SKILL.md loads on every invocation of that skill (common at end-of-release).
- **Severity**: Moderate. Smaller per-unit cost than P095/P097 but directly tractable and part of the full session-wide budget P091 cares about.
- **Analytics**: Measurement harness from P091 meta.

## Root Cause Analysis

### Confirmed (2026-04-22 audit)

- Global `~/CLAUDE.md` is 98 lines, most accessibility-focused, loaded on every session.
- Project-level `CLAUDE.md` absent (no conflict today).
- `.claude/skills/install-updates/SKILL.md` is 238 lines / 13.5KB — confirms the P097 pattern applies to project-local skills too.
- MEMORY.md index is small (1786 bytes) but the 9 referenced memory files total ~22KB — loads ad-hoc during a session.

### Investigation tasks

- [x] Measure the four contributors (2026-04-22 audit)
- [ ] Line-tag `~/CLAUDE.md`: which sections are universal vs web-UI-specific vs plugin-dev-specific
- [ ] Propose a trimmed `~/CLAUDE.md` (≤20 lines, universal only)
- [ ] Decide whether a project-level `CLAUDE.md` is warranted in this repo; if yes, draft it lean (progressive disclosure — pointers to `docs/decisions/`, `docs/jtbd/`, etc. rather than re-stating policy inline)
- [ ] Apply P097-style trimming to `.claude/skills/install-updates/SKILL.md` — move detail to a sibling REFERENCE file; keep runtime steps lean
- [ ] Audit current MEMORY.md index entries: which are still load-bearing; prune stale ones; tighten descriptions so Claude can decide relevance without reading
- [ ] Confirm the memory-file loading discipline in the auto-memory instructions is actually applied in practice (informal audit of recent sessions)

## Fix Strategy

**Progressive disclosure** is the unifying principle (per user direction 2026-04-22):

- Global `~/CLAUDE.md` carries only the universal directive and pointers to detail. Web-UI-specific policy lives in web project CLAUDE.md files. Plugin-dev-specific policy lives here if needed. Claude reads the right project-level file from the current working directory on a per-project basis — the global stays tiny.
- Project-level CLAUDE.md (if added here) carries top-level pointers: "Architecture: see `docs/decisions/`. Personas: see `docs/jtbd/`. Risk policy: see `RISK-POLICY.md`. Problem backlog: see `docs/problems/README.md`." Claude reads the pointed files when the task actually needs them.
- `.claude/skills/install-updates/SKILL.md` becomes a runtime-steps-only file linking to a sibling REFERENCE.md with policy / ADR-030 rationale / troubleshooting. Same pattern P097 introduces across windyroad plugins.
- MEMORY.md entries: each line carries a focused description so Claude can skip loading irrelevant memory files. Prune stale entries quarterly (or whenever `/wr-retrospective:run-retro` surfaces a memory that's no longer useful).

The ADR anchor from P091 ("Progressive disclosure for governance tooling context") covers this ticket's conventions too — particularly the project-level CLAUDE.md pointer pattern.

## Related

- **P091 (Session-wide context budget — meta)** — parent meta ticket.
- **P095 (UserPromptSubmit hook injection)** — sibling cluster (plugin-owned hooks).
- **P096 (PreToolUse/PostToolUse hook injection)** — sibling cluster (plugin-owned hooks).
- **P097 (SKILL.md runtime size)** — sibling cluster (plugin-owned skills); the trimming pattern this ticket applies to `install-updates` is the same pattern P097 introduces.
- **ADR-030** (if present) — local skills convention; the `install-updates` trimming must stay within its scope rules.
- **ADR anchor**: "Progressive disclosure for governance tooling context" (tracked on P091).
