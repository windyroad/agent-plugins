# Windy Road Agent Plugins

**Governance guardrails for AI coding agents.** Architecture reviews, risk scoring, TDD enforcement, and delivery quality gates that run automatically inside [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Built by [Windy Road Technology](https://windyroad.com.au).

## The Problem

AI coding agents are fast. Sometimes too fast. They skip architecture reviews, introduce risk without assessment, ignore your design system, and write implementation before tests. The same governance that keeps human teams shipping safely gets bypassed when an agent writes code.

These plugins bring that governance back -- automatically. They hook into Claude Code's plugin system and enforce your team's standards on every edit, commit, and push. No manual checks. No hoping the agent remembers.

## Quick Start

Install all plugins with one command:

```bash
npx @windyroad/agent-plugins
```

Restart Claude Code. That's it. The plugins activate automatically based on what they find in your project.

**Install only what you need:**

```bash
npx @windyroad/agent-plugins --plugin architect tdd risk-scorer
```

**Or install a single plugin directly:**

```bash
npx @windyroad/architect
```

> Plugins install to your project by default (not globally), so they won't affect your other projects. Pass `--scope user` to install globally.

After installing, type `/wr-` in Claude Code to see all available skills.

## How It Works

Each plugin uses Claude Code's hook system to intercept actions at the right moment:

1. **Detect** -- A `UserPromptSubmit` hook scans for relevant project files (e.g., `docs/decisions/` for architect, `RISK-POLICY.md` for risk-scorer)
2. **Gate** -- A `PreToolUse` hook blocks edits to relevant files until the review agent has been consulted
3. **Review** -- The agent reviews the proposed change against your project's policy documents
4. **Unlock** -- A `PostToolUse` hook marks the review as complete, allowing edits to proceed

Policy files are generated for you. When a plugin detects that its policy file is missing, it blocks edits and directs you to the setup skill (e.g., `/wr-voice-tone:update-guide`).

## Plugins

### Governance and Quality Gates

These plugins enforce review workflows. They block edits to relevant files until the appropriate review agent has been consulted.

| Package | What it enforces |
|---------|-----------------|
| [`@windyroad/architect`](packages/architect/) | Architecture decisions reviewed before code changes |
| [`@windyroad/risk-scorer`](packages/risk-scorer/) | Pipeline risk scoring, commit/push gates, secret leak detection |
| [`@windyroad/tdd`](packages/tdd/) | Red-Green-Refactor TDD cycle for implementation code |
| [`@windyroad/voice-tone`](packages/voice-tone/) | User-facing copy reviewed against voice and tone guide |
| [`@windyroad/style-guide`](packages/style-guide/) | CSS and UI components reviewed against style guide |
| [`@windyroad/jtbd`](packages/jtbd/) | UI changes reviewed against jobs-to-be-done document |

### Process Tools

| Package | What it does |
|---------|-------------|
| [`@windyroad/problem`](packages/problem/) | ITIL-aligned problem management with WSJF prioritisation |
| [`@windyroad/retrospective`](packages/retrospective/) | Session retrospectives that update briefings and create problem tickets |

### Diagram Generation

| Package | What it does |
|---------|-------------|
| [`@windyroad/c4`](packages/c4/) | C4 architecture diagram generation and validation |
| [`@windyroad/wardley`](packages/wardley/) | Wardley Map generation from source code analysis |

### Meta-Installer

| Package | What it does |
|---------|-------------|
| [`@windyroad/agent-plugins`](packages/agent-plugins/) | One-command installer for all plugins |

## Dependencies Between Plugins

Most plugins are standalone. Two have dependencies:

```
@windyroad/retrospective
  └── @windyroad/problem
        └── @windyroad/risk-scorer
```

The installer warns if dependencies are missing.

## Updating and Uninstalling

```bash
# Update everything
npx @windyroad/agent-plugins --update

# Update a single plugin
npx @windyroad/architect --update

# Remove everything
npx @windyroad/agent-plugins --uninstall

# Remove a single plugin
npx @windyroad/architect --uninstall
```

## Development

For plugin development, load directly from source with `--plugin-dir`:

```bash
claude --plugin-dir ~/Projects/windyroad-agent-plugins/packages/architect
```

Or load all plugins at once:

```bash
./claude-wr.sh
```

Changes take effect on session restart -- no install or update step needed.

### Running Tests

Hook tests use [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System):

```bash
npm test
```

### Releasing

This monorepo uses [Changesets](https://github.com/changesets/changesets) for versioning:

```bash
npx changeset        # Create a changeset
npm run release      # Publish to npm
npm run push:watch   # Push and watch CI
```

## Monorepo Structure

```
packages/
  agent-plugins/    Meta-installer for all plugins
  architect/        Architecture decision enforcement
  risk-scorer/      Pipeline risk scoring and gates
  tdd/              TDD state machine enforcement
  voice-tone/       Voice and tone review
  style-guide/      Style guide review
  jtbd/             Jobs-to-be-done review
  problem/          Problem management
  retrospective/    Session retrospectives
  c4/               C4 diagram generation
  wardley/          Wardley Map generation
  shared/           Shared install utilities (internal)
```

## Licence

[MIT](LICENSE)
