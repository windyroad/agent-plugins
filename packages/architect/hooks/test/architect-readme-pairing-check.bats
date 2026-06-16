#!/usr/bin/env bats

# Behavioural tests for architect-readme-pairing-check.sh (RFC-014 Story B,
# ADR-078 Phase 1 / Option 9). Exercises the hook against a real staged git
# index; asserts on its PreToolUse allow/deny decision (exit code + deny JSON).
# Behavioural — no grep on hook source (feedback_behavioural_tests).

setup() {
  HOOK="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/architect-readme-pairing-check.sh"
  REPO="$(mktemp -d)"
  cd "$REPO"
  git init -q
  git config user.email t@e.x
  git config user.name t
  mkdir -p docs/decisions
  echo "# compendium" > docs/decisions/README.md
  echo "# adr 049" > docs/decisions/049-x.proposed.md
  git add -A && git commit -q -m init
}

teardown() {
  cd /
  rm -rf "$REPO"
}

# Run the hook with a synthetic `git commit` Bash PreToolUse payload.
run_commit_hook() {
  local cmd="${1:-git commit -m wip}"
  echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$cmd\"}}" | bash "$HOOK"
}

@test "denies commit when an ADR body is staged without README (criterion 1)" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  run run_commit_hook
  [ "$status" -eq 2 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"049-x.proposed.md"* ]]
}

@test "permits commit when ADR body AND README are both staged (criterion 2)" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  echo "# compendium refreshed" > docs/decisions/README.md
  git add docs/decisions/049-x.proposed.md docs/decisions/README.md
  run run_commit_hook
  [ "$status" -eq 0 ]
}

@test "permits commit when only README is staged (compendium-only edit) (criterion 3)" {
  echo "# compendium refreshed" > docs/decisions/README.md
  git add docs/decisions/README.md
  run run_commit_hook
  [ "$status" -eq 0 ]
}

@test "permits commit when no ADR-touching change is staged (criterion 4)" {
  echo "x" > unrelated.txt
  git add unrelated.txt
  run run_commit_hook
  [ "$status" -eq 0 ]
}

@test "deny message names the unpaired ADR file + recovery directive (criterion 5)" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  run run_commit_hook
  [ "$status" -eq 2 ]
  [[ "$output" == *"049-x.proposed.md"* ]]
  [[ "$output" == *"wr-architect-generate-decisions-compendium"* ]]
}

@test "allows non-commit Bash commands silently" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  run run_commit_hook "git status"
  [ "$status" -eq 0 ]
}

@test "RISK_BYPASS token permits an intentional split" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  run run_commit_hook "git commit -m 'wip RISK_BYPASS: architect-compendium-deferred'"
  [ "$status" -eq 0 ]
}

# --- P366 leading-token detection regression guards ---
# These exercise the shared command_invokes_git_commit helper that the hook
# now sources (replacing inline awk). Permit-path-only coverage is what let
# the original BSD-awk `\b` bug hide; these are the deny-path / mention-path
# guards the ticket asks for.

@test "denies 'cd <repo> && git commit' with an unpaired ADR (P366 cd-prefix)" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  run run_commit_hook "cd $REPO && git commit -m wip"
  [ "$status" -eq 2 ]
  [[ "$output" == *"deny"* ]]
}

@test "denies 'VAR=1 git commit' with an unpaired ADR (P366 env-prefix)" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  run run_commit_hook "GIT_AUTHOR_NAME=x git commit -m wip"
  [ "$status" -eq 2 ]
  [[ "$output" == *"deny"* ]]
}

@test "permits a command that merely MENTIONS 'git commit' as a substring (P366 mention-path)" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  run run_commit_hook "grep -r 'git commit' docs/"
  [ "$status" -eq 0 ]
}

@test "permits 'git commit-tree' plumbing (P366 token-boundary)" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  run run_commit_hook "git commit-tree HEAD"
  [ "$status" -eq 0 ]
}

@test "registered in hooks.json as PreToolUse Bash (criterion 6)" {
  HOOKS_JSON="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/hooks.json"
  run jq -e '.hooks.PreToolUse[] | select(.matcher=="Bash") | .hooks[] | select(.command | test("architect-readme-pairing-check"))' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
}
