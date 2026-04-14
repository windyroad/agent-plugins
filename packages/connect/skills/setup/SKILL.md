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

**This is an interactive walkthrough.** Use AskUserQuestion at each step to confirm
progress and gather details. Do NOT skip ahead — wait for the user at each checkpoint.

## Steps

### 1. Explain and opt-in

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

Use AskUserQuestion:
- "Would you like to proceed with setting up cross-repo collaboration via Discord?"
- Options: "Yes, let's set it up" / "No, skip for now"

If no:
> Setup skipped. The connect plugin is inactive until configured.
> Run `/wr-connect:setup` any time to start again.

Stop — do not proceed.

### 2. Check for existing Discord server

Use AskUserQuestion:
- "Do you already have a Discord server you'd like to use, or do you need to create one?"
- Options: "I have a server" / "I need to create one"

If they need to create one, guide them:
1. Open Discord and click the **+** button in the server list
2. Choose **Create My Own** > **For me and my friends**
3. Name it something like `dev-agents` or `wr-connect`

### 3. Create a Discord bot

Tell the user to go to https://discord.com/developers/applications, then guide
them step by step. Use AskUserQuestion after giving the instructions:

**Instructions:**
1. Click **New Application** — name it `wr-connect`
2. Go to **Bot** > click **Add Bot** > confirm
3. Under **Token**, click **Reset Token** and copy the token
4. Under **Privileged Gateway Intents**, enable:
   - **Message Content Intent** (to read message text)
   - **Server Members Intent** (optional — for member awareness)
5. Go to **OAuth2 > URL Generator**:
   - Scopes: `bot`
   - Bot permissions: `Send Messages`, `Read Messages/View Channels`, `Add Reactions`, `Read Message History`
6. Copy the generated URL, open it in a browser, and add the bot to your server

Use AskUserQuestion:
- "Have you created the bot and copied the token?"
- Options: "Yes, I have the token" / "I need help with a step"

If they need help, ask which step is unclear and provide more detail.

### 4. Get the channel ID

Tell the user:
1. In Discord, go to **User Settings > Advanced** and enable **Developer Mode**
2. Create a channel (e.g., `#agent-collab`) or pick an existing one
3. Right-click the channel and click **Copy Channel ID**

Use AskUserQuestion:
- "Have you copied the channel ID?"
- Options: "Yes, I have the channel ID" / "I need help"

### 5. Store credentials

Use AskUserQuestion:
- "Where would you like to store the bot token and channel ID?"
- Options:
  - ".env file (recommended)" — "Store in a .env file in the project root. The file must be in .gitignore."
  - "1Password CLI" — "Use `op` CLI to store secrets in 1Password and reference them via `op://`"
  - "Shell profile" — "Add exports to ~/.zshrc or ~/.bashrc"

**If .env file:**

Check that `.env` is in `.gitignore`:
```bash
grep -q '\.env' .gitignore 2>/dev/null && echo ".env is in .gitignore" || echo "WARNING: .env is NOT in .gitignore"
```

If not in `.gitignore`, warn the user and offer to add it.

Use AskUserQuestion to get the values:
- "Paste your bot token (from step 3):"
- "Paste your channel ID (from step 4):"
- "What should this session be called? (e.g., `windyroad-plugins`, `repo-a`)"

Write the `.env` file (or append to it if it exists):
```
WR_CONNECT_BOT_TOKEN=<token>
WR_CONNECT_CHANNEL_ID=<channel-id>
WR_CONNECT_SESSION_NAME=<session-name>
```

**If 1Password CLI:**

Check if `op` is available:
```bash
command -v op && echo "1Password CLI available" || echo "1Password CLI not found"
```

Guide the user to create a vault item and reference it:
```bash
op item create --category=API\ Credential --title="wr-connect" \
  'bot_token=<token>' \
  'channel_id=<channel-id>' \
  'session_name=<session-name>'
```

Then add to shell profile:
```bash
export WR_CONNECT_BOT_TOKEN="$(op read 'op://Private/wr-connect/bot_token')"
export WR_CONNECT_CHANNEL_ID="$(op read 'op://Private/wr-connect/channel_id')"
export WR_CONNECT_SESSION_NAME="$(op read 'op://Private/wr-connect/session_name')"
```

**If shell profile:**

Use AskUserQuestion to get the values (same as .env), then tell the user to add
the exports to their `~/.zshrc` or `~/.bashrc` and run `source ~/.zshrc`.

**Security warning:** The bot token gives anyone who has it the ability to send
messages to your Claude Code session. Never commit it to source control.

### 6. Verify environment variables

Check the env vars are set in the current shell:

```bash
[ -n "$WR_CONNECT_BOT_TOKEN" ] && echo "BOT_TOKEN: set" || echo "BOT_TOKEN: NOT SET"
[ -n "$WR_CONNECT_CHANNEL_ID" ] && echo "CHANNEL_ID: set" || echo "CHANNEL_ID: NOT SET"
[ -n "$WR_CONNECT_SESSION_NAME" ] && echo "SESSION_NAME: set" || echo "SESSION_NAME: NOT SET"
```

If any are not set:
- For .env: remind the user to run `source .env` or check the file
- For 1Password: remind the user to run `eval $(op signin)` first
- For shell profile: remind the user to `source ~/.zshrc`

Use AskUserQuestion:
- "Are all three variables showing as set?"
- Options: "Yes, all set" / "No, some are missing"

If missing, help troubleshoot.

### 7. Install the Discord channel plugin

```bash
claude plugin install discord@claude-plugins-official
```

### 8. Configure the Discord allowlist (security)

This is critical. Without the allowlist, anyone who can message the bot can send
instructions to the Claude Code session.

Tell the user:

> To find your Discord user ID: In Discord with Developer Mode enabled,
> click your username at the bottom left, then click **Copy User ID**.

Guide the user to configure the allowlist so only their own Discord user ID can
send messages. The exact command depends on the Discord channel plugin's interface —
check its documentation for the allowlist or access policy setting.

Use AskUserQuestion:
- "Have you configured the Discord allowlist with your user ID?"
- Options: "Yes, allowlist configured" / "I need help finding my user ID" / "I'll do this later"

### 9. Restart with channels active

Tell the user:

> To activate, restart Claude Code with:
> ```
> claude --channels plugin:discord@claude-plugins-official
> ```
> Claude will send a pairing code. Follow the prompts to pair your Discord account.

### 10. Test the setup

Use AskUserQuestion:
- "Would you like to send a test message to verify the setup?"
- Options: "Yes, send a test" / "No, I'll test later"

If yes, tell them to use:

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
> - Agents can react to messages for lightweight acknowledgement.

$ARGUMENTS
