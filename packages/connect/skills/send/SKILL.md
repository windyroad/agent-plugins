---
name: wr-connect:send
description: Send a message to other Claude Code sessions via Discord.
allowed-tools: Bash, AskUserQuestion
---

# Send Message

Send a message from this session to other Claude Code sessions listening on the
configured Discord channel.

## Instructions

### 1. Check environment variables

Verify these environment variables are set:
- `WR_CONNECT_BOT_TOKEN`
- `WR_CONNECT_CHANNEL_ID`
- `WR_CONNECT_SESSION_NAME`

```bash
[ -n "$WR_CONNECT_BOT_TOKEN" ] && [ -n "$WR_CONNECT_CHANNEL_ID" ] && [ -n "$WR_CONNECT_SESSION_NAME" ] && echo "OK" || echo "MISSING"
```

If any are missing, tell the user:

> wr-connect is not configured. Run `/wr-connect:setup` first.

Then stop.

### 2. Get the message

The message to send is provided via `$ARGUMENTS`.

If `$ARGUMENTS` is empty, use AskUserQuestion to ask:

> What message would you like to send to the other session(s)?
> To direct your message to a specific session, start with @session-name.

### 3. Send the message

Format the message as: `[wr-connect] from: <SESSION_NAME> | <message>`

**@mentions:** If the user's message starts with `@<name>`, preserve it as-is in the
message body. This tells the target session to prioritise the message. Messages
without an `@` are treated as broadcast to all listening sessions.

Send via the Discord API:

```bash
curl -s -o /tmp/wr-connect-response.json -w "%{http_code}" \
  -X POST "https://discord.com/api/v10/channels/${WR_CONNECT_CHANNEL_ID}/messages" \
  -H "Authorization: Bot ${WR_CONNECT_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"[wr-connect] from: ${WR_CONNECT_SESSION_NAME} | <MESSAGE>\"}"
```

Replace `<MESSAGE>` with the actual message content. Escape any double quotes in the
message before inserting into the JSON payload.

### 4. Report result

Check the HTTP status code returned by curl:
- **200** or **201**: Message sent successfully. Report the formatted message to the user.
- **429**: Rate limited. Tell the user to wait a moment and try again.
- **401** or **403**: Authentication failed. Tell the user to check their bot token.
- **Other**: Report the status code and response body for debugging.

## Examples

**Broadcast (all sessions):**
```
/wr-connect:send BUG: Widget.parse() throws on null input at line 47
```
Sends:
```
[wr-connect] from: repo-a | BUG: Widget.parse() throws on null input at line 47
```

**Directed (specific session):**
```
/wr-connect:send @repo-b BUG: Widget.parse() throws on null input at line 47
```
Sends:
```
[wr-connect] from: repo-a | @repo-b BUG: Widget.parse() throws on null input at line 47
```

$ARGUMENTS
