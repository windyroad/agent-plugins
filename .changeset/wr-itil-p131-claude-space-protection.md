---
"@windyroad/itil": minor
---

P131 Phase 2 — `.claude/` user-space write protection. NEW `packages/itil/hooks/itil-claude-space-protection.sh` PreToolUse:Write|Edit hook denies agent writes to project-scoped `.claude/` paths NOT in the user-space allow-list, unless an approval marker is present. NEW shared helper `packages/itil/hooks/lib/claude-space-gate.sh` exporting `is_protected_claude_path` / `has_approval_marker` / `claude_space_deny`.

Why: `.claude/` is user-controlled config space (settings, memory, MCP servers, user-authored skills/hooks/commands/agents, Claude Code's own state in `projects/` and `worktrees/`). Agents misread the architect/JTBD/TDD/style-guide/voice-tone/risk-scorer gate-exclusion lists as "approved write zones" and write project-generated content (plans, audits, scratch state) under `.claude/`, polluting user space. Project-generated content belongs in `docs/` (plans, audits) or inline in problem-ticket bodies.

Allow-list (project-relative): `.claude/{settings.json, settings.local.json, MEMORY.md, .install-updates-consent, scheduled_tasks.lock}` + `.claude/{skills, commands, agents, hooks, projects, worktrees}/*` subtrees + `.claude/*.local.json` (root-depth only) + `.claude/.agent-write-approved-*` markers themselves.

Approval-marker bypass: user creates `.claude/.agent-write-approved-<sha256-of-rel-path>` to pre-authorize specific paths. Persistent (no TTL); user creates once per path. Distinct semantic class from ADR-009 session-scoped /tmp markers — this is a persistent path-keyed approval-marker class, precedent-shaped on `.claude/.install-updates-consent` (ADR-030 / P120).

Out of scope (unaffected): Read|Glob|Grep on `.claude/` paths, paths outside `$PWD` project root (~/.claude/, other repos' .claude/), `.claude/` subtree edits hitting allow-listed paths.

Deny message: ~440 bytes (under ADR-038 progressive-disclosure 500-byte cap), names P131 + suggests `docs/plans/` / `docs/audits/` / inline-ticket alternatives + names approval-marker bypass + references project CLAUDE.md MANDATORY rule. Silent on allow path per ADR-045 Pattern 1. Fail-open on parse error per ADR-013 Rule 6.

Files shipped:
- `packages/itil/hooks/itil-claude-space-protection.sh` — NEW PreToolUse:Write|Edit hook.
- `packages/itil/hooks/lib/claude-space-gate.sh` — NEW shared helper.
- `packages/itil/hooks/hooks.json` — registers the new hook.
- `packages/itil/hooks/test/itil-claude-space-protection.bats` — NEW 34 behavioural assertions per ADR-037 + P081 covering deny path, allow-list, outside-.claude paths, approval-marker bypass, Read|Glob|Bash unaffected, allow-list anchor depth, deny-message contract, byte budget, silent-on-pass.
- `docs/problems/131-...known-error.md` → `.verifying.md` — Status flip + Phase 2 shipped section per ADR-022 fold-fix convention.
- `docs/problems/README.md` — WSJF Rankings + Verification Queue refresh per P062.

Architect: PASS-WITH-NOTES — allow-list amended to add `MEMORY.md`, `commands/`, `agents/`, `hooks/` subtrees + anchor `*.local.json` to root depth; ADR formalising user-space-vs-project-space distinction deferred to Phase 3 per ticket Fix Strategy line 113; marker format consistent with ADR-009 (new persistent semantic class, not conflict).
JTBD: ALIGNED PASS — JTBD-001 primary (governance without breaking user editing flows; allow-list preserves "no manual policing"); JTBD-006 strong fit (originating P131 incident was AFK orchestrator writing `.claude/plans/p081-...md`; Phase 2 prevents recurrence); JTBD-101 no conflict; JTBD-202 indirect.
Voice-tone: PASS advisory-only (`docs/VOICE-AND-TONE.md` not yet authored).
Style-guide: PASS out-of-scope.
TDD: 34/34 new bats green; full 129-test itil hooks suite green (no regression).

Phase 3 remaining (deferred): formalising-ADR; doc-reframe in remaining 4 gate-hook prose surfaces (tdd, style-guide, voice-tone, risk-scorer); `docs/briefing/hooks-and-gates.md` topic file update.
