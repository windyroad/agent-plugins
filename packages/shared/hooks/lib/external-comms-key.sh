#!/bin/bash
# Shared helper: derive the external-comms marker key from an agent's
# tool_input.prompt by extracting the structured `SURFACE: <name>` line
# and `<draft>...</draft>` block, then computing the canonical key via
# compute_external_comms_key — the same key shape the gate computes at
# PreToolUse time (external-comms-gate.sh).
#
# P166 + ADR-028 amended 2026-05-16: the PostToolUse:Agent mark hook
# derives the marker key from observed runtime state instead of trusting
# an agent-emitted EXTERNAL_COMMS_<EVAL>_KEY line. Removes the
# double-invocation cost class — single fire per gate cycle suffices.
#
# P010 + ADR-028 amended 2026-05-25: the marker key is computed via the
# SINGLE canonical normalization in compute_external_comms_key, shared
# byte-for-byte between the gate (PreToolUse) and this mark-hook helper
# (PostToolUse). The normalization strips the changeset YAML frontmatter
# block before hashing (the gate sees the FULL Write content incl.
# frontmatter; the agent wraps only the body in <draft>) and applies a
# single canonical trailing-whitespace strip so the two sides cannot
# diverge. Fixes the deny-after-PASS marker-key mismatch (P198 / #149).
#
# Canonical source: packages/shared/hooks/lib/external-comms-key.sh
# Synced byte-identically into each consumer plugin's hooks/lib/ via
# scripts/sync-external-comms-gate.sh (ADR-017 duplicate-script pattern).

# ---------------------------------------------------------------------------
# compute_external_comms_key <draft> <surface>
#
# THE single source of truth for the external-comms marker key. Both the
# PreToolUse gate and the PostToolUse mark hook compute the key through
# this function so they hash byte-identical input (ADR-028 amended
# 2026-05-25). Echoes the 64-char lowercase sha256 hex on stdout.
#
# normalize(draft, surface):
#   - changeset-author surface: strip the leading YAML frontmatter block
#     (`---\n...\n---\n` plus the blank line after it). Changeset files
#     carry `---\n"@windyroad/x": minor\n---\n\n<body>`; the gate sees the
#     whole thing via tool_input.content while the agent wraps only the
#     <body> in <draft>. Stripping frontmatter makes the two inputs equal.
#     All other surfaces (gh-*, npm-publish) are already body-only via the
#     gate's --body / --field extraction, so they are left unchanged.
#   - all surfaces: rstrip ALL trailing whitespace. This single canonical
#     newline normalization subsumes both the gate's `$()` trailing-newline
#     strip and this helper's `<draft>` regex single-newline strip, so the
#     two sides are provably symmetric on trailing whitespace.
#   key = sha256(normalize(draft, surface) + '\n' + surface)
# ---------------------------------------------------------------------------
compute_external_comms_key() {
    local draft="$1" surface="$2"
    EXTCOMMS_DRAFT="$draft" EXTCOMMS_SURFACE="$surface" python3 -c "
import os, re, hashlib
draft = os.environ.get('EXTCOMMS_DRAFT', '')
surface = os.environ.get('EXTCOMMS_SURFACE', '')
# changeset-author: strip the leading YAML frontmatter block + blank line.
if surface == 'changeset-author':
    draft = re.sub(r'^---\n.*?\n---\n\n?', '', draft, count=1, flags=re.DOTALL)
# Substance-aware whitespace normalization (P276 / ADR-009 + ADR-028 amended
# 2026-06-06). Tolerate trivial PASS-class reformatting so a marker survives
# interior CRLF/CR line endings and per-line trailing whitespace — the same
# normalization _substance_normalize_then_hash (gate-helpers.sh) applies to
# the policy-file-drift gates. Conservative boundary preserved: single-numeral
# edits and frontmatter-key changes stay substantive (key changes → review
# re-fires), so the leak-detection guarantee is never weakened.
#   1. CRLF / CR -> LF
#   2. strip trailing whitespace per line
#   3. strip trailing whitespace of the whole draft (subsumes the prior
#      single-canonical rstrip; NO trailing '\n' is appended here so the key
#      shape sha256(normalize(draft) + '\n' + surface) is byte-stable for
#      already-clean drafts — existing markers and keys do not shift).
draft = draft.replace('\r\n', '\n').replace('\r', '\n')
draft = '\n'.join(line.rstrip() for line in draft.split('\n')).rstrip()
print(hashlib.sha256((draft + '\n' + surface).encode('utf-8')).hexdigest())
" 2>/dev/null
}

# ---------------------------------------------------------------------------
# derive_external_comms_key_from_prompt <prompt>
#
# Extracts the (SURFACE, draft-body) pair from an agent prompt's structured
# `SURFACE: <name>` line + `<draft>...</draft>` block, then delegates to
# compute_external_comms_key so the normalization lives in exactly one place.
#
# Returns the 64-char hex sha256 on stdout when both markers are present in
# the prompt. Returns empty string when either marker is absent — the caller
# falls back to the agent-emitted KEY for backward compatibility with cached
# old SKILL.md / agent prompts.
# ---------------------------------------------------------------------------
derive_external_comms_key_from_prompt() {
    local prompt="$1"
    [ -n "$prompt" ] || { echo ""; return 0; }
    # Extract SURFACE + <draft> body in one pass. The two fields are emitted
    # \x1f-separated (ASCII unit separator) so a body containing newlines — or
    # an empty body — round-trips through command substitution intact (only
    # trailing newlines are dropped, which compute_external_comms_key rstrips
    # anyway). Empty output when either marker is absent → empty key.
    local extracted
    extracted=$(printf '%s' "$prompt" | python3 -c "
import sys, re
text = sys.stdin.read()
# DRAFT: non-greedy match between <draft>...</draft>, tolerating an optional
# newline immediately after <draft> and before </draft>.
draft_match = re.search(r'<draft>\n?(.*?)\n?</draft>', text, re.DOTALL)
# SURFACE: anchored to line start (MULTILINE) so prose like 'context says
# SURFACE: x' does not match. Surface name is a single letter+word/hyphen token.
surface_match = re.search(r'^SURFACE:\s*([A-Za-z][\w-]*)', text, re.MULTILINE)
if not draft_match or not surface_match:
    sys.exit(0)
sys.stdout.write(surface_match.group(1) + '\x1f' + draft_match.group(1))
" 2>/dev/null) || extracted=""
    [ -n "$extracted" ] || { echo ""; return 0; }
    local surface="${extracted%%$'\x1f'*}"
    local body="${extracted#*$'\x1f'}"
    compute_external_comms_key "$body" "$surface"
}
