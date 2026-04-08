#!/bin/bash
# Launch Claude Code with all Windy Road plugins loaded via --plugin-dir.
# Workaround for marketplace skill loading bug (anthropics/claude-code#35641).
#
# Usage: ./claude-wr.sh [claude args...]
# Example: ./claude-wr.sh
#          ./claude-wr.sh -p "list skills"
#          ./claude-wr.sh --model sonnet

PKG_DIR="$(cd "$(dirname "$0")/packages" && pwd)"

exec claude \
  --plugin-dir "$PKG_DIR/architect" \
  --plugin-dir "$PKG_DIR/risk-scorer" \
  --plugin-dir "$PKG_DIR/voice-tone" \
  --plugin-dir "$PKG_DIR/style-guide" \
  --plugin-dir "$PKG_DIR/jtbd" \
  --plugin-dir "$PKG_DIR/tdd" \
  --plugin-dir "$PKG_DIR/retrospective" \
  --plugin-dir "$PKG_DIR/problem" \
  --plugin-dir "$PKG_DIR/c4" \
  --plugin-dir "$PKG_DIR/wardley" \
  "$@"
