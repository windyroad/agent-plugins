---
title: Claude Code and Codex
description: Choose the correct installation and invocation path for your coding-agent runtime.
---

Claude Code remains the default runtime. Codex support is documented per package;
do not assume that installing a plugin in one runtime makes it available in the
other, or that a manifest proves equivalent behavior.

## Claude Code

Run the selected package's installer, then restart Claude Code:

```bash
npx @windyroad/itil
```

Invoke a skill by its slash command:

```text
/wr-itil:outcome-led-planning
```

## Codex

The ITIL package supports an explicit Codex installation:

```bash
npx @windyroad/itil --runtime codex --scope user
```

Restart Codex and check its installed plugin and skill lists. Select the skill
name exposed by that installation. The outcome-led planning invocation is:

```text
$wr-itil:outcome-led-planning
```

For a package that documents both-runtime installation, `--runtime both` selects
both. This is an individual-package option; the current suite meta-installer
does not offer that runtime selection.

## Install required reviewers

Outcome-led planning requires architecture, JTBD and risk assessment. Installing
ITIL alone does not supply all three review roles. Install the relevant plugins
for the runtime you will use, following each package's documentation:

- [Architecture review](../plugins/architect/).
- [JTBD review](../plugins/jtbd/).
- [Risk assessment](../plugins/risk-scorer/).

The ITIL installer also declares a risk-scorer dependency. Check installer
warnings and verify the required reviewers are available before starting work.

## Understand evidence limits

An installation can register a skill without proving its later behavior. A
working skill command does not establish every hook or cross-plugin workflow.
Read package-specific support statements and verify the journey you depend on.
