#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOKS="${ARCHITECT_PACKAGE_ROOT:-$REPO_ROOT/packages/architect}/hooks"
}

make_fake_dispatcher() {
  FAKE_ROOT="$(mktemp -d)"
  TRACE="$FAKE_ROOT/trace"
  mkdir -p "$FAKE_ROOT/hooks" "$FAKE_ROOT/scripts"
  cp "$HOOKS/architect-dispatch.sh" "$FAKE_ROOT/hooks/architect-dispatch.sh"
  cp "$HOOKS/bash-write-dispatch.sh" "$FAKE_ROOT/hooks/bash-write-dispatch.sh"
  chmod +x "$FAKE_ROOT/hooks/bash-write-dispatch.sh"
  local child
  for child in \
    architect-oversight-nudge.sh architect-detect.sh staleness-check.sh \
    architect-enforce-edit.sh architect-oversight-marker-discipline.sh \
    architect-plan-enforce.sh architect-readme-pairing-check.sh \
    architect-mark-reviewed.sh architect-refresh-hash.sh \
    architect-compendium-update-entry.sh architect-slide-marker.sh; do
    printf '#!/bin/bash\necho "%s" >> "$TRACE"\n' "$child" > "$FAKE_ROOT/hooks/$child"
    chmod +x "$FAKE_ROOT/hooks/$child"
  done
  printf '%s\n' \
    'import fs from "node:fs";' \
    'fs.appendFileSync(process.env.TRACE, "codex-agent.mjs\n");' \
    > "$FAKE_ROOT/scripts/codex-agent.mjs"
  printf '%s\n' \
    'import fs from "node:fs";' \
    'fs.appendFileSync(process.env.TRACE, "codex-agent-completion.mjs\n");' \
    > "$FAKE_ROOT/hooks/codex-agent-completion.mjs"
}

run_fake() {
  local event="$1" tool="${2:-}" status=0
  : > "$TRACE"
  TRACE="$TRACE" env -u CODEX_THREAD_ID bash "$FAKE_ROOT/hooks/architect-dispatch.sh" "$event" \
    <<<"{\"session_id\":\"dispatch-test\",\"tool_name\":\"$tool\"}" || status=$?
  cat "$TRACE"
  return "$status"
}

@test "hooks.json registers four command hooks" {
  run python3 - "$HOOKS/hooks.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
print(sum(len(entry["hooks"]) for entries in data["hooks"].values() for entry in entries))
PY
  [ "$status" -eq 0 ]
  [ "$output" = "4" ]
}

@test "dispatcher retains all thirteen child hook routes" {
  local child
  for child in \
    codex-agent.mjs architect-oversight-nudge.sh \
    architect-detect.sh staleness-check.sh \
    architect-enforce-edit.sh architect-oversight-marker-discipline.sh \
    architect-plan-enforce.sh architect-readme-pairing-check.sh \
    architect-mark-reviewed.sh codex-agent-completion.mjs \
    architect-refresh-hash.sh architect-compendium-update-entry.sh \
    architect-slide-marker.sh; do
    run grep -F "$child" "$HOOKS/architect-dispatch.sh"
    [ "$status" -eq 0 ]
  done
}

@test "Codex SessionStart combines agent repair and oversight nudge" {
  local dir input
  dir="$(mktemp -d)"
  mkdir -p "$dir/project/docs/decisions"
  cat > "$dir/project/docs/decisions/001-test.proposed.md" <<'EOF'
---
status: proposed
human-oversight: unconfirmed
---
EOF
  input='{"session_id":"dispatch-test"}'

  run env CODEX_THREAD_ID=codex-test CODEX_HOME="$dir/codex" CLAUDE_PROJECT_DIR="$dir/project" \
    bash "$HOOKS/architect-dispatch.sh" session-start <<<"$input"
  rm -rf "$dir"

  [ "$status" -eq 0 ]
  run jq -er '.systemMessage | contains("Codex agent installed") and contains("lacks human oversight")' <<<"$output"
  [ "$status" -eq 0 ]
}

@test "dispatcher preserves every lifecycle route and child order" {
  make_fake_dispatcher

  run run_fake session-start
  [ "$output" = $'codex-agent.mjs\narchitect-oversight-nudge.sh' ]
  run run_fake user-prompt
  [ "$output" = $'architect-detect.sh\nstaleness-check.sh' ]
  run run_fake pre-tool Edit
  [ "$output" = $'architect-enforce-edit.sh\narchitect-oversight-marker-discipline.sh' ]
  run run_fake pre-tool ExitPlanMode
  [ "$output" = 'architect-plan-enforce.sh' ]
  run run_fake pre-tool Bash
  [ "$output" = 'architect-readme-pairing-check.sh' ]
  run run_fake post-tool Agent
  [ "$output" = $'architect-mark-reviewed.sh\narchitect-slide-marker.sh' ]
  run run_fake post-tool multi_agent_v1__close_agent
  [ "$output" = 'codex-agent-completion.mjs' ]
  run run_fake post-tool Edit
  [ "$output" = $'architect-refresh-hash.sh\narchitect-compendium-update-entry.sh' ]
  run run_fake post-tool Bash
  [ "$output" = 'architect-slide-marker.sh' ]
}

@test "dispatcher stops after a stdout deny" {
  make_fake_dispatcher
  cat > "$FAKE_ROOT/hooks/architect-enforce-edit.sh" <<'EOF'
#!/bin/bash
echo "architect-enforce-edit.sh" >> "$TRACE"
echo '{"hookSpecificOutput":{"permissionDecision":"deny"}}'
EOF
  chmod +x "$FAKE_ROOT/hooks/architect-enforce-edit.sh"

  run run_fake pre-tool Edit
  [ "$status" -eq 0 ]
  [[ "$output" == *'permissionDecision'* ]]
  [ "$(cat "$TRACE")" = 'architect-enforce-edit.sh' ]
}

@test "dispatcher propagates a nonzero deny" {
  make_fake_dispatcher
  cat > "$FAKE_ROOT/hooks/architect-readme-pairing-check.sh" <<'EOF'
#!/bin/bash
echo "architect-readme-pairing-check.sh" >> "$TRACE"
echo '{"hookSpecificOutput":{"permissionDecision":"deny"}}' >&2
exit 2
EOF
  chmod +x "$FAKE_ROOT/hooks/architect-readme-pairing-check.sh"

  run run_fake pre-tool Bash
  [ "$status" -eq 2 ]
  [[ "$output" == *'permissionDecision'* ]]
}
