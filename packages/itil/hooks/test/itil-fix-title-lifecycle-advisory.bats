#!/usr/bin/env bats

# P345/RFC-044/STORY-038: itil-fix-title-lifecycle-advisory.sh — post-commit
# ADVISORY for fix-titled commits whose named P<NNN> ticket is still Open on
# disk (no paired lifecycle transition in the commit). Advisory-only per
# ADR-092: never blocks, exit 0 on every path. Behavioural (ADR-052).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/itil/hooks/itil-fix-title-lifecycle-advisory.sh"
  DIR="$(mktemp -d)"; cd "$DIR"
  git init -q; git config user.email t@e.x; git config user.name t
  mkdir -p docs/problems/open docs/problems/known-error
  echo x > seed; git add -A; git commit -qm "chore: seed"
}
teardown() { cd /; rm -rf "$DIR"; }

# Feed the hook a PostToolUse Bash payload for a `git commit` command.
run_hook() {
  printf '{"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}' | bash "$HOOK"
}

commit() { git commit -q --allow-empty -m "$1"; }

@test "advises when a fix-titled commit names a still-Open ticket" {
  echo t > docs/problems/open/501-widget-breaks.md
  commit "fix(itil): P501 stop the widget breaking"
  run run_hook
  [ "$status" -eq 0 ]
  [[ "$output" == *"P501"* ]]
  [[ "$output" == *"Open"* ]]
  [[ "$output" == *"transition"* ]]
}

@test "silent when the named ticket is known-error (transition already happened)" {
  echo t > docs/problems/known-error/501-widget-breaks.md
  commit "fix(itil): P501 stop the widget breaking"
  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when the named ticket does not exist on disk" {
  commit "fix(itil): P999 phantom ticket"
  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent on a non-fix-typed subject naming a P token" {
  echo t > docs/problems/open/501-widget-breaks.md
  commit "docs(problems): P501 add investigation notes"
  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent on a fix-typed subject with no P token" {
  echo t > docs/problems/open/501-widget-breaks.md
  commit "fix(itil): tidy the widget"
  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "advises on the bare fix: form too" {
  echo t > docs/problems/open/502-gadget-stuck.md
  commit "fix: P502 unstick the gadget"
  run run_hook
  [ "$status" -eq 0 ]
  [[ "$output" == *"P502"* ]]
}

@test "total emission stays at or under 300 bytes with many still-Open tickets" {
  for n in 511 512 513 514 515 516; do
    echo t > "docs/problems/open/${n}-thing-${n}.md"
  done
  commit "fix(itil): P511 P512 P513 P514 P515 P516 mega sweep"
  run run_hook
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  [ "${#output}" -le 300 ]
}

@test "bypass env var suppresses the advisory" {
  echo t > docs/problems/open/501-widget-breaks.md
  commit "fix(itil): P501 stop the widget breaking"
  run env BYPASS_FIX_TITLE_LIFECYCLE_ADVISORY=1 bash -c 'printf "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git commit -m x\"}}" | bash "$0"' "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent on non-Bash tool payloads" {
  echo t > docs/problems/open/501-widget-breaks.md
  commit "fix(itil): P501 stop the widget breaking"
  run bash -c 'printf "{\"tool_name\":\"Write\",\"tool_input\":{}}" | bash "$0"' "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent on non-commit Bash commands" {
  echo t > docs/problems/open/501-widget-breaks.md
  commit "fix(itil): P501 stop the widget breaking"
  run bash -c 'printf "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git log --oneline\"}}" | bash "$0"' "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fail-open silent when docs/problems is absent" {
  rm -rf docs/problems
  commit "fix(itil): P501 stop the widget breaking"
  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fail-open silent outside a git work tree" {
  NOGIT="$(mktemp -d)"; cd "$NOGIT"
  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  cd /; rm -rf "$NOGIT"
}

@test "fail-open silent on malformed JSON input" {
  run bash -c 'printf "not json at all" | bash "$0"' "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
