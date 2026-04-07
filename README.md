# Windy Road Claude Code Plugins

Claude Code plugins for architecture governance, risk management, TDD enforcement, and delivery quality by [Windy Road Technology](https://windyroad.com.au).

## Install

Add the marketplace and install the plugins you need:

```bash
# Add the marketplace (once)
claude plugin marketplace add windyroad/windyroad-claude-plugin

# Install all plugins
for p in wr-architect wr-risk-scorer wr-voice-tone wr-style-guide wr-jtbd wr-tdd wr-retrospective wr-problem wr-c4 wr-wardley; do
  claude plugin install "${p}@windyroad"
done
```

Or install individually:

```bash
claude plugin install wr-architect@windyroad
```

## Plugins

### Governance and Quality Gates

These plugins enforce review workflows via hooks. They block edits to relevant files until the appropriate review agent has been consulted.

| Plugin | Agent | Skills | What it enforces |
|--------|-------|--------|-----------------|
| **wr-architect** | `wr-architect:agent` | | Architecture decisions reviewed before code changes |
| **wr-risk-scorer** | `wr-risk-scorer:agent` + 4 variants | `/wr-risk-scorer:policy` | Pipeline risk scoring, commit/push gates, secret leak detection |
| **wr-voice-tone** | `wr-voice-tone:agent` | `/wr-voice-tone:create` | User-facing copy reviewed against voice and tone guide |
| **wr-style-guide** | `wr-style-guide:agent` | `/wr-style-guide:create` | CSS and UI components reviewed against style guide |
| **wr-jtbd** | `wr-jtbd:agent` | `/wr-jtbd:create` | UI changes reviewed against jobs-to-be-done document |
| **wr-tdd** | | `/wr-tdd:create` | Red-Green-Refactor TDD cycle enforced for implementation code |

When a policy file is missing (e.g., no `docs/VOICE-AND-TONE.md`), the hooks block edits and direct you to the create skill to generate one.

### Process Tools

| Plugin | Skills | What it does |
|--------|--------|-------------|
| **wr-problem** | `/wr-problem:manage` | ITIL-aligned problem management with WSJF prioritisation |
| **wr-retrospective** | `/wr-retrospective:run` | Session retrospectives that update briefings and create problem tickets |

### Diagram Generation

| Plugin | Skills | What it does |
|--------|--------|-------------|
| **wr-c4** | `/wr-c4:create`, `/wr-c4:check` | C4 architecture diagram generation and validation |
| **wr-wardley** | `/wr-wardley:create` | Wardley Map generation |

## Dependencies

Some plugins depend on others:

- **wr-problem** requires: wr-risk-scorer
- **wr-retrospective** requires: wr-problem, wr-risk-scorer

A SessionStart hook warns if dependencies are missing.

## Updating

```bash
claude plugin marketplace update windyroad
```

Then reinstall any plugin that has been updated.

## Development

For plugin development, use `--plugin-dir` to load directly from source:

```bash
claude --plugin-dir ~/Projects/windyroad-claude-plugin/plugins/wr-architect
```

This loads from your local directory. Changes take effect on session restart (no install/update needed).
