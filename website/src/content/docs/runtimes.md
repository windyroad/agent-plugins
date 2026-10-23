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

## Optional GitHub tracking

The full GitHub coordination requirements use planning **0.4.0 or later**,
or ITIL **3.4.0 or later** through its compatibility command. Follow
[GitHub planning and agent coordination](../outcome-led-planning/#choose-where-to-track-the-plan).
Planning and contribute reuse the project's saved GitHub Issues or Local choice.
Local planning remains available without GitHub access. A selected Project
requires saved-view setup and verified updates at work checkpoints.

Use `/wr-planning:contribute` in Claude Code or `$wr-planning:contribute` in
Codex to join a current assessed outcome. This entrypoint belongs to the
standalone planning package.

## Install required reviewers

Initial and materially revised executable plans require five independent critics:
architecture, JTBD, risk, cognitive accessibility and planning. Planning bundles
no reviewers or hooks and does not require ITIL. Use available
independent reviewers, or install the relevant plugins
for the runtime you will use, following each package's documentation:

- [Architecture review](../plugins/architect/).
- [JTBD review](../plugins/jtbd/).
- [Risk assessment](../plugins/risk-scorer/).

Arrange cognitive accessibility and planning critics through available independent
reviewers too. Routine task claims and status updates inside the assessed plan
do not restart all five reviews. Verify that all five are available before starting
dependent work. The skill reports a missing review capability and holds
implementation if it cannot obtain a review.

## Understand evidence limits

An installation can register a skill without proving its later behavior. A
working skill command does not establish every hook or cross-plugin workflow.
Read package-specific support statements and verify the journey you depend on.
