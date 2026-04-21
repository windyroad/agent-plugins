# Problem 098: Project-owned and user-owned context contributors — global `~/CLAUDE.md`, local `.claude/skills/`, and memory index

**Status**: Verification Pending
**Reported**: 2026-04-22
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: M
**WSJF**: 0 (Verification Pending — excluded from ranking per ADR-022)

> Split from P091 meta (session-wide context budget) on 2026-04-22 after user direction: "you can fix THIS project itself if there is wasteful context usage". This ticket owns the non-plugin-source surfaces that are nonetheless within this repo's editable reach.

## Fix Released

Released 2026-04-22 in the same commit as the Known Error → Verification Pending transition. Awaiting user verification.

In-repo portions of the fix:

- **Created `CLAUDE.md` at repo root** (24 lines) — progressive-disclosure pointer file. Points to `docs/decisions/`, `docs/jtbd/`, `RISK-POLICY.md`, `docs/problems/README.md`, `docs/BRIEFING.md`, `docs/STYLE-GUIDE.md`, `docs/VOICE-AND-TONE.md`, `docs/PRODUCT_DISCOVERY.md`. Explicitly notes this is a plugin-dev project (not web UI) so accessibility-first global guidance does not apply. Includes the Windy Road positioning statement ("promote Windy Road's service offering... NOT internal project utilities") migrated from the deleted `project_state.md` memory.
- **Split `.claude/skills/install-updates/SKILL.md`** (238 lines / 13.5KB → 149 lines / 6.8KB) — runtime steps remain; moved rationale, ADR-030 Confirmation amendment detail, consent-gate shape explanation, edge cases, scope exclusions, and full ADR cross-references to sibling `REFERENCE.md` (93 lines / 6.8KB). SKILL.md references REFERENCE.md anchors on demand. Reference implementation of the progressive-disclosure pattern P097 is expected to generalise (see `docs/BRIEFING.md` "What You Need to Know" entry 2026-04-22 for the pattern contract).
- **Deleted stale memory files**: `project_state.md` (12 days old — listed renamed skill names like `/wr:problem`, `/wr:adr`; most content duplicated filesystem/git state which auto-memory rules exclude) and `project_jtbd_migration.md` (7 days old — migration complete: `docs/jtbd/` exists in this repo). Updated `MEMORY.md` index.
- **Added BRIEFING note** documenting the SKILL+REFERENCE progressive-disclosure pattern as an implementation example, with a pointer to the P097 ADR that should formally codify it.

Out-of-repo portion (user action remaining):

- **`~/CLAUDE.md`** (98 lines / 1540 tokens, loads every session) — not edited. The file has `<!-- accessibility-agents: start/end -->` markers suggesting plugin-managed content; trimming may be clobbered on next install. See the Follow-up section below for recommended user action.

**Verification**:
- Project `CLAUDE.md` should load at session start on next fresh session and replace/supplement the global file.
- `/install-updates` should still run without error; REFERENCE.md loads only when SKILL.md pointers invite it.
- The two deleted memory files should not reappear; `MEMORY.md` index shows 7 remaining entries.

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
- [x] Decide whether a project-level `CLAUDE.md` is warranted in this repo; if yes, draft it lean (2026-04-22 — created with progressive-disclosure pointers to `docs/decisions/`, `docs/jtbd/`, `RISK-POLICY.md`, `docs/problems/README.md`, `docs/BRIEFING.md`, `docs/STYLE-GUIDE.md`, `docs/VOICE-AND-TONE.md`, `docs/PRODUCT_DISCOVERY.md`)
- [x] Apply P097-style trimming to `.claude/skills/install-updates/SKILL.md` — move detail to a sibling REFERENCE file; keep runtime steps lean (2026-04-22 — SKILL.md 238 → 149 lines / 13.5KB → 6.8KB; REFERENCE.md 93 lines / 6.8KB carries rationale, edge cases, ADR-030 amendment, non-interactive fallback, scope exclusions)
- [x] Audit current MEMORY.md index entries: which are still load-bearing; prune stale ones; tighten descriptions so Claude can decide relevance without reading (2026-04-22 — deleted `project_state.md` (duplicates filesystem/git state per auto-memory rules, listed skill names that were renamed) and `project_jtbd_migration.md` (migration complete — `docs/jtbd/` exists); remaining 7 feedback entries verified load-bearing)
- [ ] **User-owned surface**: trim `~/CLAUDE.md`. See Follow-up below.
- [ ] P097 generalisation — author sibling ADR naming a per-SKILL.md byte budget (discoverable via ADR-023 `performance-budget-*` glob); this ticket's `install-updates` split is the reference implementation.

## Fix Strategy

**Progressive disclosure** is the unifying principle (per user direction 2026-04-22):

- Global `~/CLAUDE.md` carries only the universal directive and pointers to detail. Web-UI-specific policy lives in web project CLAUDE.md files. Plugin-dev-specific policy lives here if needed. Claude reads the right project-level file from the current working directory on a per-project basis — the global stays tiny.
- Project-level CLAUDE.md (if added here) carries top-level pointers: "Architecture: see `docs/decisions/`. Personas: see `docs/jtbd/`. Risk policy: see `RISK-POLICY.md`. Problem backlog: see `docs/problems/README.md`." Claude reads the pointed files when the task actually needs them.
- `.claude/skills/install-updates/SKILL.md` becomes a runtime-steps-only file linking to a sibling REFERENCE.md with policy / ADR-030 rationale / troubleshooting. Same pattern P097 introduces across windyroad plugins.
- MEMORY.md entries: each line carries a focused description so Claude can skip loading irrelevant memory files. Prune stale entries quarterly (or whenever `/wr-retrospective:run-retro` surfaces a memory that's no longer useful).

The ADR anchor from P091 ("Progressive disclosure for governance tooling context") covers this ticket's conventions too — particularly the project-level CLAUDE.md pointer pattern.

## Follow-up — user-owned `~/CLAUDE.md` (out of repo)

The global `~/CLAUDE.md` (98 lines / 6163 bytes / ~1540 tokens) is outside this repo's working tree and carries an accessibility-agents web-UI preamble (wrapped in `<!-- accessibility-agents: start/end -->` markers suggesting plugin-managed content). For this plugin-development project, the entire block is irrelevant — and it loads on every Claude Code session regardless of project type.

**Recommended user action** (no repo commit involved):

1. Verify whether the accessibility-agents plugin actively rewrites the `<!-- accessibility-agents -->` block on install/update. If yes, manual trim would be clobbered — uninstall or scope-configure the plugin instead.
2. If the block is static (user-pasted, not plugin-managed), trim `~/CLAUDE.md` to ≤20 lines of genuinely universal guidance. Move project-type-specific content to project-level `CLAUDE.md` files in the repos where it applies. Example starting point — a near-empty global file with "See project CLAUDE.md for project-specific guidance."

**Why this matters** (per JTBD-001 and JTBD-003): the global file loads on every session across every project. 1540 tokens × every session is a persistent overhead cost that violates JTBD-001 "without the overhead", and carrying non-applicable web-UI guidance on plugin-dev projects violates JTBD-003 "my session isn't cluttered with guardrails that don't apply".

This bullet stays on the ticket as a user-facing action alongside the in-repo fix verification. Close this ticket only after the user confirms both: (a) the in-repo portions work (project `CLAUDE.md` present and useful, `install-updates` skill still runs correctly, memory audit did not lose load-bearing content), AND (b) `~/CLAUDE.md` has been trimmed or the overhead has been accepted as unavoidable.

## Related

- **P091 (Session-wide context budget — meta)** — parent meta ticket.
- **P095 (UserPromptSubmit hook injection)** — sibling cluster (plugin-owned hooks); now `.verifying.md`.
- **P096 (PreToolUse/PostToolUse hook injection)** — sibling cluster (plugin-owned hooks); Open.
- **P097 (SKILL.md runtime size)** — sibling cluster (plugin-owned skills); Open. This ticket's `install-updates` split is the reference implementation of the pattern P097 will generalise. Before generalisation, P097 should author its own ADR naming a byte budget per SKILL.md.
- **ADR-030** — repo-local skills convention; the `install-updates` split stays within its scope.
- **ADR-038** — progressive disclosure for governance tooling context; the pattern anchor this ticket applies.
