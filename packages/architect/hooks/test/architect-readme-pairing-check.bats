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

  TARGET_REPO="$(mktemp -d)"
  git -C "$TARGET_REPO" init -q
  git -C "$TARGET_REPO" config user.email t@e.x
  git -C "$TARGET_REPO" config user.name t
  mkdir -p "$TARGET_REPO/docs/decisions"
  echo "# compendium" > "$TARGET_REPO/docs/decisions/README.md"
  echo "# adr 050" > "$TARGET_REPO/docs/decisions/050-y.proposed.md"
  git -C "$TARGET_REPO" add -A
  git -C "$TARGET_REPO" commit -q -m init
}

teardown() {
  cd /
  rm -rf "$REPO" "$TARGET_REPO"
}

# Run the hook with a synthetic `git commit` Bash PreToolUse payload.
run_commit_hook() {
  local cmd="${1:-git commit -m wip}"
  echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$cmd\"}}" | bash "$HOOK"
}

run_commit_hook_payload() {
  local payload="$1"
  local process_repo="${2:-$REPO}"
  (cd "$process_repo" && printf '%s\n' "$payload" | bash "$HOOK")
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
  run jq -e '.hooks.PreToolUse[] | select(.matcher | test("Bash")) | .hooks[] | select(.command | test("architect-dispatch[.]sh pre-tool"))' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
  run grep -F "architect-readme-pairing-check.sh" "$(dirname "$HOOKS_JSON")/architect-dispatch.sh"
  [ "$status" -eq 0 ]
}

@test "workdir targets the clean command checkout instead of the dirty hook checkout" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  payload=$(jq -n --arg dir "$TARGET_REPO" '{tool_name:"Bash",tool_input:{command:"git commit -m wip",workdir:$dir}}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 0 ]
}

@test "workdir targets an unpaired command checkout instead of the clean hook checkout" {
  echo "# adr 050 edited" > "$TARGET_REPO/docs/decisions/050-y.proposed.md"
  git -C "$TARGET_REPO" add docs/decisions/050-y.proposed.md
  payload=$(jq -n --arg dir "$TARGET_REPO" '{tool_name:"Bash",tool_input:{command:"git commit -m wip",workdir:$dir}}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 2 ]
  [[ "$output" == *"050-y.proposed.md"* ]]
}

@test "tool cwd wins over a conflicting workdir" {
  echo "# adr 050 edited" > "$TARGET_REPO/docs/decisions/050-y.proposed.md"
  git -C "$TARGET_REPO" add docs/decisions/050-y.proposed.md
  payload=$(jq -n --arg cwd "$REPO" --arg workdir "$TARGET_REPO" '{tool_name:"Bash",tool_input:{command:"git commit -m wip",cwd:$cwd,workdir:$workdir}}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 0 ]
}

@test "empty tool cwd falls through to workdir" {
  echo "# adr 050 edited" > "$TARGET_REPO/docs/decisions/050-y.proposed.md"
  git -C "$TARGET_REPO" add docs/decisions/050-y.proposed.md
  payload=$(jq -n --arg workdir "$TARGET_REPO" '{tool_name:"Bash",tool_input:{command:"git commit -m wip",cwd:"",workdir:$workdir}}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 2 ]
  [[ "$output" == *"050-y.proposed.md"* ]]
}

@test "empty workdir falls through to leading cd" {
  echo "# adr 050 edited" > "$TARGET_REPO/docs/decisions/050-y.proposed.md"
  git -C "$TARGET_REPO" add docs/decisions/050-y.proposed.md
  payload=$(jq -n --arg cmd "cd '$TARGET_REPO' && git commit -m wip" '{tool_name:"Bash",tool_input:{command:$cmd,workdir:""}}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 2 ]
  [[ "$output" == *"050-y.proposed.md"* ]]
}

@test "leading quoted cd selects the command checkout without cwd fields" {
  echo "# adr 050 edited" > "$TARGET_REPO/docs/decisions/050-y.proposed.md"
  git -C "$TARGET_REPO" add docs/decisions/050-y.proposed.md
  payload=$(jq -n --arg cmd "cd '$TARGET_REPO' && git commit -m wip" '{tool_name:"Bash",tool_input:{command:$cmd}}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 2 ]
  [[ "$output" == *"050-y.proposed.md"* ]]
}

@test "top-level cwd selects the command checkout when tool fields are absent" {
  echo "# adr 050 edited" > "$TARGET_REPO/docs/decisions/050-y.proposed.md"
  git -C "$TARGET_REPO" add docs/decisions/050-y.proposed.md
  payload=$(jq -n --arg dir "$TARGET_REPO" '{tool_name:"Bash",tool_input:{command:"git commit -m wip"},cwd:$dir}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 2 ]
  [[ "$output" == *"050-y.proposed.md"* ]]
}

@test "relative declared checkout denies instead of falling back" {
  payload=$(jq -n '{tool_name:"Bash",tool_input:{command:"git commit -m wip",workdir:"relative"}}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 2 ]
  [[ "$output" == *"absolute readable Git worktree"* ]]
}

@test "non-Git declared checkout denies instead of falling back" {
  non_git=$(mktemp -d)
  payload=$(jq -n --arg dir "$non_git" '{tool_name:"Bash",tool_input:{command:"git commit -m wip",workdir:$dir}}')
  run run_commit_hook_payload "$payload"
  rm -rf "$non_git"
  [ "$status" -eq 2 ]
  [[ "$output" == *"absolute readable Git worktree"* ]]
}

@test "missing checkout metadata preserves legacy process-cwd behavior" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  run run_commit_hook
  [ "$status" -eq 2 ]
  [[ "$output" == *"049-x.proposed.md"* ]]
}

@test "all-empty checkout metadata preserves legacy process-cwd behavior" {
  echo "# adr 049 edited" > docs/decisions/049-x.proposed.md
  git add docs/decisions/049-x.proposed.md
  payload=$(jq -n '{tool_name:"Bash",tool_input:{command:"git commit -m wip",cwd:"",workdir:""},cwd:""}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 2 ]
  [[ "$output" == *"049-x.proposed.md"* ]]
}

@test "nested declared path resolves its Git root" {
  mkdir -p "$TARGET_REPO/nested/path"
  echo "# adr 050 edited" > "$TARGET_REPO/docs/decisions/050-y.proposed.md"
  git -C "$TARGET_REPO" add docs/decisions/050-y.proposed.md
  payload=$(jq -n --arg dir "$TARGET_REPO/nested/path" '{tool_name:"Bash",tool_input:{command:"git commit -m wip",workdir:$dir}}')
  run run_commit_hook_payload "$payload"
  [ "$status" -eq 2 ]
  [[ "$output" == *"050-y.proposed.md"* ]]
}
