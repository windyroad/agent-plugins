#!/usr/bin/env bats

# P301: jtbd-enforce-edit.sh exempts marker-only frontmatter diffs to
# docs/decisions/*.md ADRs from the JTBD review gate. The JTBD gate currently
# fires on docs/decisions/ writes (decisions are not in its exclusion list);
# the ticket's symptom "Batch 8 (ADR-020): blocked on architect review
# (`jtbd policy file changed since last review`)" is that JTBD round-trip.
#
# Behavioural — exercises the full hook with constructed PreToolUse stdin
# JSON payloads under a sandbox project dir; asserts on stdout+exit.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/jtbd-enforce-edit.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  # JTBD docs must exist for the gate to engage (otherwise it denies
  # with "no JTBD documentation" — out of scope of this exemption test).
  mkdir -p docs/jtbd/persona docs/decisions
  echo "# stub job" > docs/jtbd/persona/JTBD-001-stub.proposed.md
  echo "# stub adr" > docs/decisions/001-stub.proposed.md
  SID="jtbd-marker-only-$$-$BATS_TEST_NUMBER"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  rm -f "/tmp/jtbd-reviewed-${SID}" "/tmp/jtbd-reviewed-${SID}.hash"
}

run_hook_json() {
  local json_file="$1"
  bash "$HOOK" < "$json_file"
}

# ── Marker-only ADD: should exempt ───────────────────────────────────────

@test "P301: Edit adding only human-oversight + oversight-date to ADR is exempt (no JTBD marker required)" {
  adr="$PWD/docs/decisions/100-some-adr.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
---

# 100 some adr
EOF
  old=$'---\nstatus: "proposed"\n---'
  new=$'---\nstatus: "proposed"\nhuman-oversight: unconfirmed\noversight-date: 2026-06-08\n---'
  json_file=$(mktemp)
  jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "P301: Edit updating human-oversight value (unconfirmed → confirmed) on ADR is exempt" {
  adr="$PWD/docs/decisions/101-promote.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
human-oversight: unconfirmed
---

# 101
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

# ── Mixed marker + body: must NOT exempt ─────────────────────────────────

@test "P301: Edit changing body content along with markers still gates" {
  adr="$PWD/docs/decisions/110-mixed.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
---

# 110

Original body.
EOF
  old=$'---\nstatus: "proposed"\n---\n\n# 110\n\nOriginal body.'
  new=$'---\nstatus: "proposed"\nhuman-oversight: confirmed\noversight-date: 2026-06-08\n---\n\n# 110\n\nNew policy claim added.'
  json_file=$(mktemp)
  jq -nc --arg p "$adr" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [[ "$output" == *"BLOCKED"* ]]
}

# ── Pure body change: must still gate ────────────────────────────────────

@test "P301: Edit changing only body content with no marker lines still gates" {
  adr="$PWD/docs/decisions/120-body.proposed.md"
  cat > "$adr" <<'EOF'
---
status: "proposed"
---

# 120

Some text.
EOF
  old='Some text.'
  new='Some text. And more.'
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
  new=$'// stub\nhuman-oversight: confirmed'
  json_file=$(mktemp)
  jq -nc --arg p "$src" --arg s "$SID" --arg o "$old" --arg n "$new" \
    '{tool_name:"Edit",session_id:$s,tool_input:{file_path:$p,old_string:$o,new_string:$n}}' > "$json_file"
  run run_hook_json "$json_file"
  rm -f "$json_file"
  [[ "$output" == *"BLOCKED"* ]]
}
