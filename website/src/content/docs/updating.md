---
title: Update or remove plugins
description: Keep installed plugins current through their supported installers.
---

Use the installer rather than changing files inside a runtime's plugin cache.
Restart the selected runtime after an update, then verify its plugin version and
skill list. An already-running chat may still have earlier instructions loaded.

## Update the Claude Code suite

```bash
npx @windyroad/agent-plugins --update
```

## Update an individual plugin

For Claude Code:

```bash
npx @windyroad/planning --update
```

For the planning Codex installation:

```bash
npx @windyroad/planning --runtime codex --scope user --update
```

Check the individual package's installer help for runtime and scope options.
The full GitHub coordination requirements use planning **0.3.0
or later**, or ITIL **3.3.0 or later** through its compatibility command. Follow
[GitHub planning and agent coordination](../outcome-led-planning/#choose-where-to-track-the-plan)
after updating.

The source version shown on this website identifies repository reference
material; it does not read your installed version or promise that every source
change is already published.

## Remove plugins

Remove the Claude Code suite:

```bash
npx @windyroad/agent-plugins --uninstall
```

Or remove an individual planning installation for the selected runtime:

```bash
npx @windyroad/planning --uninstall
npx @windyroad/planning --runtime codex --scope user --uninstall
```

Review the installer's output and restart the runtime. Uninstalling a plugin is
different from deleting the project documents it helped you create.
