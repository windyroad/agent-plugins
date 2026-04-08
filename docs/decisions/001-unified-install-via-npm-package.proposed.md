---
status: "proposed"
date: 2026-04-08
decision-makers: [Tom Howard]
consulted: [Claude Code plugin docs, skills package docs, anthropics/claude-code#35641]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-08
---

# Unified Install Experience via npm Package

## Context and Problem Statement

The Windy Road Claude Code plugin suite consists of 10 plugins (agents + hooks distributed via the Claude Code marketplace) and 10 skills (SKILL.md files distributed via the `skills` npm package). Users currently need two separate install commands:

```bash
# Command 1: marketplace plugins (agents + hooks)
claude plugin marketplace add windyroad/windyroad-claude-plugin
for p in wr-architect wr-risk-scorer wr-voice-tone wr-style-guide wr-jtbd wr-tdd wr-retrospective wr-problem wr-c4 wr-wardley; do
  claude plugin install "${p}@windyroad"
done

# Command 2: skills (SKILL.md files)
npx skills add --yes --all windyroad/windyroad-claude-plugin
```

This is a poor onboarding experience. Users must understand two distribution systems and run multiple commands to get a working setup.

## Decision Drivers

- **User experience**: A single install command is significantly easier to document, share, and support
- **Skill autocomplete is essential**: Skills must appear in `/` autocomplete for users to discover and use them. Without autocomplete, skills are effectively invisible.
- **Claude Code bug anthropics/claude-code#35641**: Skills bundled inside marketplace plugins do not appear in slash command autocomplete. This bug has been confirmed and is a showstopper for the "bundle skills in plugins" approach.
- **Two working distribution channels exist**: The marketplace handles agents/hooks well; the `skills` package handles skills well (with working autocomplete). Both are proven.
- **Future-proofing**: The solution should be easy to simplify once the Claude Code bug is fixed.

## Considered Options

### Option 1: npm Package with Installer Script

Publish an npm package (e.g., `@windyroad/claude-plugins`) whose `bin` entry orchestrates both install mechanisms in sequence:

1. `claude plugin marketplace add windyroad/windyroad-claude-plugin`
2. `claude plugin install` for each of the 10 plugins
3. `npx skills add --yes --all windyroad/windyroad-claude-plugin`

User runs: `npx @windyroad/claude-plugins`

### Option 2: Bundle Skills Inside Plugin Directories

Move each SKILL.md into its corresponding plugin's `skills/` directory. Claude Code's plugin system supports this natively. One `claude plugin install` gets everything.

User runs: `claude plugin install wr-architect@windyroad` (per plugin)

### Option 3: Shell Install Script

Host an `install.sh` in the repo that users download and run:

```bash
curl -sSL https://raw.githubusercontent.com/windyroad/windyroad-claude-plugin/main/install.sh | bash
```

### Option 4: `/wr:setup` Bootstrapper Skill

Users install skills first (one command), then run `/wr:setup` which programmatically installs all marketplace plugins.

## Decision Outcome

**Chosen option: Option 1 — npm Package with Installer Script**

This is the only option that:
- Delivers a true single-command experience
- Ensures skills appear in autocomplete (via the `skills` package path)
- Works around anthropics/claude-code#35641 without compromise
- Uses a familiar distribution mechanism (npm/npx)

## Consequences

### Good

- Single command install: `npx @windyroad/claude-plugins`
- Skills appear in autocomplete immediately
- Agents and hooks install via the proven marketplace path
- Easy to document and share
- When anthropics/claude-code#35641 is fixed, the package internals can be simplified (or the package can become a thin wrapper around `claude plugin install`) without changing the user-facing command

### Neutral

- Requires publishing and maintaining an npm package
- Adds npm as a dependency for installation (already required for `skills` package)

### Bad

- Two distribution systems still exist under the hood — this is a workaround, not a simplification
- Users who want to install individual plugins still need to understand both systems (or the package needs `--plugin` flags)
- Package must be updated when plugins are added or removed

## Confirmation

- Running `npx @windyroad/claude-plugins` installs all 10 plugins and all 10 skills
- After install, `/wr:` autocomplete shows all 10 skills
- After install, `claude plugin list` shows all 10 plugins
- The install is idempotent (safe to re-run)

## Pros and Cons of the Options

### Option 1: npm Package with Installer Script

- Good: True single-command experience
- Good: Skills autocomplete works (uses `skills` package)
- Good: Familiar npm/npx distribution
- Good: Future-proof — internals can change without changing user command
- Bad: Must publish and maintain an npm package
- Bad: Two distribution systems still exist under the hood

### Option 2: Bundle Skills Inside Plugin Directories

- Good: Uses Claude Code's native plugin system as intended
- Good: No additional package to maintain
- Good: Simplest architecture — one distribution mechanism
- Bad: **Skills do not appear in autocomplete** (anthropics/claude-code#35641) — showstopper
- Bad: Users cannot discover skills without reading documentation
- Neutral: Will become the correct approach once the bug is fixed

### Option 3: Shell Install Script

- Good: Single command (curl | bash)
- Good: No npm package to publish
- Bad: `curl | bash` is a security anti-pattern many users avoid
- Bad: No version management or update mechanism
- Bad: Platform-specific concerns (Windows compatibility)

### Option 4: `/wr:setup` Bootstrapper Skill

- Good: Self-documenting — the skill guides the user
- Bad: Still two conceptual steps (install skills, then run setup)
- Bad: Requires users to understand they need skills installed first
- Bad: Not truly a single command

## Reassessment Criteria

- **anthropics/claude-code#35641 is fixed**: If marketplace plugins begin registering skills in autocomplete, reassess whether Option 2 (bundle skills in plugins) should supersede this decision.
- **Claude Code adds a native "install all from marketplace" command**: If a single `claude plugin install-all@windyroad` becomes possible, the npm wrapper may become unnecessary.
- **Skills package adds post-install hooks**: If the `skills` package gains the ability to trigger plugin installation, the npm wrapper may be replaceable.
