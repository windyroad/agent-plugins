#!/usr/bin/env bats
# Behavioural tests for the self-installing quota-state producer (ADR-097/STORY-043).
# HOME is redirected to a temp dir so nothing touches the real ~/.claude.

setup() {
  unset CODEX_THREAD_ID CODEX_HOME CODEX_BINARY
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
  [[ "$output" == *"start, stop, or change intentional tool-call delays"* ]]
  [[ "$output" == *"Wait silently"* ]]
  [[ "$output" == *"cancelling or retrying restarts the pacing delay"* ]]
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

@test "agent-merge nudge fires at most once while pacing guidance remains" {
  printf '#!/bin/bash\ninput=$(cat)\necho hi\n' > "$SL"
  bash "$INST" </dev/null >/dev/null                 # first: nudges + writes marker
  run bash "$INST" </dev/null                        # second: marker present → silent no-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"start, stop, or change intentional tool-call delays"* ]]
  [[ "$output" != *"needs a quota-state producer"* ]]
}

# --- adopter-config-diversity: prove non-destructive across shapes (risk remediation) ---

@test "path-robust: an active statusline at a NON-default path that already produces → no-op" {
  other="$HOME/.claude/my-statusline.sh"
  printf '#!/bin/bash\n# writes quota-state.json\ncat >/dev/null\n' > "$other"
  printf '{"statusLine":{"type":"command","command":"%s"}}' "$other" > "$SETTINGS"
  run bash "$INST" </dev/null
  [ "$status" -eq 0 ]
  [ ! -f "$SL" ]                                              # no orphan default statusline created
  [ ! -f "$HOME/.claude/.cruise-producer-merge-nudged" ]     # not nudged (already produces)
}

@test "non-destructive: an existing settings.statusLine is never overwritten (nudge, no orphan)" {
  other="$HOME/.claude/my-statusline.sh"
  printf '#!/bin/bash\ninput=$(cat)\necho hi\n' > "$other"    # exists elsewhere, does NOT produce
  printf '{"statusLine":{"type":"command","command":"%s"},"keep":1}' "$other" > "$SETTINGS"
  before="$(cat "$SETTINGS")"
  run bash "$INST" </dev/null
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null   # agent-merge nudge
  [ "$(cat "$SETTINGS")" = "$before" ]                       # settings UNTOUCHED
  [ ! -f "$SL" ]                                             # NO orphan default statusline created
}

@test "non-destructive: a malformed settings.json is never clobbered" {
  printf 'this is { not valid json' > "$SETTINGS"
  before="$(cat "$SETTINGS")"
  run bash "$INST" </dev/null
  [ "$status" -eq 0 ]
  [ "$(cat "$SETTINGS")" = "$before" ]                       # malformed settings preserved byte-for-byte
}

@test "missing ~/.claude directory → no-op, creates nothing, no crash" {
  rm -rf "$HOME/.claude"
  run bash "$INST" </dev/null
  [ "$status" -eq 0 ]
  [ ! -d "$HOME/.claude" ]
}
