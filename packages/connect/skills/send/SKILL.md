---
name: wr-connect:send
description: Send a message to other Claude Code sessions via the Discord channel.
allowed-tools: Bash, AskUserQuestion, mcp__plugin_discord_discord__reply, mcp__plugin_discord_discord__react, mcp__plugin_discord_discord__fetch_messages
---

# Send Message

Send a message from this session to other Claude Code sessions on the shared
Discord channel. Uses the Discord plugin's reply tool directly.

## Prerequisites

The Discord channel plugin must be active (`--channels plugin:discord@claude-plugins-official`).
If not set up, run `/wr-connect:setup` first.

## Instructions

### 1. Determine the channel

Check if `WR_CONNECT_CHANNEL_ID` is set:

```bash
echo "${WR_CONNECT_CHANNEL_ID:-NOT SET}"
```

If not set, use `fetch_messages` to find the active guild channel, or ask the user
which channel to send to via AskUserQuestion.

### 2. Determine session name

Check if `WR_CONNECT_SESSION_NAME` is set:

```bash
echo "${WR_CONNECT_SESSION_NAME:-}"
```

If not set, detect from git remote:

```bash
git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||'
```

If neither works, use the current directory name.

### 3. Get the message

The message to send is provided via `$ARGUMENTS`.

If `$ARGUMENTS` is empty, use AskUserQuestion to ask:

> What message would you like to send to the other session(s)?
> To direct your message to a specific session, start with @session-name.

### 4. Send the message

Format the message as: `**<session-name>:** <message>`

Use the Discord plugin's `reply` tool to send it to the channel:

```
reply(chat_id: "<channel-id>", text: "**<session-name>:** <message>")
```

**@mentions:** If the user's message starts with `@<name>`, preserve it in the
message body. This tells the target session to prioritise the message.

### 5. Report result

Confirm the message was sent and show the formatted text.

## Examples

**Broadcast (all sessions):**
```
/wr-connect:send BUG: Widget.parse() throws on null input at line 47
```
Sends:
```
**windyroad/agent-plugins:** BUG: Widget.parse() throws on null input at line 47
```

**Directed (specific session):**
```
/wr-connect:send @bbstats please fix Widget.parse()
```
Sends:
```
**windyroad/agent-plugins:** @bbstats please fix Widget.parse()
```

$ARGUMENTS
