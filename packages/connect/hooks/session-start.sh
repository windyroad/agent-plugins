#!/bin/bash
# wr-connect - SessionStart hook
# Warns if env vars are configured but --channels is not active.
# Always exits 0 (warns, never blocks).

# If bot token is not set, plugin is inactive — exit silently
if [ -z "${WR_CONNECT_BOT_TOKEN:-}" ]; then
  exit 0
fi

# If --channels is active, output collaboration primer
# NOTE: CLAUDE_CHANNELS is the expected env var when --channels is active.
# This may change in future Claude Code versions; update if needed.
if [ -n "${CLAUDE_CHANNELS:-}" ]; then
  SESSION_NAME="${WR_CONNECT_SESSION_NAME:-unnamed}"
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
PRIMER
  exit 0
fi

# Env vars set but --channels not active — warn
cat <<'EOF'
wr-connect: Environment configured but --channels is not active.
To enable cross-repo collaboration, restart with:
  claude --channels plugin:discord@claude-plugins-official
EOF
exit 0
