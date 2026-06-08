#!/usr/bin/env bats

# P301: architect-enforce-edit.sh exempts marker-only frontmatter diffs to
# docs/decisions/*.md ADRs from the full architect review gate. The
# architect-oversight-marker-discipline.sh hook remains the safety net for
# `human-oversight: confirmed` introductions; this exemption only short-
# circuits the enforce-edit drift/TTL gate when the diff adds/modifies
# nothing but the narrow oversight-marker grammar.
#
# Behavioural — exercises the full hook with constructed PreToolUse stdin
# JSON payloads under a sandbox project dir; asserts on stdout+exit.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/architect-enforce-edit.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  # Engage the architect gate — only runs when docs/decisions/ exists.
  mkdir -p docs/decisions
  echo "# stub" > docs/decisions/001-stub.proposed.md
  SID="marker-only-exempt-$$-$BATS_TEST_NUMBER"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  rm -f "/tmp/architect-reviewed-${SID}" "/tmp/architect-reviewed-${SID}.hash"
}

# Helper: run the hook with constructed JSON. Echo to a file then pipe to
# avoid heredoc / quote-escaping headaches with multi-line content.
run_hook_json() {
  local json_file="$1"
  bash "$HOOK" < "$json_file"
}

# ── Marker-only ADD: should exempt ───────────────────────────────────────

@test "P301: Edit adding only human-oversight + oversight-date is exempt (no architect marker required)" {
  adr="$PWD/docs/decisions/100-some-adr.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
date: 2026-06-08
---

# 100 some adr

Body content unchanged.
EOF
  old=$'---\nstatus: "proposed"\ndate: 2026-06-08\n---'
  new=$'---\nstatus: "proposed"\ndate: 2026-06-08\nhuman-oversight: unconfirmed\noversight-date: 2026-06-08\n---'
  json_file=$(mktemp)
  jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "P301: Edit updating human-oversight value (unconfirmed → confirmed) is exempt" {
  adr="$PWD/docs/decisions/101-promote.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
human-oversight: unconfirmed
---

# 101 promote
EOF
  old=$'human-oversight: unconfirmed'
  new=$'human-oversight: confirmed\noversight-date: 2026-06-08'
  json_file=$(mktemp)
  jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "P301: Edit adding rejected-pending-supersede + supersede-ticket is exempt" {
  adr="$PWD/docs/decisions/102-rejected.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
---

# 102 rejected
EOF
  old=$'status: "proposed"'
  new=$'status: "proposed"\nhuman-oversight: rejected-pending-supersede\nsupersede-ticket: P999'
  json_file=$(mktemp)
  jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# ── Mixed marker + body: must NOT exempt ─────────────────────────────────

@test "P301: Edit changing body content along with markers still gates" {
  adr="$PWD/docs/decisions/110-mixed.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
---

# 110 mixed

Original body.
EOF
  old=$'---\nstatus: "proposed"\n---\n\n# 110 mixed\n\nOriginal body.'
  new=$'---\nstatus: "proposed"\nhuman-oversight: confirmed\noversight-date: 2026-06-08\n---\n\n# 110 mixed\n\nRewritten body with new policy claim.'
  json_file=$(mktemp)
  jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [[ "$output" == *"BLOCKED"* ]]
}

@test "P301: Edit changing status field (not a marker line) still gates" {
  adr="$PWD/docs/decisions/111-status-change.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
---

# 111
EOF
  old=$'status: "proposed"'
  new=$'status: "accepted"\nhuman-oversight: confirmed\noversight-date: 2026-06-08'
  json_file=$(mktemp)
  jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [[ "$output" == *"BLOCKED"* ]]
}

# ── Pure body change: must still gate (no marker involvement) ────────────

@test "P301: Edit changing only body content with no marker lines still gates" {
  adr="$PWD/docs/decisions/120-body.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
---

# 120 body

Some text.
EOF
  old='Some text.'
  new='Some text. And new text.'
  json_file=$(mktemp)
  jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [[ "$output" == *"BLOCKED"* ]]
}

# ── Scope: exemption is narrow to docs/decisions/*.md ────────────────────

@test "P301: marker-only diff to a NON docs/decisions/ path still gates (no path exemption)" {
  mkdir -p "$PWD/src"
  echo "// stub" > "$PWD/src/x.ts"
  src="$PWD/src/x.ts"
  old='// stub'
  new='// stub'$'\n''human-oversight: confirmed'
  json_file=$(mktemp)
  jq -nc --arg p "$src" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [[ "$output" == *"BLOCKED"* ]]
}
