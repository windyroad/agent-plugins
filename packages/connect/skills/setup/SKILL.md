---
name: wr-connect:setup
description: Set up cross-repo collaboration via Discord. Step-by-step interactive walkthrough with explicit opt-out before any configuration.
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

# Connect Setup

> **EXPERIMENTAL:** This plugin uses Claude Code's `--channels` feature, which is a
> research preview. The API surface may change. See ADR-006 for details.

This skill configures Discord as a collaboration channel so Claude Code sessions
across different repos can communicate with zero idle token cost.

**CRITICAL: Walk the user through ONE action at a time.** Never give a list of
multiple actions and ask "done?" at the end. After EACH action, pause with the
AskUserQuestion tool (this is mandatory — do NOT fall back to plain prompts)
and wait for confirmation before giving the next instruction. If any step has
sub-steps, treat each sub-step as its own checkpoint.

**If AskUserQuestion is not available** (MCP server disconnected), stop the
skill and tell the user to restart Claude Code so the tool is available. Do
NOT continue with plain-text prompts — the checkpointed flow depends on
structured questions.

**Each repo should have its own Discord bot** so sessions are distinguishable
in Discord. The bot name defaults to the org/repo from git remote.

## Walkthrough

### Stage 1: Opt-in

Tell the user:

> This plugin connects your Claude Code sessions across repos so they can
> collaborate. Sessions can hand off findings, ask questions, share context,
> or coordinate work — all via a shared Discord channel with zero idle token cost.
>
> Each repo gets its own Discord bot (so you can tell sessions apart in Discord).
> You will need a Discord account, a Discord server, and a few minutes to create
> a bot in the Discord Developer Portal.

**Checkpoint 1a:** Would you like to proceed?
- yes → continue to Stage 2
- no → stop and tell the user: "Setup skipped. Run `/wr-connect:setup` any time to start."

### Stage 2: Bot name

Detect the bot name from git remote:
```bash
git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||' | tr '/' '-'
```

If no remote, use the directory name.

**Checkpoint 2a:** Confirm the bot name.
> Detected bot name: `<detected-name>`. This is how the bot will appear in Discord.
- Use this name → continue
- Different name → ask what they want, then confirm and continue

### Stage 3: Discord server

**Checkpoint 3a:** Do you have a Discord server for agent collaboration?
- yes → continue to Stage 4
- no → go to Stage 3b

**Stage 3b: Create server** (only if needed)

One action at a time:

**Checkpoint 3b.1:** Open Discord.
> Open the Discord desktop or web app.

Wait for confirmation.

**Checkpoint 3b.2:** Create the server.
> Click the **+** button in the server list on the left.

Wait for confirmation.

**Checkpoint 3b.3:** Choose type.
> Choose **Create My Own** > **For me and my friends**.

Wait for confirmation.

**Checkpoint 3b.4:** Name it.
> Name it something like `dev-agents` or whatever you prefer.

Wait for confirmation. Then continue to Stage 4.

### Stage 4: Create the Discord application

One action at a time. After each instruction, wait for confirmation.

**Checkpoint 4a:** Open Developer Portal.
> Go to https://discord.com/developers/applications in your browser.

Wait for confirmation.

**Checkpoint 4b:** Create application.
> Click **New Application**. Name it `<detected-bot-name>`. Accept the terms and click **Create**.

Wait for confirmation.

**Checkpoint 4c:** Open the Bot section.
> In the left sidebar, click **Bot**.

Wait for confirmation.

**Checkpoint 4d:** Set the bot username.
> Set the bot's username to `<detected-bot-name>` (same as the application name).
> Save changes.

Wait for confirmation.

**Checkpoint 4e:** Reset and copy the token.
> Scroll up to the **Token** section. Click **Reset Token** and confirm.
> Copy the token that appears — **it's only shown once**. Save it somewhere safe
> for the next step.

Wait for confirmation.

**Checkpoint 4f:** Enable Message Content Intent.
> Scroll down to **Privileged Gateway Intents**. Enable **Message Content Intent**.
> Save changes.

Wait for confirmation.

### Stage 5: Invite the bot

**Checkpoint 5a:** Open OAuth2 URL Generator.
> In the left sidebar, click **OAuth2** > **URL Generator**.

Wait for confirmation.

**Checkpoint 5b:** Select scopes.
> Under **Scopes**, check `bot`.

Wait for confirmation.

**Checkpoint 5c:** Select bot permissions.
> Under **Bot Permissions**, check: `View Channels`, `Send Messages`,
> `Send Messages in Threads`, `Read Message History`, `Attach Files`, `Add Reactions`.

Wait for confirmation.

**Checkpoint 5d:** Set integration type.
> Set **Integration Type** to **Guild Install**.

Wait for confirmation.

**Checkpoint 5e:** Copy the URL.
> Scroll down and copy the **Generated URL** at the bottom.

Wait for confirmation.

**Checkpoint 5f:** Invite the bot.
> Paste the URL into your browser. Select your server. Click **Authorize**.

Wait for confirmation. The bot should now appear in your server's member list.

### Stage 6: Configure the token

**Checkpoint 6a:** Run /discord:configure.

Tell the user:
> Now register the token with the Discord plugin. Run this command,
> replacing `<token>` with the bot token you copied:
> ```
> /discord:configure <token>
> ```
> **Do NOT paste the token in chat** — type it directly into the slash command.

Wait for confirmation.

### Stage 7: Restart with --channels

**Checkpoint 7a:** Restart.

Tell the user:
> Exit this Claude Code session and restart with the channels flag:
> ```
> claude --channels plugin:discord@claude-plugins-official
> ```
> The Discord plugin won't connect without this flag. The SessionStart hook
> will confirm when it's active.

Wait for confirmation (or note that the remaining stages must be done in the
restarted session).

### Stage 8: Pair via DM

One action at a time.

**Checkpoint 8a:** DM the bot.
> Open Discord. In your server's member list (or server icon dropdown),
> click on your bot. Send it any DM (e.g., "hello").

Wait for confirmation.

**Checkpoint 8b:** Get the pairing code.
> The bot should reply with a 6-character pairing code. If it doesn't respond,
> the `--channels` flag might not be active — double-check the restart.

Wait for confirmation with the code.

**Checkpoint 8c:** Approve the pairing.

Tell the user:
> Run this in Claude Code, replacing `<code>` with the 6-character code:
> ```
> /discord:access pair <code>
> ```

Wait for confirmation. Once paired, the bot will send a "you're in" message.

### Stage 9: Lock down access

**Checkpoint 9a:** Add more people?
> Is there anyone else who needs to reach this session via Discord?
- yes → tell them to DM the bot, then approve each with `/discord:access pair <code>`
- no → continue

**Checkpoint 9b:** Lock to allowlist.

Tell the user:
> Switch from `pairing` mode (which lets anyone trigger pairing codes) to
> `allowlist` mode:
> ```
> /discord:access policy allowlist
> ```

Wait for confirmation.

### Stage 10: Guild channel (optional)

**Checkpoint 10a:** Want a guild channel?
> For multi-agent collaboration, add a shared Discord channel that all
> sessions can see.
- yes → continue to 10b
- no → skip to Stage 11

**Checkpoint 10b:** Enable Developer Mode.
> In Discord: **User Settings** > **Advanced** > enable **Developer Mode**.

Wait for confirmation.

**Checkpoint 10c:** Copy channel ID.
> Right-click the channel you want to use and click **Copy Channel ID**.

Wait for confirmation.

**Checkpoint 10d:** Add the channel.

Tell the user:
> Run this, replacing `<channel-id>` with what you copied:
> ```
> /discord:access group add <channel-id>
> ```
> Add `--no-mention` if you want the bot to see all messages (not just @mentions).

Wait for confirmation.

### Stage 11: Session name (optional)

**Checkpoint 11a:** Set session name.

The session name identifies this session in messages. Check if it's already set:
```bash
echo "${WR_CONNECT_SESSION_NAME:-not set}"
```

If not set, tell the user to add it to their `.env` or shell profile:
```
WR_CONNECT_SESSION_NAME=<org/repo>
```

Wait for confirmation. (Not critical — the send skill falls back to git remote.)

### Stage 12: Test

**Checkpoint 12a:** Send a test message?
- yes → use the Discord reply tool to send a test message to the channel,
  or tell the user to DM the bot
- no → skip

### Stage 13: Summary

Tell the user:

> Setup complete! Summary:
>
> - Bot: `<bot-name>` created and added to your server
> - Token: saved via `/discord:configure`
> - Access: locked to allowlist (only you can reach this session)
> - Guild channel: `<configured or skipped>`
>
> How collaboration works:
> - Each repo has its own bot — you can see which session sent a message.
> - Use `@session-name` to direct messages at a specific session.
> - Messages without `@` are broadcast.
> - Each session reads everything for context but only responds when relevant.
> - Always prefix your Discord replies with `**<session-name>:**` so others
>   can tell who you are.

$ARGUMENTS
