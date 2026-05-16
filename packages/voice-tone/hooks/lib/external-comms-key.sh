#!/bin/bash
# Shared helper: derive the external-comms marker key from an agent's
# tool_input.prompt by extracting the structured `SURFACE: <name>` line
# and `<draft>...</draft>` block, then computing
# sha256(DRAFT + '\n' + SURFACE) — the same key shape the gate computes
# at PreToolUse time (external-comms-gate.sh line 229).
#
# P166 + ADR-028 amended 2026-05-16: the PostToolUse:Agent mark hook
# derives the marker key from observed runtime state instead of trusting
# an agent-emitted EXTERNAL_COMMS_<EVAL>_KEY line. Removes the
# double-invocation cost class — single fire per gate cycle suffices.
#
# Canonical source: packages/shared/hooks/lib/external-comms-key.sh
# Synced byte-identically into each consumer plugin's hooks/lib/ via
# scripts/sync-external-comms-gate.sh (ADR-017 duplicate-script pattern).
#
# Returns the 64-char hex sha256 on stdout when both markers are present
# in the prompt. Returns empty string when either marker is absent — the
# caller falls back to the agent-emitted KEY for backward compatibility
# with cached old SKILL.md / agent prompts.

derive_external_comms_key_from_prompt() {
    local prompt="$1"
    [ -n "$prompt" ] || { echo ""; return 0; }
    printf '%s' "$prompt" | python3 -c "
import sys, re, hashlib
text = sys.stdin.read()
# DRAFT extraction: non-greedy match between <draft>...</draft>.
# Tolerates an optional newline immediately after <draft> and before </draft>
# so the body content does not capture wrapping newlines.
draft_match = re.search(r'<draft>\n?(.*?)\n?</draft>', text, re.DOTALL)
# SURFACE extraction: must be anchored to line start (MULTILINE) to avoid
# matching prose like 'context says SURFACE: x'. Surface name is a single
# token: letter + word/hyphen chars.
surface_match = re.search(r'^SURFACE:\s*([A-Za-z][\w-]*)', text, re.MULTILINE)
if not draft_match or not surface_match:
    print('')
    sys.exit(0)
draft = draft_match.group(1)
surface = surface_match.group(1)
payload = (draft + '\n' + surface).encode('utf-8')
print(hashlib.sha256(payload).hexdigest())
" 2>/dev/null
}
