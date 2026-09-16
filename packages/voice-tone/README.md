# @windyroad/voice-tone

**Voice and tone guidance for Claude Code and Codex.** Reviews user-facing copy before it ships and can shape ordinary assistant responses. *Maturity: Experimental (suite-bootstrap window; 169 invocations / 30d).*

Part of [Windy Road Agent Plugins](../../README.md).

## What It Does

When an AI agent writes user-facing text -- button labels, error messages, onboarding copy, marketing pages -- it doesn't know your brand voice. This plugin teaches it.

The voice-tone plugin:

1. **Detects** when an edit touches user-facing copy
2. **Blocks** the edit until the voice-tone agent has reviewed it
3. **Reviews** the proposed copy against your `docs/VOICE-AND-TONE.md` guide
4. **Reports** violations with suggested fixes that match your brand's voice principles, banned patterns, and word list

Beyond in-repo edits, the plugin also gates **external communications** — `gh issue create`, `gh pr create`, `gh issue/pr comment`, `gh api security-advisories`, `npm publish`, and `.changeset/*.md` author-time — via the [`wr-voice-tone:external-comms`](agents/external-comms.md) subagent and the on-demand [`/wr-voice-tone:assess-external-comms`](skills/assess-external-comms/SKILL.md) skill. This composes with `@windyroad/risk-scorer`'s sibling external-comms gate (see [ADR-028 amended 2026-05-14](../../docs/decisions/028-voice-tone-gate-external-comms.proposed.md)) — when both plugins are installed, voice/tone and risk/leak review fire independently on the same outbound prose call. This serves automatic governance enforcement on every copy edit and on-demand pre-flight governance checks before a release or handover.

## Install

```bash
npx @windyroad/voice-tone
```

Restart Claude Code after installing.

## Usage

The plugin works automatically. On first use in a project without a voice guide, it blocks edits and directs you to create one:

```
/wr-voice-tone:update-guide
```

This examines your existing content and asks about your brand voice, target audience, and tone preferences to generate a `docs/VOICE-AND-TONE.md` tailored to your project.

### Assistant responses

Run `/wr-voice-tone:update-assistant-guide` to create or update `docs/ASSISTANT-VOICE-AND-TONE.md`. The file's existence is the only enablement switch. Its prose may describe plain-language standards such as ISO 24495-1:2023 or ASD-STE100, or creative voice traits. The same assistant applies the guide and performs one semantic self-review before stopping; this adds one continuation's latency and token use, and some runtimes may briefly show the first response before its correction.

This supports the plugin's Claude Code and Codex command-hook runtimes, not ordinary web ChatGPT conversations. Standards references express alignment, not certification.

## How It Works

| Hook | Trigger | What it does |
|------|---------|-------------|
| `voice-tone-eval.sh` | Every prompt | Evaluates copy work and injects an opted-in assistant-response guide |
| `voice-tone-enforce-edit.sh` | Edit or Write | Blocks edits until the voice-tone agent has reviewed |
| `voice-tone-mark-reviewed.sh` | Agent completes | Marks the review as done (TTL: 3600s) |
| `assistant-voice-tone-stop.sh` | Response stop | Requests one guarded semantic self-review when the assistant guide exists |

## Agent

The `wr-voice-tone:agent` reads your `docs/VOICE-AND-TONE.md` and reviews proposed copy changes against:

- Voice principles and personality traits
- Tone guidance for different contexts
- Banned words and patterns
- Preferred terminology

## Updating and Uninstalling

```bash
npx @windyroad/voice-tone --update
npx @windyroad/voice-tone --uninstall
```

## Licence

[MIT](../../LICENSE)
