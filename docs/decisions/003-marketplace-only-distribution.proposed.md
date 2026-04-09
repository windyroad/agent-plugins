---
status: "proposed"
date: 2026-04-09
decision-makers: [Tom Howard]
consulted: [Claude Code plugin docs, anthropics/claude-code#35641]
informed: [Windy Road plugin users]
supersedes: [001-unified-install-via-npm-package]
reassessment-date: 2026-07-09
---

# Marketplace-Only Distribution

## Context and Problem Statement

ADR-001 introduced an npm package (`@windyroad/agent-plugins`) that orchestrated two separate install mechanisms: the Claude Code marketplace for agents/hooks, and the `skills` npm package for skill autocomplete. This dual-install workaround existed because of anthropics/claude-code#35641 — marketplace-installed plugins didn't register skills in autocomplete.

As of 2026-04-09, this bug is confirmed fixed. Marketplace plugins now register skills in autocomplete without any additional install step. The `npx skills add` workaround is no longer necessary.

## Decision Drivers

- **Bug is fixed**: Skills from marketplace plugins now appear in `/` autocomplete (verified by removing all skills package artifacts and confirming marketplace skills still show)
- **Simpler install**: One mechanism (marketplace) instead of two (marketplace + skills package) reduces failure modes and user confusion
- **Fewer dependencies**: No need for the `skills` npm package as a runtime dependency of the install process
- **Cross-tool note**: The skills package installed to 45 agents (Codex, Cursor, Cline, etc.) via universal/symlink. Marketplace-only distribution is Claude Code specific. This trade-off is acceptable because the plugins' hooks and agents are Claude Code specific anyway.

## Considered Options

### Option 1: Marketplace-Only Distribution

Remove the `npx skills add` step from the installer. The marketplace handles agents, hooks, and skills. The installer becomes:
1. `claude plugin marketplace add windyroad/agent-plugins`
2. `claude plugin install <plugin>@windyroad` (for each plugin)

### Option 2: Keep Dual Distribution for Backward Compatibility

Keep the `npx skills add` step alongside marketplace install. Users on older Claude Code versions that still have the bug would continue to get skill autocomplete.

## Decision Outcome

**Chosen option: Option 1 — Marketplace-Only Distribution**

The bug fix eliminates the only reason for dual distribution. Keeping the skills package step adds complexity with no benefit for current Claude Code versions. Users on older versions can still install skills manually if needed.

## Consequences

### Good

- Installer is simpler — two steps instead of three
- No dependency on the `skills` npm package
- No duplicate skill entries in autocomplete
- No `.agents/`, `.claude/skills/`, or other symlink directories created in the project
- Cleaner `.gitignore` (most entries were for skills package artifacts)

### Neutral

- Users on older Claude Code versions (before the bug fix) won't get skill autocomplete from the installer. They can run `npx skills add --yes --all windyroad/agent-plugins` manually.
- The per-plugin packages (`@windyroad/architect`, etc.) still exist and work — they just do less (no skills step)

### Bad

- Loses cross-tool distribution (skills package installed to Codex, Cursor, Cline, etc.). This is acceptable because the plugins' hooks and agents are Claude Code specific.

## Confirmation

- Running `npx @windyroad/agent-plugins` installs all 10 plugins
- After install, `/wr:` autocomplete shows all skills (from marketplace, not skills package)
- No `.agents/`, `.claude/skills/`, or `skills-lock.json` created in the project
- `claude plugin list` shows all 10 plugins (single entry each, not duplicated)

## Pros and Cons of the Options

### Option 1: Marketplace-Only Distribution

- Good: Simpler installer, fewer failure modes
- Good: No duplicate autocomplete entries
- Good: No skills package dependency
- Bad: Loses cross-tool distribution to non-Claude-Code agents
- Bad: Users on very old Claude Code versions lose skill autocomplete

### Option 2: Keep Dual Distribution

- Good: Backward compatible with older Claude Code versions
- Good: Cross-tool distribution to Codex, Cursor, Cline, etc.
- Bad: Duplicate autocomplete entries for every skill
- Bad: More complex installer, more failure modes
- Bad: Maintains dependency on third-party `skills` package
- Bad: Creates many symlink directories in the project

## Reassessment Criteria

- **Cross-tool demand**: If significant demand emerges for non-Claude-Code agent support (Codex, Cursor, etc.), consider reintroducing the skills package step as an opt-in flag (`--with-skills`).
- **Marketplace regression**: If a future Claude Code update breaks skill autocomplete from marketplace plugins, revert to dual distribution.
