#!/usr/bin/env bats

# P123: packages/itil/hooks/lib/block-list.sh shared helper for the
# inbound-report block-list mechanism. Per ADR-046 §v1 implementation
# contract — audit-log-only — the helper exposes four functions:
#   is_blocked(<reporter-id-hash>)
#   add_block(<reporter-id-hash> <evidence-ticket-P###> <provenance>)
#   remove_block(<reporter-id-hash> <reason>)
#   list_blocks()
#
# Per ADR-046 §Decision Outcome §Identifier, the entry shape is the
# SHA-256 hash of the GitHub numeric user ID. Per architect verdict
# (this iter), the helper does NOT compute the hash — caller supplies
# an opaque hex string; helper validates hex shape only. This keeps
# the helper GitHub-agnostic so non-GitHub channel adoption (out-of-
# scope per ADR-046 §Reassessment) wouldn't require helper changes.
#
# Audit log: sibling JSONL file `docs/blocked-reporters.audit.jsonl`.
# Append-only; one JSON object per line per the five-field shape
# adopted in ADR-046 Q2: {type, reporter_id_hash, evidence_ticket,
# timestamp, author}.
#
# Per feedback_behavioural_tests.md (P081) — behavioural assertions on
# observable outcomes (file state, exit codes, helper-emitted output).
# No source-grep on helper text. Per ADR-005 (plugin testing strategy)
# + ADR-037 (skill testing strategy) hook bats live under
# packages/itil/hooks/test/ and assert behaviour, not implementation.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HELPER="$SCRIPT_DIR/lib/block-list.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  mkdir -p docs
  # Mirror the per-repo on-disk shape ADR-046 names.
  echo "[]" > docs/blocked-reporters.json
  # Source the helper. Functions become callable in this shell.
  # shellcheck source=/dev/null
  source "$HELPER"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# Canonical fixture hash — 64 hex chars (SHA-256 width). Real callers
# would compute this from a GitHub numeric user ID; the helper does
# not care about provenance, only that the input is hex-shaped.
HASH_A="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
HASH_B="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

# --- Round-trip: add_block then is_blocked ---

@test "add_block + is_blocked round-trip: hash present after add" {
  add_block "$HASH_A" "P123" "test@example.com"
  run is_blocked "$HASH_A"
  [ "$status" -eq 0 ]
}

@test "is_blocked: returns non-zero for hash never added" {
  run is_blocked "$HASH_B"
  [ "$status" -ne 0 ]
}

# --- list_blocks output shape ---

@test "list_blocks: prints each blocked hash on its own line" {
  add_block "$HASH_A" "P123" "test@example.com"
  add_block "$HASH_B" "P124" "test@example.com"
  run list_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"$HASH_A"* ]]
  [[ "$output" == *"$HASH_B"* ]]
  # Two distinct hashes — output should have at least two non-empty lines.
  line_count=$(printf '%s\n' "$output" | grep -c .)
  [ "$line_count" -ge 2 ]
}

@test "list_blocks: empty list on empty docs/blocked-reporters.json" {
  run list_blocks
  [ "$status" -eq 0 ]
  # No hash strings; either empty output or whitespace only.
  [[ "$output" != *"$HASH_A"* ]]
  [[ "$output" != *"$HASH_B"* ]]
}

# --- Idempotent add ---

@test "add_block: adding the same hash twice is idempotent (one entry)" {
  add_block "$HASH_A" "P123" "test@example.com"
  add_block "$HASH_A" "P123" "test@example.com"
  run list_blocks
  [ "$status" -eq 0 ]
  occurrences=$(printf '%s\n' "$output" | grep -c "$HASH_A")
  [ "$occurrences" -eq 1 ]
}

# --- remove_block path ---

@test "remove_block: hash absent from is_blocked after remove" {
  add_block "$HASH_A" "P123" "test@example.com"
  remove_block "$HASH_A" "wrongly-classified"
  run is_blocked "$HASH_A"
  [ "$status" -ne 0 ]
}

# --- Audit log presence (ADR-046 Q2 five-field shape) ---

@test "add_block: appends entry to docs/blocked-reporters.audit.jsonl" {
  add_block "$HASH_A" "P123" "test@example.com"
  [ -f docs/blocked-reporters.audit.jsonl ]
  run cat docs/blocked-reporters.audit.jsonl
  [[ "$output" == *"\"type\""* ]]
  [[ "$output" == *"\"block\""* ]]
  [[ "$output" == *"$HASH_A"* ]]
  [[ "$output" == *"P123"* ]]
  [[ "$output" == *"test@example.com"* ]]
  # Five-field shape names: type, reporter_id_hash, evidence_ticket,
  # timestamp, author. Assert each label is present.
  [[ "$output" == *"reporter_id_hash"* ]]
  [[ "$output" == *"evidence_ticket"* ]]
  [[ "$output" == *"timestamp"* ]]
  [[ "$output" == *"author"* ]]
}

@test "remove_block: appends an unblock entry to the audit log" {
  add_block "$HASH_A" "P123" "test@example.com"
  remove_block "$HASH_A" "wrongly-classified"
  run cat docs/blocked-reporters.audit.jsonl
  [[ "$output" == *"\"unblock\""* ]]
  # The reason field rides under evidence_ticket per the five-field shape
  # (audit log is type-tagged; the reason slot reuses evidence_ticket
  # for unblock provenance per the helper's contract).
  [[ "$output" == *"wrongly-classified"* ]]
}

# --- Hashed-ID handling: helper validates hex shape ---

@test "add_block: rejects non-hex input (non-zero exit, no entry written)" {
  run add_block "not-a-hash" "P123" "test@example.com"
  [ "$status" -ne 0 ]
  # State unchanged.
  run is_blocked "not-a-hash"
  [ "$status" -ne 0 ]
}

@test "add_block: rejects wrong-length hex (non-SHA-256-width input)" {
  # 32 hex chars (half of SHA-256 width) — wrong length.
  run add_block "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" "P123" "test@example.com"
  [ "$status" -ne 0 ]
}
