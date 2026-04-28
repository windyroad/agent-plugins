#!/bin/bash
# P123: shared block-list helper for the inbound-report block mechanism.
# Per ADR-046 §v1 implementation contract — audit-log-only.
#
# Functions:
#   is_blocked(<reporter-id-hash>)
#     Exit 0 if the hash is present in $BLOCK_LIST_FILE; non-zero otherwise.
#   add_block(<reporter-id-hash> <evidence-ticket-P###> <provenance>)
#     Validate hex-shape on the hash; append to $BLOCK_LIST_FILE if absent
#     (idempotent); append a `block`-typed entry to $AUDIT_LOG_FILE.
#   remove_block(<reporter-id-hash> <reason>)
#     Remove the hash from $BLOCK_LIST_FILE if present; append an
#     `unblock`-typed entry to $AUDIT_LOG_FILE recording the reason.
#   list_blocks()
#     Print all currently-blocked hashes, one per line.
#
# Helper does NOT compute hashes. Caller supplies an opaque hex string;
# the helper validates SHA-256-width hex shape (64 chars, [0-9a-f]).
# Rationale (architect verdict, this iter): keeping the helper GitHub-
# agnostic means non-GitHub channel adoption (out-of-scope per ADR-046
# §Reassessment) wouldn't require helper changes — only the hashing
# step on the caller side would differ.
#
# Persistence:
#   $BLOCK_LIST_FILE — default `docs/blocked-reporters.json`. JSON array
#                      of hash strings. Tracked in git per ADR-046.
#   $AUDIT_LOG_FILE  — default `docs/blocked-reporters.audit.jsonl`.
#                      One JSON object per line (append-only). Five-field
#                      shape per ADR-046 Q2: type, reporter_id_hash,
#                      evidence_ticket, timestamp, author.
#
# Both file paths are relative to the caller's CWD so test fixtures
# can drop a temp `docs/` dir in $TEST_DIR. Production callers run
# from the repo root; same shape applies.
#
# Dependencies: `jq` for JSON read/write. `python3` is acceptable as a
# fallback if jq is not available, but the audit log JSONL emission
# uses bash printf for atomicity (one printf per line — no parse-write
# cycle for append).
#
# References:
#   ADR-005 — plugin testing strategy (helper bats live alongside).
#   ADR-014 — governance skills commit their own work (this helper is
#             called by future P079 / report-upstream consumers; their
#             commits include the block-list mutation).
#   ADR-017 — shared-code-sync pattern (helper ships ahead of consumers).
#   ADR-022 — verification-pending status (P123 ships audit-log-only,
#             transitions to verifying; full enforcement in future iters).
#   ADR-029 — diagnose before implement (ADR-046 is the diagnosis).
#   ADR-030 — repo-local skills / per-repo artefact precedent.
#   ADR-037 — skill testing strategy (this is hook-shared-helper, not
#             skill content; bats partition under hooks/test/).
#   ADR-046 — blocked-reporters persistence (proposed → accepted with
#             this iter); §v1 implementation contract names this helper.
#   P123    — primary ticket.

# Default paths — caller's CWD relative. Override for tests by exporting
# BLOCK_LIST_FILE / AUDIT_LOG_FILE before sourcing.
: "${BLOCK_LIST_FILE:=docs/blocked-reporters.json}"
: "${AUDIT_LOG_FILE:=docs/blocked-reporters.audit.jsonl}"

# SHA-256 hex width (64 chars). Helper rejects any input that doesn't
# match this shape — per architect verdict, we don't allow alternate
# hash widths in v1 (single-shape contract is simpler to reason about
# and the JTBD-101 "decide once, encode it" pattern wins here).
_BLOCK_LIST_HASH_RE='^[0-9a-f]{64}$'

# Validate that a string is SHA-256-width hex. Returns 0 on match.
_block_list_validate_hash() {
  local hash="$1"
  [[ "$hash" =~ $_BLOCK_LIST_HASH_RE ]]
}

# Ensure the block-list file exists with an empty array on first use.
# Idempotent — repeated calls leave existing content alone.
_block_list_ensure_file() {
  if [ ! -f "$BLOCK_LIST_FILE" ]; then
    mkdir -p "$(dirname "$BLOCK_LIST_FILE")"
    printf '[]\n' > "$BLOCK_LIST_FILE"
  fi
}

# Append one JSONL audit-log entry. Five-field shape per ADR-046 Q2.
# `evidence_ticket` carries the reason string for unblock entries
# (type-tagged; the unblock reason reuses the same slot).
_block_list_audit_append() {
  local type="$1"
  local hash="$2"
  local evidence="$3"
  local author="$4"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$(dirname "$AUDIT_LOG_FILE")"
  # JSON-escape the evidence and author fields. Both are user-supplied
  # strings; backslash + double-quote are the load-bearing chars.
  local evidence_esc author_esc
  evidence_esc=${evidence//\\/\\\\}
  evidence_esc=${evidence_esc//\"/\\\"}
  author_esc=${author//\\/\\\\}
  author_esc=${author_esc//\"/\\\"}
  printf '{"type":"%s","reporter_id_hash":"%s","evidence_ticket":"%s","timestamp":"%s","author":"%s"}\n' \
    "$type" "$hash" "$evidence_esc" "$timestamp" "$author_esc" \
    >> "$AUDIT_LOG_FILE"
}

# Returns 0 if the hash is currently in the block list; non-zero
# otherwise. Empty/missing block list => non-zero.
is_blocked() {
  local hash="$1"
  [ -n "$hash" ] || return 1
  _block_list_validate_hash "$hash" || return 1
  [ -f "$BLOCK_LIST_FILE" ] || return 1
  # Use jq if available; fall back to grep-on-quoted-hash if not.
  if command -v jq >/dev/null 2>&1; then
    jq -e --arg h "$hash" 'index([$h]) != null' "$BLOCK_LIST_FILE" >/dev/null 2>&1
  else
    grep -Fq "\"$hash\"" "$BLOCK_LIST_FILE"
  fi
}

# Add a hash to the block list. Idempotent (re-adding same hash is
# a no-op on the list file but DOES emit an audit entry — re-blocks
# are themselves audit events). Returns 0 on success / no-op,
# non-zero on input validation failure.
add_block() {
  local hash="$1"
  local evidence="$2"
  local author="$3"
  [ -n "$hash" ] || return 2
  _block_list_validate_hash "$hash" || return 2
  _block_list_ensure_file
  if is_blocked "$hash"; then
    # Idempotent — already present. Do not duplicate the list entry.
    # Skip the audit entry too: per the "one entry per hash" idempotency
    # contract the bats asserts, the audit log's add-record stays a
    # single line for a single hash.
    return 0
  fi
  if command -v jq >/dev/null 2>&1; then
    local tmp
    tmp=$(mktemp)
    jq --arg h "$hash" '. + [$h]' "$BLOCK_LIST_FILE" > "$tmp" && mv "$tmp" "$BLOCK_LIST_FILE"
  else
    # Fallback: simple JSON-array textual edit. Strip trailing `]`,
    # append `, "<hash>"]` or `"<hash>"]` for empty arrays.
    local content
    content=$(cat "$BLOCK_LIST_FILE")
    if [[ "$content" =~ ^\[\ *\]\ *$ ]]; then
      printf '["%s"]\n' "$hash" > "$BLOCK_LIST_FILE"
    else
      # Replace closing `]` with `,"<hash>"]`.
      printf '%s' "$content" | sed "s/\]\s*\$/,\"$hash\"]/" > "$BLOCK_LIST_FILE"
      printf '\n' >> "$BLOCK_LIST_FILE"
    fi
  fi
  _block_list_audit_append "block" "$hash" "$evidence" "$author"
}

# Remove a hash from the block list. Appends an `unblock` audit entry
# regardless of whether the hash was present (so attempted-unblock-of-
# never-blocked is itself audit-trail-recorded). Returns 0 on success,
# non-zero on input validation failure.
remove_block() {
  local hash="$1"
  local reason="$2"
  [ -n "$hash" ] || return 2
  _block_list_validate_hash "$hash" || return 2
  _block_list_ensure_file
  if command -v jq >/dev/null 2>&1; then
    local tmp
    tmp=$(mktemp)
    jq --arg h "$hash" '. - [$h]' "$BLOCK_LIST_FILE" > "$tmp" && mv "$tmp" "$BLOCK_LIST_FILE"
  else
    # Fallback: textual remove of `"<hash>"` and any adjacent comma.
    sed -i.bak -e "s/,\"$hash\"//g" -e "s/\"$hash\",//g" -e "s/\"$hash\"//g" "$BLOCK_LIST_FILE"
    rm -f "${BLOCK_LIST_FILE}.bak"
  fi
  _block_list_audit_append "unblock" "$hash" "$reason" ""
}

# Print all currently-blocked hashes, one per line. Empty list prints
# nothing. Returns 0 always (empty is a valid state).
list_blocks() {
  [ -f "$BLOCK_LIST_FILE" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -r '.[]' "$BLOCK_LIST_FILE" 2>/dev/null
  else
    # Fallback: extract `"<hash>"` substrings from the array.
    grep -oE '"[0-9a-f]{64}"' "$BLOCK_LIST_FILE" | tr -d '"'
  fi
}
