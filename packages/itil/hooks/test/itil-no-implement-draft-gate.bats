#!/usr/bin/env bats
# Behavioural tests for itil-no-implement-draft-gate.sh (ADR-096 / P404).
# PreToolUse:Bash — reads a JSON envelope on stdin, emits permissionDecision:deny
# (exit 0, deny in the JSON) when a commit references a DRAFT story.
# @adr ADR-096  @adr ADR-052  @problem P404

setup() {
  HOOK="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/itil-no-implement-draft-gate.sh"
  TMP="$(mktemp -d)"; cd "$TMP"; git init -q .
  mkdir -p docs/stories/draft docs/stories/accepted
}
teardown() { cd /; rm -rf "$TMP"; }

# write env.json carrying the given command string
env_cmd() { python3 -c 'import json,sys; open("env.json","w").write(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1"; }

@test "blocks a commit referencing a DRAFT story" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q 'STORY-042'
}

@test "allows a commit referencing an ACCEPTED story" {
  touch docs/stories/accepted/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "exempts a capture commit even for a draft story" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'git commit -m "feat(itil): capture STORY-042 foo

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "bootstrap-exempt commit bypasses" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'git commit -m "migrate

Refs: STORY-042
bootstrap-exempt: STORY-MAP-001"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "non-commit command is a no-op" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'echo Refs: STORY-042'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "commit with no story trailer is a no-op" {
  env_cmd 'git commit -m "fix: no story ref"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "BYPASS env allows the commit" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'git commit -m "fix

Refs: STORY-042"'
  BYPASS_NO_IMPLEMENT_DRAFT=1 run bash -c "BYPASS_NO_IMPLEMENT_DRAFT=1 bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}
