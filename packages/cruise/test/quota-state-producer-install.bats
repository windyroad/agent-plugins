#!/usr/bin/env bats
# Behavioural tests for the self-installing quota-state producer (ADR-097/STORY-043).
# HOME is redirected to a temp dir so nothing touches the real ~/.claude.

setup() {
  INST="${BATS_TEST_DIRNAME}/../hooks/quota-state-producer-install.sh"
  export HOME="$(mktemp -d)"
  mkdir -p "$HOME/.claude"
  SL="$HOME/.claude/statusline-command.sh"
  SETTINGS="$HOME/.claude/settings.json"
  PAYLOAD='{"context_window":{"used_percentage":30},"rate_limits":{"five_hour":{"used_percentage":42,"resets_at":1783700000},"seven_day":{"used_percentage":55,"resets_at":1784200000}}}'
}
teardown() { rm -rf "$HOME"; }

@test "absent statusline → creates it, makes it executable, and wires settings.json" {
  run bash "$INST" </dev/null
  [ "$status" -eq 0 ]
  [ -x "$SL" ]
  grep -q "@windyroad/cruise" "$SL"
  [ "$(jq -r '.statusLine.command' "$SETTINGS")" = "$SL" ]
}

@test "the created statusline writes a flat quota cache from a rate_limits payload" {
  bash "$INST" </dev/null
  echo "$PAYLOAD" | bash "$SL" >/dev/null 2>&1
  [ -f "$HOME/.claude/quota-state.json" ]
  [ "$(jq -r '.five_used_pct' "$HOME/.claude/quota-state.json")" = "42" ]
  [ "$(jq -r '.week_used_pct' "$HOME/.claude/quota-state.json")" = "55" ]
}

@test "idempotent: re-running does not modify the already-producing statusline" {
  bash "$INST" </dev/null
  before="$(cat "$SL")"
  run bash "$INST" </dev/null           # now a producer (writes quota-state.json) → no-op
  [ "$status" -eq 0 ]
  [ "$(cat "$SL")" = "$before" ]
}

@test "existing producer statusline (writes the cache) → no-op, not overwritten" {
  printf '#!/bin/bash\n# writes quota-state.json already\necho hi\n' > "$SL"
  before="$(cat "$SL")"
  run bash "$INST" </dev/null
  [ "$status" -eq 0 ]; [ "$(cat "$SL")" = "$before" ]
}

@test "present non-producer statusline → agent-merge JSON, statusline UNTOUCHED (no blind append)" {
  printf '#!/bin/bash\ninput=$(cat)\necho hi\n' > "$SL"
  before="$(cat "$SL")"
  run bash "$INST" </dev/null
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null   # valid agent-merge JSON
  [ "$(cat "$SL")" = "$before" ]                                              # never blind-appended
  [ -f "$HOME/.claude/.cruise-producer-merge-nudged" ]
}

@test "agent-merge nudge fires at most once (marker guard)" {
  printf '#!/bin/bash\ninput=$(cat)\necho hi\n' > "$SL"
  bash "$INST" </dev/null >/dev/null                 # first: nudges + writes marker
  run bash "$INST" </dev/null                        # second: marker present → silent no-op
  [ "$status" -eq 0 ]; [ -z "$output" ]
}
