# Windy Road Agent Plugins

AI agent plugins for architecture governance, risk management, TDD enforcement, and delivery quality by [Windy Road Technology](https://windyroad.com.au).

## Install

Install everything with one command:

```bash
npx @windyroad/agent-plugins
```

Or install only what you need:

```bash
npx @windyroad/agent-plugins --plugin architect tdd risk-scorer
```

Or install individual packages directly:

```bash
npx @windyroad/architect
npx @windyroad/c4
```

Restart Claude Code after installing. Type `/wr-` to see all available skills.

## Packages

### Governance and Quality Gates

These plugins enforce review workflows via hooks. They block edits to relevant files until the appropriate review agent has been consulted.

| Package | Plugin | Agent | Skills | What it enforces |
|---------|--------|-------|--------|-----------------|
| `@windyroad/architect` | wr-architect | `wr-architect:agent` | `/wr-architect:create-adr` | Architecture decisions reviewed before code changes |
| `@windyroad/risk-scorer` | wr-risk-scorer | `wr-risk-scorer:agent` + 4 variants | `/wr-risk-scorer:update-policy` | Pipeline risk scoring, commit/push gates, secret leak detection |
| `@windyroad/voice-tone` | wr-voice-tone | `wr-voice-tone:agent` | `/wr-voice-tone:update-guide` | User-facing copy reviewed against voice and tone guide |
| `@windyroad/style-guide` | wr-style-guide | `wr-style-guide:agent` | `/wr-style-guide:update-guide` | CSS and UI components reviewed against style guide |
| `@windyroad/jtbd` | wr-jtbd | `wr-jtbd:agent` | `/wr-jtbd:update-guide` | UI changes reviewed against jobs-to-be-done document |
| `@windyroad/tdd` | wr-tdd | | `/wr-tdd:setup-tests` | Red-Green-Refactor TDD cycle enforced for implementation code |

When a policy file is missing (e.g., no `docs/VOICE-AND-TONE.md`), the hooks block edits and direct you to the update-guide skill to generate one.

### Process Tools

| Package | Plugin | Skills | What it does |
|---------|--------|--------|-------------|
| `@windyroad/problem` | wr-problem | `/wr-problem:update-ticket` | ITIL-aligned problem management with WSJF prioritisation |
| `@windyroad/retrospective` | wr-retrospective | `/wr-retrospective:run-retro` | Session retrospectives that update briefings and create problem tickets |

### Diagram Generation

| Package | Plugin | Skills | What it does |
|---------|--------|--------|-------------|
| `@windyroad/c4` | wr-c4 | `/wr-c4:generate`, `/wr-c4:check` | C4 architecture diagram generation and validation |
| `@windyroad/wardley` | wr-wardley | `/wr-wardley:generate` | Wardley Map generation |

## Dependencies

Some plugins depend on others:

- **@windyroad/problem** requires: @windyroad/risk-scorer
- **@windyroad/retrospective** requires: @windyroad/problem, @windyroad/risk-scorer

The installer warns if dependencies are missing.

## Updating

```bash
# Update everything
npx @windyroad/agent-plugins --update

# Update a single package
npx @windyroad/architect --update
```

## Uninstalling

```bash
# Remove everything
npx @windyroad/agent-plugins --uninstall

# Remove a single plugin
npx @windyroad/architect --uninstall
```

## Development

For plugin development, use `--plugin-dir` to load directly from source:

```bash
claude --plugin-dir ~/Projects/windyroad-agent-plugins/packages/architect
```

Or load all plugins at once:

```bash
./claude-wr.sh
```

Changes take effect on session restart (no install/update needed).

## Monorepo Structure

```
packages/
  agent-plugins/    @windyroad/agent-plugins (meta-installer)
  architect/        @windyroad/architect
  risk-scorer/      @windyroad/risk-scorer
  tdd/              @windyroad/tdd
  voice-tone/       @windyroad/voice-tone
  style-guide/      @windyroad/style-guide
  jtbd/             @windyroad/jtbd
  problem/          @windyroad/problem
  retrospective/    @windyroad/retrospective
  c4/               @windyroad/c4
  wardley/          @windyroad/wardley
  shared/           Shared install utilities
```
