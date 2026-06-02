#!/usr/bin/env bats

# P348 / ADR-066 amendment 2026-06-02: architect-oversight-marker-discipline.sh
# is a PreToolUse:Edit|Write hook that denies any Edit/Write that introduces
# `human-oversight: confirmed` into a docs/decisions/ ADR's frontmatter unless
# a session-scoped evidence marker `/tmp/oversight-confirmed-<sha>-<sid>`
# exists for THAT specific ADR under THIS session.
#
# Behavioural — exercises the hook with constructed PreToolUse stdin JSON
# payloads under SESSION_MARKER_DIR sandboxing, asserts on stdout+exit.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/architect/hooks/architect-oversight-marker-discipline.sh"
  MARK_SCRIPT="$REPO_ROOT/packages/architect/scripts/mark-oversight-confirmed.sh"

  DIR="$(mktemp -d)"
  mkdir -p "$DIR/docs/decisions"
  MARK_DIR="$(mktemp -d)"
  export SESSION_MARKER_DIR="$MARK_DIR"

  ORIG_DIR="$PWD"
  cd "$DIR"

  SID="discipline-test-$$"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$DIR" "$MARK_DIR"
  unset SESSION_MARKER_DIR
}

# Helper: compute the marker path the hook expects for an ADR file.
expected_marker() {
  local f="$1"
  local abs_dir abs path_hash
  abs_dir="$(cd "$(dirname "$f")" && pwd)"
  abs="$abs_dir/$(basename "$f")"
  if command -v sha256sum >/dev/null 2>&1; then
    path_hash=$(printf '%s' "$abs" | sha256sum | cut -d' ' -f1 | cut -c1-16)
  else
    path_hash=$(printf '%s' "$abs" | shasum -a 256 | cut -d' ' -f1 | cut -c1-16)
  fi
  printf '%s/oversight-confirmed-%s-%s\n' "$MARK_DIR" "$path_hash" "$SID"
}

mk_existing_adr() {
  local name="$1"; shift
  {
    echo "---"
    echo "status: \"proposed\""
    echo "date: 2026-06-02"
    for line in "$@"; do echo "$line"; done
    echo "---"
    echo "# $name"
  } > "$DIR/docs/decisions/$name"
}

# ── Positive paths (marker present → allow) ──────────────────────────────

@test "Write introducing 'human-oversight: confirmed' with marker present is allowed" {
  mk_existing_adr "200-unconfirmed.proposed.md"
  adr="$DIR/docs/decisions/200-unconfirmed.proposed.md"
  : > "$(expected_marker "$adr")"
  new_content=$'---\nstatus: "proposed"\ndate: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-06-02\n---\n\n# 200-unconfirmed\n'
  json=$(jq -nc --arg p "$adr" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "Edit introducing 'human-oversight: confirmed' with marker present is allowed" {
  mk_existing_adr "201-pending.proposed.md"
  adr="$DIR/docs/decisions/201-pending.proposed.md"
  : > "$(expected_marker "$adr")"
  old='date: 2026-06-02'
  new=$'date: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-06-02'
  json=$(jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# ── Negative paths (no marker → deny) ───────────────────────────────────

@test "Write introducing 'human-oversight: confirmed' WITHOUT marker is denied" {
  mk_existing_adr "210-orphan.proposed.md"
  adr="$DIR/docs/decisions/210-orphan.proposed.md"
  new_content=$'---\nstatus: "proposed"\ndate: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-06-02\n---\n\n# 210-orphan\n'
  json=$(jq -nc --arg p "$adr" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision": "deny"'* ]]
  [[ "$output" == *"BLOCKED"* ]]
  [[ "$output" == *"oversight-confirmed-"* ]]
  [[ "$output" == *"wr-architect-mark-oversight-confirmed"* ]]
}

@test "Edit introducing 'human-oversight: confirmed' WITHOUT marker is denied" {
  mk_existing_adr "211-no-evidence.proposed.md"
  adr="$DIR/docs/decisions/211-no-evidence.proposed.md"
  old='date: 2026-06-02'
  new=$'date: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-06-02'
  json=$(jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [[ "$output" == *'"permissionDecision": "deny"'* ]]
}

# ── AFK-unconfirmed-write path (no marker required) ──────────────────────

@test "Write introducing 'human-oversight: unconfirmed' is allowed without marker (AFK path)" {
  mk_existing_adr "220-afk.proposed.md"
  adr="$DIR/docs/decisions/220-afk.proposed.md"
  new_content=$'---\nstatus: "proposed"\ndate: 2026-06-02\nhuman-oversight: unconfirmed\n---\n\n# 220-afk\n'
  json=$(jq -nc --arg p "$adr" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "Write introducing rejected-pending-supersede is allowed without marker" {
  mk_existing_adr "221-rejected.proposed.md"
  adr="$DIR/docs/decisions/221-rejected.proposed.md"
  new_content=$'---\nstatus: "proposed"\ndate: 2026-06-02\nhuman-oversight: rejected-pending-supersede\nsupersede-ticket: P999\n---\n\n# 221-rejected\n'
  json=$(jq -nc --arg p "$adr" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# ── Scope / non-fire paths ────────────────────────────────────────────────

@test "Edit to a non-ADR path (src/index.ts) exits 0 silently" {
  mkdir -p "$DIR/src"
  echo "// stub" > "$DIR/src/index.ts"
  json=$(jq -nc --arg p "$DIR/src/index.ts" --arg s "$SID" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:"// stub",new_string:"// human-oversight: confirmed"}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Edit to docs/decisions/README.md exits 0 silently" {
  echo "# index" > "$DIR/docs/decisions/README.md"
  adr="$DIR/docs/decisions/README.md"
  new=$'# index\nhuman-oversight: confirmed'
  json=$(jq -nc --arg p "$adr" --arg s "$SID" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:"# index",new_string:$n}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Edit whose new content lacks the marker exits 0 silently" {
  mk_existing_adr "230-unrelated.proposed.md"
  adr="$DIR/docs/decisions/230-unrelated.proposed.md"
  json=$(jq -nc --arg p "$adr" --arg s "$SID" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:"# 230-unrelated",new_string:"# 230 renamed"}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Write whose OLD content already had the marker (re-stamp / no-op) is allowed without re-evidencing" {
  # Pre-existing ADR already carries the marker; new content keeps it.
  mk_existing_adr "240-already.proposed.md" "human-oversight: confirmed" "oversight-date: 2026-05-30"
  adr="$DIR/docs/decisions/240-already.proposed.md"
  new_content=$'---\nstatus: "accepted"\ndate: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-05-30\n---\n\n# 240-already\n'
  json=$(jq -nc --arg p "$adr" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# ── End-to-end: mark-oversight-confirmed.sh + the hook ──────────────────

@test "mark-oversight-confirmed.sh writes a marker that satisfies the hook" {
  mk_existing_adr "250-e2e.proposed.md"
  adr="$DIR/docs/decisions/250-e2e.proposed.md"
  # Seed an announce marker so candidate enumeration finds the SID.
  : > "$MARK_DIR/architect-announced-$SID"
  bash "$MARK_SCRIPT" "$adr"
  # The mark script writes under every candidate; the hook's expected marker
  # filename for our SID must now exist.
  [ -f "$(expected_marker "$adr")" ]
  new_content=$'---\nstatus: "proposed"\ndate: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-06-02\n---\n\n# 250-e2e\n'
  json=$(jq -nc --arg p "$adr" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# ── Non-Edit/Write tool calls always exit 0 silently ────────────────────

@test "tool_name=Bash exits 0 silently regardless of file path" {
  json=$(jq -nc --arg s "$SID" \
    '{tool_name:"Bash",session_id:$s,tool_input:{command:"echo human-oversight: confirmed"}}')
  run bash -c "echo '$json' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
