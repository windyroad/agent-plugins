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
npx @windyroad/planning
```

Invoke a skill by its slash command:

```text
/wr-planning:outcome-led-planning
```

## Codex

The planning package supports an explicit Codex installation:

```bash
npx @windyroad/planning --runtime codex --scope user
```

Restart Codex and check its installed plugin and skill lists. Select the skill
name exposed by that installation. The outcome-led planning invocation is:

```text
$wr-planning:outcome-led-planning
```

For a package that documents both-runtime installation, `--runtime both` selects
both. This is an individual-package option; the current suite meta-installer
does not offer that runtime selection.

## Install required reviewers

Outcome-led planning requires architecture, JTBD and risk assessment. Planning bundles no reviewers or hooks and does not require ITIL. Use available
independent reviewers, or install the relevant plugins
for the runtime you will use, following each package's documentation:

- [Architecture review](../plugins/architect/).
- [JTBD review](../plugins/jtbd/).
- [Risk assessment](../plugins/risk-scorer/).

Verify that all three substantive reviews are available before starting
dependent work. The skill reports a missing review capability and holds
implementation if it cannot obtain a review.

## Understand evidence limits

An installation can register a skill without proving its later behavior. A
working skill command does not establish every hook or cross-plugin workflow.
Read package-specific support statements and verify the journey you depend on.
