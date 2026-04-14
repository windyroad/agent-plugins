---
name: wr-connect:setup
description: Set up cross-repo collaboration via Discord. Interactive walkthrough with explicit opt-out before any configuration.
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

# Connect Setup

> **EXPERIMENTAL:** This plugin uses Claude Code's `--channels` feature, which is a
> research preview. The API surface may change. See ADR-006 for details.

This skill configures Discord as a collaboration channel so Claude Code sessions
across different repos can communicate with zero idle token cost.

## Steps

### 1. Explain what this does

Tell the user:

> This plugin connects your Claude Code sessions across repos so they can
> collaborate. For example, if Session A discovers a bug in a package from repo-b,
> it can notify Session B (which is working on repo-b) without Session B polling or
> wasting tokens. Sessions can hand off findings, ask questions, share context, or
> coordinate work.
>
> It works by using Discord as a message channel. You will need:
> - A Discord account
> - A Discord bot (created in the next step)
> - A private Discord server or channel

### 2. Opt-out checkpoint

Use AskUserQuestion to ask the user:

> Would you like to proceed with setting up cross-repo collaboration via Discord?
> This will require creating a Discord bot and configuring environment variables.
> No files will be written to your project.
>
> Reply **yes** to continue or **no** to skip.

If the user says no, respond with:

> Setup skipped. The connect plugin is inactive until configured.
> Run `/wr-connect:setup` any time to start again.

Then stop — do not proceed to any further steps.

### 3. Create a Discord bot

Guide the user through these steps:

1. Go to https://discord.com/developers/applications
2. Click **New Application** — name it something like `claude-connect`
3. Go to **Bot** > click **Add Bot** > confirm
4. Under **Token**, click **Reset Token** and copy it — they will need it in step 5
5. Under **Privileged Gateway Intents**, enable **Message Content Intent**
6. Go to **OAuth2 > URL Generator**:
   - Scopes: `bot`
   - Bot permissions: `Send Messages`, `Read Messages/View Channels`
7. Copy the generated URL, open it in a browser, and add the bot to their server

### 4. Get the channel ID

Guide the user:

1. In Discord, go to **User Settings > Advanced** and enable **Developer Mode**
2. Right-click the channel to use for collaboration and click **Copy Channel ID**

### 5. Configure environment variables

Guide the user to add these to their shell profile (`~/.zshrc`, `~/.bashrc`) or a
`.env` file that is already in `.gitignore`:

```bash
export WR_CONNECT_BOT_TOKEN="<the bot token from step 3>"
export WR_CONNECT_CHANNEL_ID="<the channel ID from step 4>"
export WR_CONNECT_SESSION_NAME="<a name for this session, e.g. repo-b>"
```

**Security warning:** The bot token gives anyone who has it the ability to send
messages to your Claude Code session. Never commit it to source control. Use
environment variables or a `.env` file that is in `.gitignore`.

If the user chooses a `.env` file, verify `.env` is in `.gitignore`:

```bash
grep -q '\.env' .gitignore 2>/dev/null && echo ".env is in .gitignore" || echo "WARNING: .env is NOT in .gitignore — add it now"
```

### 6. Verify environment variables

Check the env vars are set in the current shell:

```bash
[ -n "$WR_CONNECT_BOT_TOKEN" ] && echo "BOT_TOKEN: set" || echo "BOT_TOKEN: NOT SET"
[ -n "$WR_CONNECT_CHANNEL_ID" ] && echo "CHANNEL_ID: set" || echo "CHANNEL_ID: NOT SET"
[ -n "$WR_CONNECT_SESSION_NAME" ] && echo "SESSION_NAME: set" || echo "SESSION_NAME: NOT SET"
```

If any are not set, remind the user to `source ~/.zshrc` (or their profile) or
restart their terminal before continuing.

### 7. Install the Discord channel plugin

```bash
claude plugin install discord@claude-plugins-official
```

### 8. Restart with channels active

Tell the user to restart Claude Code with:

```bash
claude --channels plugin:discord@claude-plugins-official
```

Claude will send a pairing code. Follow the prompts to pair the Discord account.

### 9. Configure the Discord allowlist (security)

This is critical. Without the allowlist, anyone who can message the bot can send
instructions to the Claude Code session.

Guide the user to configure the allowlist so only their own Discord user ID can
send messages. The exact command depends on the Discord channel plugin's interface —
check its documentation for the allowlist or access policy setting.

Tell the user:

> To find your Discord user ID: In Discord with Developer Mode enabled,
> click your username at the bottom left, then click **Copy User ID**.

### 10. Test the setup

Ask the user if they would like to send a test message. If yes, tell them to use:

```
/wr-connect:send test message from setup
```

Or from another terminal:

```bash
curl -s -X POST "https://discord.com/api/v10/channels/$WR_CONNECT_CHANNEL_ID/messages" \
  -H "Authorization: Bot $WR_CONNECT_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "[wr-connect] from: test | setup verification"}'
```

If the session with `--channels` active receives the message, setup is complete.

### 11. Explain collaboration behaviour

Tell the user:

> Your session is now part of a shared collaboration channel. Here's how it works:
>
> - **Multiple sessions and humans** can share the same Discord channel.
> - Use `@session-name` in messages to direct them at a specific session
>   (e.g. `/wr-connect:send @repo-b please fix Widget.parse()`).
> - Messages without `@` are broadcast — all sessions see them.
> - Each session reads everything for context but only responds when the message
>   is relevant to its work.
> - Your session name is whatever you set in `WR_CONNECT_SESSION_NAME`. Other
>   sessions will use `@your-name` to get your attention.

$ARGUMENTS
