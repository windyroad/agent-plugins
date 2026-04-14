---
status: "proposed"
date: 2026-04-14
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-14
---

# Connect Plugin (Experimental)

## Context and Problem Statement

When running parallel Claude Code sessions across multiple repos, there is no native mechanism for one session to notify another. A common scenario:

> Session A (repo-a) is working on a consumer of a package from repo-b. It discovers a bug in the package. Session B (repo-b) is idle, waiting for work. How does Session A tell Session B about the bug — without Session B polling and wasting tokens?

This is a real coordination problem. The existing plugins in the suite are all single-session, local-only governance tools. None address cross-session communication.

Claude Code v2.1.80+ introduced Channels — a research preview feature that lets external services push messages into a running session via the MCP protocol. Discord is one of the officially supported channel platforms. This creates an opportunity to solve the cross-repo signaling problem without custom infrastructure.

**Important:** The `--channels` flag is a research preview as of April 2026. This plugin is experimental and should be treated as such until Channels reaches GA.

## Decision Drivers

- **Zero idle token cost**: A waiting session should consume no tokens until a signal arrives. Polling-based approaches (shared file, periodic checks) burn tokens continuously.
- **Cross-machine support**: Named pipes and filesystem signals only work when both sessions are on the same machine. Discord works locally and remotely.
- **Officially supported platform**: Discord Channels are supported by Claude Code without the `--dangerously-load-development-channels` flag.
- **Opt-in, not opt-out**: This plugin is unlike the governance plugins — it should never be forced on a project. Setup must offer a clear opt-out path.
- **Security posture**: The suite includes a secret-leak gate (`risk-scorer`) that blocks credentials in files. Any credential storage must use environment variables, not config files.
- **Suite identity**: This is the first plugin that depends on an external service. That is a significant departure and must be clearly marked as experimental.

## Considered Options

### Option 1: Discord Channel Plugin (via claude-plugins-official)

Use the officially supported Discord channel plugin. The connect plugin provides setup guidance (skill), a send skill, and a session-start health check (hook). Credentials are stored in environment variables.

### Option 2: Named Pipe with Monitor Tool

Use a POSIX named pipe (`mkfifo`) as the signal transport. Session B opens the pipe with the Monitor tool; Session A writes to it. Local-only, no external dependencies.

### Option 3: Shared File with Polling

Session A writes a signal file to a shared location. Session B polls on a timer (e.g., `/loop 5m` checking for the file). No external dependencies.

### Option 4: Custom MCP Channel Server

Build a custom MCP channel server (e.g., using named pipes or WebSockets). Full control over the protocol, but requires `--dangerously-load-development-channels` and Bun.

## Decision Outcome

**Chosen option: Option 1 — Discord Channel Plugin**, because it is the only option that provides zero idle token cost, works across machines, and uses an officially supported Claude Code feature without dangerous flags.

The plugin is marked **experimental** because:

1. The `--channels` flag is a research preview
2. This is the first plugin in the suite with an external service dependency
3. The Discord channel plugin is maintained by a third party (`claude-plugins-official`)

## Plugin Design

### Package Structure

```
packages/
  connect/
    .claude-plugin/
      plugin.json
    bin/
      install.mjs
    hooks/
      hooks.json
      session-start.sh
      test/
        session-start.bats
    skills/
      setup/
        SKILL.md
      send/
        SKILL.md
    package.json
    README.md
```

### Credential Storage

Credentials are stored in environment variables, **never in project files**:

- `WR_CONNECT_BOT_TOKEN` — the Discord bot token
- `WR_CONNECT_CHANNEL_ID` — the Discord channel ID
- `WR_CONNECT_SESSION_NAME` — a human-readable name for this session (e.g., `repo-b`)

The setup skill guides users to set these in their shell profile (`.zshrc`, `.bashrc`) or a `.env` file that is already in `.gitignore`. The skill explicitly warns against committing tokens and checks that `.gitignore` covers `.env` if that path is chosen.

This approach is consistent with the `risk-scorer`'s `secret-leak-gate.sh`, which blocks credentials written to project files with the guidance: "Use environment variables or CI secrets instead."

### Setup Skill — Opt-Out

The `/wr-connect:setup` skill is interactive and must:

1. Explain what the plugin does and that it requires a Discord bot
2. **Ask the user if they want to proceed** before any configuration. If the user declines, exit cleanly with no changes.
3. Walk through Discord bot creation, channel ID retrieval, and env var configuration
4. Verify the env vars are set and the Discord channel plugin is installed
5. Offer a test signal to confirm the setup works

The opt-out happens at step 2. No config files are written, no env vars are required, and no hooks activate unless the user completes setup.

### Session-Start Hook

The `SessionStart` hook checks whether the environment variables are set. If they are but `--channels` is not active, it warns (does not block) with actionable advice:

```
wr-connect: Environment configured but --channels is not active.
To enable cross-repo collaboration, restart with:
  claude --channels plugin:discord@claude-plugins-official
```

If the env vars are not set, the hook exits silently — the plugin is effectively inactive.

### Send Skill

The `/wr-connect:send` skill reads `WR_CONNECT_BOT_TOKEN`, `WR_CONNECT_CHANNEL_ID`, and `WR_CONNECT_SESSION_NAME` from the environment, formats a message with a `[wr-connect]` prefix and session name, and sends it via the Discord API.

### Message Routing and Multi-Agent Collaboration

All messages go to the shared Discord channel. Multiple Claude Code sessions and
human participants can coexist on the same channel.

**Message format:** `[wr-connect] from: <session-name> | <message>`

**@mention convention:** Messages can include `@<session-name>` to direct them at
a specific session. This is a text convention, not a Discord @user mention. Each
session knows its own name via `WR_CONNECT_SESSION_NAME` and applies this logic:

- **`@my-name` present** — directed at me, prioritise and respond
- **`@someone-else` present** — read for context, stay quiet unless I have
  something relevant to add
- **No `@` at all** — broadcast, respond if relevant to my domain

The `SessionStart` hook primes the agent with these guidelines when channels are
active. This enables a collaborative group dynamic: agents hand off findings, ask
questions, share context, and coordinate work — while humans can weigh in with
experience or requirements using the same channel.

**Note:** In v1 there is no enforced routing — all sessions receive all messages.
The `@mention` convention is advisory, relying on the agent's judgement. A future
version could add server-side filtering if needed.

## Security Considerations

### The bot token is a remote code execution credential

Anyone with the bot token and channel ID can send arbitrary messages to a Claude Code session that has full filesystem and shell access. This is **Impact 5 (Severe)** per `RISK-POLICY.md`.

Mitigations:

1. **Environment variables only** — tokens never written to project files, consistent with `secret-leak-gate.sh`
2. **Discord allowlist** — the Discord channel plugin supports user-ID allowlisting. The setup skill must guide users through configuring this.
3. **Private channel** — the setup skill recommends a private Discord server or private channel
4. **Dedicated bot** — one bot per developer, not shared team bots for personal dev workflows
5. **Experimental label** — prominent warnings in README, setup skill, and this ADR

### External service dependency

Discord is a third-party service. If Discord is unavailable:

- The send skill fails with a clear error
- Listening sessions continue working normally (they just don't receive signals)
- No local functionality is affected

### Supply chain: claude-plugins-official

This plugin depends on the Discord channel plugin from `claude-plugins-official`. This is the first time the suite depends on an external plugin. If that plugin is compromised, it could inject messages into Claude Code sessions. This risk is mitigated by:

- The plugin being from the official Claude Code plugin marketplace
- The Discord allowlist filtering messages by sender

## Install Scope

Per ADR-004, the plugin defaults to `--scope project`. However, cross-repo signaling inherently spans projects — the plugin must be installed in every participating repo.

Users who want the plugin available everywhere can use `--scope user`. The install script and README document this escape hatch. No amendment to ADR-004 is needed; its existing `--scope user` override applies.

## Consequences

### Good

- Solves cross-session coordination with zero idle token cost
- Uses officially supported Claude Code infrastructure (no dangerous flags)
- Opt-in design — inactive unless explicitly configured
- Environment variable storage is consistent with the suite's security posture

### Neutral

- Adds a 12th plugin to the suite (within the monorepo growth threshold noted in ADR-002)
- Requires Discord account and bot setup — more friction than other plugins
- Per ADR-005, the plugin needs bats tests in `hooks/test/`

### Bad

- First external service dependency — changes the suite's "everything is local" identity
- Depends on a research preview feature (`--channels`) that may change
- Depends on a third-party plugin (`claude-plugins-official`) outside our control
- No enforced message routing in v1 — all listeners receive all messages (advisory @mention convention only)
- Discord bot setup is manual and somewhat involved

## Confirmation

- Setup skill asks for explicit opt-in before any configuration
- No credentials stored in project files (env vars only)
- `SessionStart` hook warns (not blocks) when env vars are set but `--channels` is inactive
- `SessionStart` hook outputs a collaboration primer when env vars are set and `--channels` is active
- `SessionStart` hook is silent when env vars are not set (plugin is inactive)
- README and setup skill include experimental warnings
- Install defaults to `--scope project` (ADR-004 compliant)
- `hooks/test/session-start.bats` exists with tests for all states (no config, config without channels, config with channels and primer output)
- `secret-leak-gate.sh` is not triggered by any file this plugin creates

## Pros and Cons of the Options

### Option 1: Discord Channel Plugin

- Good: Zero idle token cost — session wakes only on signal
- Good: Works across machines, not just locally
- Good: Officially supported channel platform, no dangerous flags
- Good: Simple implementation — wraps existing infrastructure with skills and a hook
- Bad: Requires Discord account and bot setup
- Bad: External service dependency (Discord)
- Bad: Third-party plugin dependency (claude-plugins-official)
- Bad: Research preview feature may change

### Option 2: Named Pipe with Monitor Tool

- Good: No external dependencies, fully local
- Good: Zero token cost (Monitor tool watches the pipe)
- Bad: Local-only — both sessions must be on the same machine
- Bad: Named pipe `open()` blocks until both ends are present — requires workarounds (pre-opened writer)
- Bad: Pipe cleanup is fiddly (stale pipes, broken readers)
- Bad: Monitor tool behavior with named pipes is not well-documented

### Option 3: Shared File with Polling

- Good: Simplest implementation, no dependencies
- Good: Works with existing tools (file read + `/loop`)
- Bad: High token cost — polling burns tokens continuously
- Bad: Latency — signal delivery depends on poll interval
- Bad: File locking and race conditions on concurrent writes

### Option 4: Custom MCP Channel Server

- Good: Full control over protocol and transport
- Good: Could use named pipes, WebSockets, or any IPC mechanism
- Bad: Requires `--dangerously-load-development-channels` flag
- Bad: Requires Bun runtime
- Bad: Significant implementation effort for the channel server
- Bad: No official support — breakage risk on Claude Code updates

## Reassessment Criteria

- **`--channels` goes GA**: Remove the experimental label and revisit the setup flow. The env var detection mechanism in the hook may need updating.
- **Claude Code adds native cross-session signaling**: If Claude Code ships a built-in way for sessions to signal each other, this plugin becomes unnecessary. Deprecate it.
- **claude-plugins-official Discord plugin is deprecated or compromised**: Reassess the supply chain dependency. Consider Option 2 or 4 as fallbacks.
- **Message routing becomes essential**: If multi-session scenarios are common, add `to: <session-name>` filtering. This is a feature extension, not an architectural change.
- **Plugin count exceeds 15**: Per ADR-002's reassessment criteria, evaluate whether monorepo tooling needs upgrading.
