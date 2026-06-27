#!/usr/bin/env bats

# P348 / ADR-068 amendment 2026-06-02: jtbd-oversight-marker-discipline.sh
# is the JTBD-side sibling of architect-oversight-marker-discipline.sh.
# Denies Edit/Write that introduces `human-oversight: confirmed` into a
# docs/jtbd/ artefact's frontmatter unless a session-scoped evidence marker
# proves the user has substance-confirmed THAT artefact.
#
# Behavioural — exercises the hook with constructed PreToolUse stdin JSON
# payloads under SESSION_MARKER_DIR sandboxing.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/jtbd/hooks/jtbd-oversight-marker-discipline.sh"
  MARK_SCRIPT="$REPO_ROOT/packages/jtbd/scripts/mark-oversight-confirmed.sh"

  DIR="$(mktemp -d)"
  mkdir -p "$DIR/docs/jtbd/developer"
  MARK_DIR="$(mktemp -d)"
  export SESSION_MARKER_DIR="$MARK_DIR"

  ORIG_DIR="$PWD"
  cd "$DIR"

  SID="jtbd-discipline-test-$$"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$DIR" "$MARK_DIR"
  unset SESSION_MARKER_DIR
}

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

mk_existing_artefact() {
  local subpath="$1"; shift
  local dir
  dir="$(dirname "$DIR/docs/jtbd/$subpath")"
  mkdir -p "$dir"
  {
    echo "---"
    echo "status: \"proposed\""
    echo "date: 2026-06-02"
    for line in "$@"; do echo "$line"; done
    echo "---"
    echo "# $(basename "$subpath" .md)"
  } > "$DIR/docs/jtbd/$subpath"
}

# ── Positive paths ───────────────────────────────────────────────────────

@test "Write introducing 'human-oversight: confirmed' to a JTBD with marker present is allowed" {
  mk_existing_artefact "developer/JTBD-300-test.proposed.md"
  art="$DIR/docs/jtbd/developer/JTBD-300-test.proposed.md"
  : > "$(expected_marker "$art")"
  new_content=$'---\nstatus: "proposed"\ndate: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-06-02\n---\n\n# JTBD-300\n'
  json=$(jq -nc --arg p "$art" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "Edit to a persona introducing the marker with evidence is allowed" {
  mk_existing_artefact "developer/persona.md"
  art="$DIR/docs/jtbd/developer/persona.md"
  : > "$(expected_marker "$art")"
  old='date: 2026-06-02'
  new=$'date: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-06-02'
  json=$(jq -nc --arg p "$art" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# ── Negative paths ───────────────────────────────────────────────────────

@test "Write introducing 'human-oversight: confirmed' to a JTBD WITHOUT marker is denied" {
  mk_existing_artefact "developer/JTBD-310-orphan.proposed.md"
  art="$DIR/docs/jtbd/developer/JTBD-310-orphan.proposed.md"
  new_content=$'---\nstatus: "proposed"\ndate: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-06-02\n---\n\n# JTBD-310\n'
  json=$(jq -nc --arg p "$art" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision": "deny"'* ]]
  [[ "$output" == *"BLOCKED"* ]]
  [[ "$output" == *"wr-jtbd-mark-oversight-confirmed"* ]]
  [[ "$output" == *"/wr-jtbd:confirm-jobs-and-personas"* ]]
}

@test "Edit introducing the marker to persona WITHOUT marker is denied" {
  mk_existing_artefact "tech-lead/persona.md"
  art="$DIR/docs/jtbd/tech-lead/persona.md"
  old='date: 2026-06-02'
  new=$'date: 2026-06-02\nhuman-oversight: confirmed'
  json=$(jq -nc --arg p "$art" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [[ "$output" == *'"permissionDecision": "deny"'* ]]
}

# ── AFK-unconfirmed-write ────────────────────────────────────────────────

@test "Write introducing 'human-oversight: unconfirmed' is allowed without marker (AFK path)" {
  mk_existing_artefact "developer/JTBD-320-afk.proposed.md"
  art="$DIR/docs/jtbd/developer/JTBD-320-afk.proposed.md"
  new_content=$'---\nstatus: "proposed"\ndate: 2026-06-02\nhuman-oversight: unconfirmed\n---\n\n# JTBD-320-afk\n'
  json=$(jq -nc --arg p "$art" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# ── Scope / non-fire paths ───────────────────────────────────────────────

@test "Edit to a non-JTBD path exits 0 silently even with the marker line" {
  mkdir -p "$DIR/src"
  echo "// stub" > "$DIR/src/foo.ts"
  json=$(jq -nc --arg p "$DIR/src/foo.ts" --arg s "$SID" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:"// stub",new_string:"// human-oversight: confirmed"}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Edit to docs/jtbd/README.md exits 0 silently" {
  echo "# index" > "$DIR/docs/jtbd/README.md"
  art="$DIR/docs/jtbd/README.md"
  new=$'# index\nhuman-oversight: confirmed'
  json=$(jq -nc --arg p "$art" --arg s "$SID" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:"# index",new_string:$n}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Edit whose new content lacks the marker exits 0 silently" {
  mk_existing_artefact "developer/JTBD-330-rename.proposed.md"
  art="$DIR/docs/jtbd/developer/JTBD-330-rename.proposed.md"
  json=$(jq -nc --arg p "$art" --arg s "$SID" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:"# JTBD-330-rename",new_string:"# JTBD-330 renamed"}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── End-to-end ───────────────────────────────────────────────────────────

@test "mark-oversight-confirmed.sh writes a marker that satisfies the JTBD hook" {
  mk_existing_artefact "developer/JTBD-340-e2e.proposed.md"
  art="$DIR/docs/jtbd/developer/JTBD-340-e2e.proposed.md"
  : > "$MARK_DIR/jtbd-announced-$SID"
  bash "$MARK_SCRIPT" "$art"
  [ -f "$(expected_marker "$art")" ]
  new_content=$'---\nstatus: "proposed"\ndate: 2026-06-02\nhuman-oversight: confirmed\noversight-date: 2026-06-02\n---\n\n# JTBD-340-e2e\n'
  json=$(jq -nc --arg p "$art" --arg s "$SID" --arg c "$new_content" \
    '{tool_name:"Write",session_id:$s,tool_input:{file_path:$p,content:$c}}')
  run bash -c "echo '$(echo "$json" | sed "s/'/'\\\\''/g")' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# P380: on macOS SESSION_MARKER_DIR defaults to /tmp, a symlink to /private/tmp.
# `find <symlink> -maxdepth 1` in default (-P) mode refuses to descend the
# start-point symlink, so candidate enumeration returns empty and the script
# writes ZERO markers (silent cold-path exit 0). The `-L` flag follows it. This
# test points SESSION_MARKER_DIR at a SYMLINK to the marker dir (reproducing the
# macOS /tmp shape on any platform); RED without `-L`, GREEN with it.
@test "mark-oversight-confirmed.sh enumerates candidates when SESSION_MARKER_DIR is a symlink (P380)" {
  mk_existing_artefact "developer/JTBD-341-symlink.proposed.md"
  art="$DIR/docs/jtbd/developer/JTBD-341-symlink.proposed.md"
  : > "$MARK_DIR/jtbd-announced-$SID"
  link_dir="${MARK_DIR}.link"
  ln -s "$MARK_DIR" "$link_dir"
  SESSION_MARKER_DIR="$link_dir" bash "$MARK_SCRIPT" "$art"
  rm -f "$link_dir"
  [ -f "$(expected_marker "$art")" ]
}

@test "tool_name=Bash exits 0 silently regardless of file path" {
  json=$(jq -nc --arg s "$SID" \
    '{tool_name:"Bash",session_id:$s,tool_input:{command:"echo human-oversight: confirmed"}}')
  run bash -c "echo '$json' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
