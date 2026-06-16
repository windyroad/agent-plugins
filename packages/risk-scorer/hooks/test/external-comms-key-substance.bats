#!/usr/bin/env bats
# Behavioural tests for compute_external_comms_key substance-aware draft
# normalization (P276 — external-comms gate marker over-fires on PASS-class
# content edits).
#
# Contract (ADR-009 + ADR-028 amended 2026-06-06, ratified): the marker key
# must survive TRIVIAL whitespace-class edits to the draft body — interior
# CRLF/CR line endings and per-line trailing whitespace — so a PASS review
# does not have to re-fire on a no-op reformat. The conservative boundary is
# preserved: single-numeral edits and frontmatter-key changes remain
# SUBSTANTIVE (the key changes → review re-fires) so the leak-detection
# guarantee is never weakened.
#
# These exercise compute_external_comms_key directly (its stdout = the 64-char
# sha256 key) — behavioural assertions on the function's output, not a
# structural grep of the source.

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  # shellcheck source=../lib/external-comms-key.sh
  source "$HOOKS_DIR/lib/external-comms-key.sh"
}

# ---------- Trivial edits must NOT change the key (P276) ----------

@test "P276: interior CRLF line endings produce the same key as LF" {
  lf=$(compute_external_comms_key $'Line one\nLine two\nLine three' 'gh-issue-comment')
  crlf=$(compute_external_comms_key $'Line one\r\nLine two\r\nLine three' 'gh-issue-comment')
  [ -n "$lf" ]
  [ "$lf" = "$crlf" ]
}

@test "P276: per-line trailing whitespace produces the same key as clean lines" {
  clean=$(compute_external_comms_key $'Line one\nLine two' 'gh-issue-comment')
  trailing=$(compute_external_comms_key $'Line one   \nLine two\t' 'gh-issue-comment')
  [ -n "$clean" ]
  [ "$clean" = "$trailing" ]
}

@test "P276: trailing whitespace at end of draft produces the same key (regression guard for prior rstrip)" {
  clean=$(compute_external_comms_key 'A short draft body' 'gh-issue-comment')
  trailed=$(compute_external_comms_key $'A short draft body\n\n  ' 'gh-issue-comment')
  [ "$clean" = "$trailed" ]
}

# ---------- Conservative boundary: substantive edits MUST change the key ----------

@test "P276 boundary: a single-numeral edit changes the key (review re-fires)" {
  before=$(compute_external_comms_key 'We support 12 plugins today' 'gh-issue-comment')
  after=$(compute_external_comms_key 'We support 11 plugins today' 'gh-issue-comment')
  [ "$before" != "$after" ]
}

@test "P276 boundary: a word/content edit changes the key (review re-fires)" {
  before=$(compute_external_comms_key 'The release is ready' 'gh-issue-comment')
  after=$(compute_external_comms_key 'The release is delayed' 'gh-issue-comment')
  [ "$before" != "$after" ]
}

# ---------- Surface binding + changeset frontmatter strip preserved ----------

@test "P276: the surface remains part of the key (same body, different surface → different key)" {
  a=$(compute_external_comms_key 'Same body text' 'gh-issue-comment')
  b=$(compute_external_comms_key 'Same body text' 'gh-pr-comment')
  [ "$a" != "$b" ]
}

@test "P276: changeset frontmatter strip still holds — full content keys equal the body-only key" {
  body=$'Add the substance-aware normalization to the external-comms key.'
  full=$'---\n"@windyroad/risk-scorer": patch\n---\n\n'"$body"
  body_key=$(compute_external_comms_key "$body" 'changeset-author')
  full_key=$(compute_external_comms_key "$full" 'changeset-author')
  [ "$body_key" = "$full_key" ]
}
