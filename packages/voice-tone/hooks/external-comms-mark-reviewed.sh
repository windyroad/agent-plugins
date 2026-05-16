#!/bin/bash
# PostToolUse:Agent hook for the wr-voice-tone:external-comms subagent.
# Parses structured verdict from agent output and writes the per-evaluator
# marker that the canonical external-comms-gate.sh checks (P038 / ADR-028
# amended 2026-05-14, further amended 2026-05-16 P166).
#
# Marker filename: external-comms-voice-tone-reviewed-<KEY>
# Marker location: ${TMPDIR:-/tmp}/claude-risk-${SESSION_ID}/
#
# Marker key derivation (P166 / ADR-028 amended 2026-05-16):
#   1. PRIMARY — derive from agent's tool_input.prompt via
#      derive_external_comms_key_from_prompt (parses `SURFACE: <name>` +
#      `<draft>...</draft>` block, computes sha256(DRAFT + '\n' + SURFACE)).
#      Matches the gate's canonical key shape (external-comms-gate.sh
#      line 229). Single fire per gate cycle — agent does not compute the
#      key itself.
#   2. FALLBACK — when the prompt lacks structure (cached old SKILL.md /
#      agent prompts during the deprecation window), fall back to the
#      agent-emitted EXTERNAL_COMMS_VOICE_TONE_KEY line. Removed after
#      one release cycle per architect direction.
#
# The risk-scorer evaluator writes its own per-evaluator marker
# (external-comms-risk-reviewed-<KEY>) from packages/risk-scorer/hooks/
# risk-score-mark.sh. When both plugins installed, both gates fire on the
# same PreToolUse event; both deny until both per-evaluator markers exist.
# Gates compose at firing level — no shared composite marker.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/external-comms-key.sh
source "$SCRIPT_DIR/lib/external-comms-key.sh"

INPUT=$(cat)

TOOL_NAME=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_name', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")
[ "$TOOL_NAME" = "Agent" ] || exit 0

SUBAGENT=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input', {}).get('subagent_type', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

SESSION_ID=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('session_id', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")
[ -n "$SESSION_ID" ] || exit 0

# Only handle the voice-tone external-comms subagent.
case "$SUBAGENT" in
  *voice-tone*external-comms*|*wr-voice-tone:external-comms*) ;;
  *) exit 0 ;;
esac

AGENT_OUTPUT=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    out = data.get('tool_response', {}).get('output', '')
    if not out:
        # PostToolUse may deliver content as a list of {type,text} parts
        # (matches the Claude Code PostToolUse hook payload shape).
        tr = data.get('tool_response', {})
        if isinstance(tr, dict):
            content = tr.get('content', [])
            if isinstance(content, list):
                texts = [c.get('text', '') for c in content if isinstance(c, dict) and c.get('type') == 'text']
                if texts:
                    out = '\n'.join(texts)
        if not out:
            out = data.get('tool_response', '')
    print(out if isinstance(out, str) else json.dumps(out))
except Exception:
    print('')
" 2>/dev/null || echo "")

# Extract the prompt the orchestrator sent to the agent — P166 uses this
# as the canonical source for the marker key (sha256(DRAFT+'\n'+SURFACE)).
PROMPT=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input', {}).get('prompt', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

RDIR="${TMPDIR:-/tmp}/claude-risk-${SESSION_ID}"
mkdir -p "$RDIR"

VERDICT_LINE=$(echo "$AGENT_OUTPUT" | grep -E '^EXTERNAL_COMMS_VOICE_TONE_VERDICT:' | tail -1) || true
VERDICT=$(echo "$VERDICT_LINE" | sed 's/^EXTERNAL_COMMS_VOICE_TONE_VERDICT:[[:space:]]*//' | tr -d '[:space:]')

# ---------- P166 key derivation (primary: from prompt; fallback: from agent emit) ----------
KEY=$(derive_external_comms_key_from_prompt "$PROMPT")
if [ -z "$KEY" ]; then
  # Backward-compat: cached old SKILL.md still instructs the agent to emit
  # EXTERNAL_COMMS_VOICE_TONE_KEY. Honour it during the deprecation window.
  KEY_LINE=$(echo "$AGENT_OUTPUT" | grep -E '^EXTERNAL_COMMS_VOICE_TONE_KEY:' | tail -1) || true
  KEY=$(echo "$KEY_LINE" | sed 's/^EXTERNAL_COMMS_VOICE_TONE_KEY:[[:space:]]*//' | tr -d '[:space:]')
fi

# Validate key: 64 hex chars (sha256 output). Reject anything else.
if echo "$KEY" | grep -qE '^[0-9a-f]{64}$'; then
  case "$VERDICT" in
    PASS) touch "${RDIR}/external-comms-voice-tone-reviewed-${KEY}" ;;
    FAIL) ;; # Do NOT create marker — draft must be revised
    *) ;;    # Unknown verdict — fail closed
  esac
fi

exit 0
