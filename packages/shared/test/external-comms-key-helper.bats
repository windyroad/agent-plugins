#!/usr/bin/env bats
# Behavioural tests for packages/shared/hooks/lib/external-comms-key.sh
# (P166 — hook-side key derivation; ADR-028 amended 2026-05-16).
#
# Contract: derive_external_comms_key_from_prompt reads an agent-prompt
# string and extracts the canonical (DRAFT, SURFACE) pair from
# `SURFACE: <name>` line + `<draft>...</draft>` block, then emits
# sha256(DRAFT + '\n' + SURFACE) — agreeing with the gate's marker key.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  LIB="$REPO_ROOT/packages/shared/hooks/lib/external-comms-key.sh"
}

# Helper: run the function in a subshell with a fresh shell env.
derive() {
  local prompt="$1"
  bash -c "source '$LIB' && derive_external_comms_key_from_prompt \"\$1\"" _ "$prompt"
}

# Gate-side reference key — replicates external-comms-gate.sh line 229.
gate_key() {
  local draft="$1" surface="$2"
  printf '%s\n%s' "$draft" "$surface" | shasum -a 256 | cut -d' ' -f1
}

@test "derives key from well-formed prompt matching gate computation" {
  PROMPT=$'SURFACE: changeset-author\n<draft>\nfix the build on Node 20\n</draft>\nReview this for confidential info.'
  KEY=$(derive "$PROMPT")
  EXPECTED=$(gate_key "fix the build on Node 20" "changeset-author")
  [ "$KEY" = "$EXPECTED" ]
}

@test "handles multi-line draft body with blank lines verbatim" {
  DRAFT=$'first line\n\nthird line after blank'
  PROMPT=$'SURFACE: gh-issue-create\n<draft>\n'"$DRAFT"$'\n</draft>'
  KEY=$(derive "$PROMPT")
  EXPECTED=$(gate_key "$DRAFT" "gh-issue-create")
  [ "$KEY" = "$EXPECTED" ]
}

@test "handles draft containing brackets and angle brackets that are not </draft>" {
  DRAFT="text with <a href=\"x\"> and [brackets] inside"
  PROMPT=$'SURFACE: gh-pr-comment\n<draft>\n'"$DRAFT"$'\n</draft>'
  KEY=$(derive "$PROMPT")
  EXPECTED=$(gate_key "$DRAFT" "gh-pr-comment")
  [ "$KEY" = "$EXPECTED" ]
}

@test "returns empty string when SURFACE line absent" {
  PROMPT=$'<draft>\nsome body\n</draft>'
  KEY=$(derive "$PROMPT")
  [ -z "$KEY" ]
}

@test "returns empty string when <draft> block absent" {
  PROMPT=$'SURFACE: changeset-author\nReview this body inline: hello'
  KEY=$(derive "$PROMPT")
  [ -z "$KEY" ]
}

@test "returns empty string for empty prompt" {
  KEY=$(derive "")
  [ -z "$KEY" ]
}

@test "key length is 64 hex chars when derivation succeeds" {
  PROMPT=$'SURFACE: npm-publish\n<draft>\nREADME diff line\n</draft>'
  KEY=$(derive "$PROMPT")
  [ "${#KEY}" -eq 64 ]
  [[ "$KEY" =~ ^[0-9a-f]{64}$ ]]
}

@test "surface name extraction stops at whitespace (no trailing content captured)" {
  PROMPT=$'SURFACE: gh-issue-edit some-trailing-stuff\n<draft>\nbody\n</draft>'
  KEY=$(derive "$PROMPT")
  # Surface should be "gh-issue-edit" only; trailing text ignored.
  EXPECTED=$(gate_key "body" "gh-issue-edit")
  [ "$KEY" = "$EXPECTED" ]
}

@test "ignores SURFACE: lines that are not at line-start (e.g. indented or in prose)" {
  # If SURFACE: appears mid-prose (not anchored to line start), the line-start
  # constraint of the parser should reject it. Without a valid SURFACE line,
  # derivation returns empty.
  PROMPT=$'context says SURFACE: should-not-match\n<draft>\nbody\n</draft>'
  KEY=$(derive "$PROMPT")
  [ -z "$KEY" ]
}
