#!/bin/bash
# wr-connect - SessionStart hook
# Outputs collaboration primer when Discord channel is active.
# Always exits 0 (warns, never blocks).

# Check if the Discord plugin is configured (token saved)
DISCORD_ENV="$HOME/.claude/channels/discord/.env"
if [ ! -f "$DISCORD_ENV" ]; then
  # Discord plugin not configured — plugin is inactive, exit silently
  exit 0
fi

# Check if --channels is active
# NOTE: CLAUDE_CHANNELS is the expected env var when --channels is active.
# This may change in future Claude Code versions; update if needed.
if [ -n "${CLAUDE_CHANNELS:-}" ]; then
  # Detect session name from env var or git remote
  SESSION_NAME="${WR_CONNECT_SESSION_NAME:-}"
  if [ -z "$SESSION_NAME" ]; then
    SESSION_NAME=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||' || echo "")
  fi
  if [ -z "$SESSION_NAME" ]; then
    SESSION_NAME=$(basename "$PWD")
  fi

  cat <<PRIMER
wr-connect: Collaboration channel active. Your session name is "${SESSION_NAME}".

You are connected to a shared channel with other Claude Code sessions and
potentially human participants. Follow these guidelines:

LISTENING:
- Read all messages for context, but only respond if relevant to your work.
- Messages containing @${SESSION_NAME} are directed at you — prioritise these.
- Messages with @someone-else are for another session — read for context but
  stay quiet unless you have something relevant to add.
- Messages with no @ are broadcast — respond if relevant to your domain.

SENDING:
- Use /wr-connect:send to message the channel.
- Use @<session-name> to direct a message to a specific session.
- Be concise — other sessions will read your messages too.
- Always prefix your replies with **${SESSION_NAME}:** so others know who sent it.
PRIMER
  exit 0
fi

# Discord configured but --channels not active — warn
cat <<'EOF'
wr-connect: Discord is configured but --channels is not active.
To enable cross-repo collaboration, restart with:
  claude --channels plugin:discord@claude-plugins-official
EOF
exit 0
