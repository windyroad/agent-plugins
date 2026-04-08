#!/bin/bash
# Launch Claude Code with all Windy Road plugins loaded via --plugin-dir.
# Workaround for marketplace skill loading bug (anthropics/claude-code#35641).
#
# Usage: ./claude-wr.sh [claude args...]
# Example: ./claude-wr.sh
#          ./claude-wr.sh -p "list skills"
#          ./claude-wr.sh --model sonnet

PLUGIN_DIR="$(cd "$(dirname "$0")/plugins" && pwd)"

exec claude \
  --plugin-dir "$PLUGIN_DIR/wr-architect" \
  --plugin-dir "$PLUGIN_DIR/wr-risk-scorer" \
  --plugin-dir "$PLUGIN_DIR/wr-voice-tone" \
  --plugin-dir "$PLUGIN_DIR/wr-style-guide" \
  --plugin-dir "$PLUGIN_DIR/wr-jtbd" \
  --plugin-dir "$PLUGIN_DIR/wr-tdd" \
  --plugin-dir "$PLUGIN_DIR/wr-retrospective" \
  --plugin-dir "$PLUGIN_DIR/wr-problem" \
  --plugin-dir "$PLUGIN_DIR/wr-c4" \
  --plugin-dir "$PLUGIN_DIR/wr-wardley" \
  "$@"
