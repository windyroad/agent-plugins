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

**Important:** Each repo should have its own Discord bot so sessions are
distinguishable in Discord. The bot name defaults to the org/repo from git remote.

## Steps

### 1. Explain and opt-in

Tell the user:

> This plugin connects your Claude Code sessions across repos so they can
> collaborate. For example, if Session A discovers a bug in a package from repo-b,
> it can notify Session B (which is working on repo-b) without Session B polling or
> wasting tokens. Sessions can hand off findings, ask questions, share context, or
> coordinate work.
>
> Each repo gets its own Discord bot (so you can tell sessions apart in Discord).
> You will need:
> - A Discord account
> - A Discord server with a channel for agent collaboration
> - A few minutes to create a bot in the Discord Developer Portal

Use AskUserQuestion:
- "Would you like to proceed with setting up cross-repo collaboration via Discord?"
- Options: "Yes, let's set it up" / "No, skip for now"

If no:
> Setup skipped. The connect plugin is inactive until configured.
> Run `/wr-connect:setup` any time to start again.

Stop — do not proceed.

### 2. Detect bot name

Detect the org/repo from git remote to suggest a bot name:

```bash
git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||' | tr '/' '-'
```

If no remote is found, use the directory name as a fallback.

Use AskUserQuestion:
- "What should the Discord bot be called? This name will appear in Discord when this session sends messages."
- Options: "<detected-name>" (e.g., "windyroad-agent-plugins") / "I want a different name"

### 3. Check for existing Discord server

Use AskUserQuestion:
- "Do you already have a Discord server for agent collaboration, or do you need to create one?"
- Options: "I have a server" / "I need to create one"

If they need to create one, guide them:
1. Open Discord and click the **+** button in the server list
2. Choose **Create My Own** > **For me and my friends**
3. Name it something like `dev-agents`
4. Create a private channel (e.g., `#agent-collab`)

### 4. Create a Discord bot

Tell the user to go to https://discord.com/developers/applications:

**Instructions:**
1. Click **New Application** — name it `<detected-bot-name>` from step 2
2. Go to **Bot** in the sidebar. Give the bot the same username.
3. Under **Token**, click **Reset Token** and copy the token (shown once).
4. Under **Privileged Gateway Intents**, enable:
   - **Message Content Intent** (to read message text)
5. Go to **OAuth2 > URL Generator**:
   - Scopes: `bot`
   - Bot permissions: `View Channels`, `Send Messages`, `Send Messages in Threads`,
     `Read Message History`, `Attach Files`, `Add Reactions`
   - Integration type: **Guild Install**
6. Copy the generated URL, open it in a browser, and add the bot to your server

Use AskUserQuestion:
- "Have you created the bot and copied the token?"
- Options: "Yes, I have the token" / "I need help with a step"

If they need help, ask which step is unclear.

### 5. Configure the Discord plugin with the token

Tell the user to run the following command. **Do NOT paste the token yourself** —
the user should type it directly to avoid the token appearing in conversation history:

> Run this command, replacing `<token>` with the bot token you copied:
> ```
> /discord:configure <token>
> ```
> This saves the token securely at `~/.claude/channels/discord/.env`.

Use AskUserQuestion:
- "Have you run `/discord:configure` with your token?"
- Options: "Yes, token is configured" / "I need help"

### 6. Restart with channels active

Tell the user:

> You need to restart Claude Code with the channels flag to connect to Discord:
> ```
> claude --channels plugin:discord@claude-plugins-official
> ```
> The Discord plugin won't connect without this flag.

Use AskUserQuestion:
- "Have you restarted with `--channels`? (If we're in a new session, just confirm)"
- Options: "Yes, restarted" / "Not yet — I'll do it after setup"

If not yet, note that steps 7-9 must be done in the restarted session.

### 7. Pair via DM

Tell the user:

> Open Discord and send a DM to your bot. The bot will reply with a 6-character
> pairing code. Then run:
> ```
> /discord:access pair <code>
> ```
> This adds your Discord user ID to the allowlist.

Use AskUserQuestion:
- "Have you paired successfully?"
- Options: "Yes, I'm paired" / "The bot didn't respond" / "I need help"

If the bot didn't respond:
- Check that the session is running with `--channels`
- Check that the token was saved correctly (`/discord:configure` with no args shows status)

### 8. Lock down access

Tell the user:

> Now let's lock down access so only you can reach this session via Discord.
> Switch from `pairing` mode (which lets anyone trigger pairing codes) to
> `allowlist` mode:
> ```
> /discord:access policy allowlist
> ```

Use AskUserQuestion:
- "Have you locked down to allowlist policy?"
- Options: "Yes, locked down" / "I want to add more people first"

If they want to add more people, guide them:
> Have them DM the bot to get a pairing code, then approve with
> `/discord:access pair <code>`. Once everyone's in, run
> `/discord:access policy allowlist` to lock it.

### 9. Set up guild channel (optional)

Tell the user:

> For multi-agent collaboration, you'll want a shared guild channel that all
> sessions can see. Get the channel ID by right-clicking the channel in Discord
> (with Developer Mode enabled) and clicking **Copy Channel ID**.
>
> Then run:
> ```
> /discord:access group add <channel-id>
> ```
> Use `--no-mention` if you want the bot to see all messages (not just @mentions).

Use AskUserQuestion:
- "Would you like to set up a guild channel now?"
- Options: "Yes, I have the channel ID" / "No, DMs are enough for now"

If yes, guide them through the command.

### 10. Configure session name (optional)

The session name is used by the `/wr-connect:send` skill to identify this session
in messages. Detect from git remote:

```bash
git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||'
```

If a `.env.tpl` exists in the project, check if `WR_CONNECT_SESSION_NAME` is defined.
If not, suggest adding it:

```
WR_CONNECT_SESSION_NAME={{ op://Private/wr-connect/session_name }}
```

Or for projects without 1Password, the session name can be set directly:
```bash
export WR_CONNECT_SESSION_NAME="<org/repo>"
```

### 11. Test the setup

Use AskUserQuestion:
- "Would you like to send a test message to verify everything works?"
- Options: "Yes, send a test" / "No, I'll test later"

If yes and a guild channel is set up, use the reply tool to send a message to
the guild channel. If DM only, tell the user to DM the bot and check if it arrives.

### 12. Explain collaboration behaviour

Tell the user:

> Setup complete! Here's how collaboration works:
>
> - **Each repo has its own bot** — so you can see which session sent a message.
> - **Multiple sessions and humans** can share the same guild channel.
> - Use `@session-name` in messages to direct them at a specific session
>   (e.g. `/wr-connect:send @repo-b please fix Widget.parse()`).
> - Messages without `@` are broadcast — all sessions see them.
> - Each session reads everything for context but only responds when the message
>   is relevant to its work.
> - Agents can react to messages for lightweight acknowledgement.
>
> To set up another repo, install the wr-connect plugin there and run
> `/wr-connect:setup` — it will create a new bot for that repo.

$ARGUMENTS
