#!/bin/bash
# Shared portable helpers for gate enforcement hooks.
# Sourced by architect-gate.sh, risk-gate.sh, and all hook scripts.
# Provides: _mtime, _hashcmd, _doc_exclusions, _err_trap, _get_*

# ---------------------------------------------------------------------------
# Portable utilities
# ---------------------------------------------------------------------------

# Portable mtime: tries GNU stat, falls back to macOS stat
_mtime() { stat -c%Y "$1" 2>/dev/null || /usr/bin/stat -f%m "$1" 2>/dev/null || echo 0; }

# Portable hash: tries md5sum, falls back to md5 -r, then shasum
_hashcmd() { md5sum 2>/dev/null || md5 -r 2>/dev/null || shasum 2>/dev/null; }

# ---------------------------------------------------------------------------
# Substance-aware drift hash + atomic verdict-write (ADR-009 amendment
# 2026-06-06, P353 + P303 close).
#
# `_substance_hash_path` normalises trivial/no-op edits BEFORE hashing so a
# PASS marker survives whitespace / CRLF / trailing-newline edits while still
# detecting substantive policy changes. Conservative boundary: when in doubt
# whether an edit is trivial vs substantive, this helper treats it as
# substantive (re-review fires). Only whitespace + line-ending + trailing-
# newline are normalised in this iteration — single-numeral edits and
# frontmatter-key changes are intentionally NOT normalised. See ADR-009
# 2026-06-06 amendment for the ratified contract.
#
# `_atomic_mark_with_hash` writes the marker + hash file as an atomic pair
# (mktemp + mv) so a PASS NEVER silently fails to persist (the empirically-
# measured P353 failure mode that forced BYPASS_RISK_GATE=1 on every
# external-comms gate clearance). Either both files land, or neither does.
# Non-zero exit on failure so callers can emit a diagnostic.
# ---------------------------------------------------------------------------

# Substance-aware hash of a file or directory path.
# For directories: hashes the concatenated content of all *.md files
# (excluding README.md) in sorted order.
# For files: hashes the file content.
# Normalisation BEFORE hashing: CRLF → LF, strip trailing whitespace per
# line, normalise trailing whitespace to a single \n.
# Echoes "missing" for paths that do not exist (drop-in equivalence with the
# pre-amendment `cat | _hashcmd | cut -d' ' -f1` site behaviour).
# Echoes a hex sha256 of the normalised content on success.
_substance_hash_path() {
    local path="$1"
    if [ -z "$path" ]; then
        echo "missing"
        return 0
    fi
    if [ -f "$path" ]; then
        cat "$path" 2>/dev/null | _substance_normalize_then_hash
    elif [ -d "$path" ]; then
        find "$path" -name '*.md' -not -name 'README.md' -print0 \
            | sort -z \
            | xargs -0 cat 2>/dev/null \
            | _substance_normalize_then_hash
    else
        echo "missing"
    fi
}

# Internal: reads from stdin, normalises whitespace + line endings, emits a
# hex sha256 of the normalised content. Conservative boundary documented in
# ADR-009 2026-06-06 amendment: ambiguous edits stay substantive.
_substance_normalize_then_hash() {
    python3 -c "
import sys, hashlib
data = sys.stdin.buffer.read().decode('utf-8', errors='replace')
# CRLF / CR -> LF
data = data.replace('\r\n', '\n').replace('\r', '\n')
# Strip trailing whitespace per line.
lines = [line.rstrip() for line in data.split('\n')]
# Re-join and normalise trailing whitespace to a single \n.
normalised = '\n'.join(lines).rstrip() + '\n'
print(hashlib.sha256(normalised.encode('utf-8')).hexdigest())
" 2>/dev/null || echo "missing"
}

# Atomically write a presence marker + its paired hash file. Either both
# files land or neither does. Returns 0 on success, 1 on failure. On failure
# any partial state is rolled back.
# Usage: _atomic_mark_with_hash "/tmp/architect-reviewed-${SID}" "$HASH"
_atomic_mark_with_hash() {
    local marker="$1"
    local hash="$2"
    local hash_file="${marker}.hash"

    if [ -z "$marker" ]; then
        return 1
    fi

    local htmp="${hash_file}.tmp.$$.${RANDOM:-0}"
    local mtmp="${marker}.tmp.$$.${RANDOM:-0}"

    # Write hash to tempfile.
    if ! printf '%s\n' "$hash" > "$htmp" 2>/dev/null; then
        rm -f "$htmp"
        return 1
    fi
    # Write empty marker to tempfile.
    if ! : > "$mtmp" 2>/dev/null; then
        rm -f "$htmp" "$mtmp"
        return 1
    fi
    # Atomic rename: hash file first.
    if ! mv -f "$htmp" "$hash_file" 2>/dev/null; then
        rm -f "$htmp" "$mtmp"
        return 1
    fi
    # Atomic rename: marker second. If this fails, roll back the hash file
    # so we never observe a hash-without-marker half-state.
    if ! mv -f "$mtmp" "$marker" 2>/dev/null; then
        rm -f "$mtmp"
        rm -f "$hash_file"
        return 1
    fi
    return 0
}

# Paths excluded from pipeline state hashing and docs-only detection.
_doc_exclusions() {
    echo ':!docs/' ':!.risk-reports/' ':!.changeset/' ':!governance/' ':!.claude/plans/' ':!CLAUDE.md' ':!AGENTS.md' ':!PRINCIPLES.md' ':!DECISION-MANAGEMENT.md' ':!AGENTIC_RISK_REGISTER.md' ':!PROBLEM-MANAGEMENT.md'
}

# ---------------------------------------------------------------------------
# ERR trap: outputs diagnostic JSON on hook errors (P010)
# Usage: source gate-helpers.sh at top of hook, then call _enable_err_trap
# ---------------------------------------------------------------------------

_enable_err_trap() {
    trap '_err_trap_handler "$BASH_SOURCE" "$LINENO" "$BASH_COMMAND"' ERR
}

_err_trap_handler() {
    local script="$1" line="$2" cmd="$3"
    local name
    name=$(basename "$script" 2>/dev/null || echo "$script")
    # Output diagnostic as systemMessage so it's visible in conversation
    cat <<EOF
{
  "systemMessage": "Hook error in ${name} at line ${line}: ${cmd}"
}
EOF
}

# ---------------------------------------------------------------------------
# JSON input parsing: standardised helpers replacing inline python3
# Each reads from _HOOK_INPUT (set by the hook before calling these)
# ---------------------------------------------------------------------------

# Store hook input for reuse by parsing helpers
_HOOK_INPUT=""

_parse_input() {
    _HOOK_INPUT=$(cat)
}

_get_tool_name() {
    echo "$_HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_name', ''))
except:
    print('')
" 2>/dev/null || echo ""
}

_get_session_id() {
    echo "$_HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('session_id', ''))
except:
    print('')
" 2>/dev/null || echo ""
}

_get_command() {
    echo "$_HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo ""
}

_get_file_path() {
    echo "$_HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ti = data.get('tool_input', {})
    print(ti.get('file_path', ti.get('path', '')))
except:
    print('')
" 2>/dev/null || echo ""
}

_get_subagent_type() {
    echo "$_HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('subagent_type', ''))
except:
    print('')
" 2>/dev/null || echo ""
}

_get_user_prompt() {
    echo "$_HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('user_prompt', ''))
except:
    print('')
" 2>/dev/null || echo ""
}

_get_tool_output() {
    echo "$_HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # PostToolUse provides tool_response (dict with content array), not tool_output
    tr = data.get('tool_response', {})
    if isinstance(tr, dict):
        content = tr.get('content', [])
        if isinstance(content, list):
            texts = [c.get('text', '') for c in content if isinstance(c, dict) and c.get('type') == 'text']
            if texts:
                print('\n'.join(texts))
                sys.exit(0)
    # Fallback for older/different hook formats
    print(data.get('tool_output', ''))
except:
    print('')
" 2>/dev/null || echo ""
}

# ---------------------------------------------------------------------------
# Session-scoped tmp directory for risk files
# ---------------------------------------------------------------------------

# Returns the session-scoped directory for risk temp files.
# Creates the directory if it doesn't exist.
# Usage: DIR=$(_risk_dir "$SESSION_ID"); echo "1" > "$DIR/commit"
_risk_dir() {
  local sid="$1"
  local dir="${TMPDIR:-/tmp}/claude-risk-${sid}"
  mkdir -p "$dir"
  echo "$dir"
}

# ---------------------------------------------------------------------------
# Subprocess-completion marker slide (P111, ADR-009 amendment)
# ---------------------------------------------------------------------------

# Slides an existing session-review marker forward on subprocess return,
# treating subprocess wall-clock as continuous parent-session work for TTL
# purposes. Intended for PostToolUse hooks on Agent / Bash that may have
# been long-running subprocesses (Agent-tool delegations, `claude -p`
# iteration subprocesses, run_in_background completions).
#
# Contract:
#   - Touches the marker ONLY if it already exists. NEVER creates a marker
#     (creating requires a real gate review with verdict parsing).
#   - Skips the touch if tool_response.is_error == true. A failed
#     subprocess MUST NOT extend the parent's trust window.
#   - Fail-safe on parse error: if _HOOK_INPUT cannot be parsed, treat as
#     error and skip the touch.
#   - No-op when marker path is empty or marker file does not exist.
#
# Why this is NOT cross-process marker sharing (ADR-032 line 123 invariant):
# the parent's PostToolUse hook touches the parent's OWN marker. The
# subprocess's session id, marker, and gate state are never read or shared.
# This is identical in shape to the existing PreToolUse:Edit slide; only
# the trigger expands to subprocess return.
#
# Usage: slide_marker_on_subprocess_return "/tmp/architect-reviewed-${SESSION_ID}"
slide_marker_on_subprocess_return() {
    local MARKER="$1"
    [ -n "$MARKER" ] || return 0
    [ -f "$MARKER" ] || return 0

    local IS_ERROR
    IS_ERROR=$(echo "$_HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tr = data.get('tool_response', {})
    if isinstance(tr, dict):
        print('true' if tr.get('is_error') is True else 'false')
    else:
        print('false')
except Exception:
    print('true')
" 2>/dev/null || echo "true")

    if [ "$IS_ERROR" = "false" ]; then
        touch "$MARKER"
    fi
}

# ---------------------------------------------------------------------------
# Non-doc file detection for WIP gating
# ---------------------------------------------------------------------------

_is_doc_file() {
    local file_path="$1"
    local EXCL
    EXCL=$(_doc_exclusions)
    for pattern in $EXCL; do
        local clean="${pattern#:!}"
        case "$file_path" in
            *"$clean"*) return 0 ;;
        esac
    done
    case "$file_path" in
        *.claude/*|*.risk-reports/*|*RISK-POLICY.md) return 0 ;;
    esac
    return 1
}
