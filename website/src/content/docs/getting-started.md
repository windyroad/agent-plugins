---
title: Install your first plugins
description: Install the Windy Road plugins relevant to your project and verify they are available.
---

You need a supported coding-agent runtime and Node.js with npm available in your
terminal. Installation commands download packages from npm; review the selected
package's documentation and maturity before using it.

## Choose a small set

For Claude Code, install selected plugins from your project directory:

```bash
npx @windyroad/agent-plugins --plugin architect tdd risk-scorer
```

Or install one plugin:

```bash
npx @windyroad/architect
```

To install the full Claude Code suite:

```bash
npx @windyroad/agent-plugins
```

The meta-installer defaults to project scope. Use `--scope user` when you want a
user-wide installation. Individual plugin defaults and supported runtimes are
described in their package documentation.

## Restart and verify

Restart Claude Code after installation. Open the skill picker and check that the
selected plugin's skills appear. For example:

```text
/wr-architect:review-design
```

Review the resulting instructions before asking the agent to change files.
Some plugins activate when they find project policy files, such as
`docs/decisions/` or `RISK-POLICY.md`; setup and enforcement behavior vary.

## Use Codex

The meta-installer command above installs for Claude Code. For Codex, follow
the [individual-package runtime instructions](../runtimes/). A Codex plugin
manifest does not by itself establish the same behavior as Claude Code.

## Choose the next plugin

Return to [the plugin directory](../) to find a workflow relevant to your work.
The reference page links to each package's full documentation, dependencies and
configuration.
