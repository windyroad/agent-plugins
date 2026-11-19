#!/usr/bin/env bats

setup() {
  HOOK_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMP="$(mktemp -d)"
  export TMPDIR="$TMP/runtime"
  export CLAUDE_PROJECT_DIR="$TMP/project"
  mkdir -p "$TMPDIR" "$CLAUDE_PROJECT_DIR/docs/decisions"
  git init -q "$CLAUDE_PROJECT_DIR"
  SESSION="architect-codex-$$"
  TARGET="agent-target"
  MARKER="/tmp/architect-reviewed-$SESSION"
  HASH="$MARKER.hash"
  PLAN="/tmp/architect-plan-reviewed-$SESSION"
  rm -f "$MARKER" "$HASH" "$PLAN"
}

teardown() {
  rm -f "$MARKER" "$HASH" "$PLAN"
  rm -rf "$TMP"
}

dispatch() {
  printf '%s' "$1" | python3 "$BATS_TEST_DIRNAME/architect-report-fixtures.py" | node "$HOOK_DIR/codex-agent-completion.mjs"
}

spawn() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__spawn_agent","tool_input":{"agent_type":"%s"},"tool_response":{"agent_id":"%s"}}' "$SESSION" "$CLAUDE_PROJECT_DIR" "$1" "$TARGET"
}

close() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__close_agent","tool_input":{"target":"%s"},"tool_response":{"previous_status":{"completed":"%s"}}}' "$SESSION" "$CLAUDE_PROJECT_DIR" "$TARGET" "$1"
}

stop() {
  printf '{"session_id":"architect-child-%s","cwd":"%s","hook_event_name":"SubagentStop","agent_type":"wr-architect:agent","agent_id":"%s","last_assistant_message":"%s"}' "$$" "$CLAUDE_PROJECT_DIR" "$TARGET" "$1"
}

prompt() {
  printf '{"session_id":"%s","cwd":"%s","hook_event_name":"UserPromptSubmit"}' "$SESSION" "$CLAUDE_PROJECT_DIR"
}

guarded_edit() {
  printf '{"session_id":"%s","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"src/example.js"}}' "$SESSION" "$CLAUDE_PROJECT_DIR"
}

@test "matched Codex architect PASS creates review markers" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(close '**Architecture Review: PASS**')"
  [ -f "$MARKER" ]
  [ -f "$HASH" ]
  [ -f "$PLAN" ]
}

@test "background Codex architect PASS is imported only by its parent" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(stop '**Architecture Review: PASS**')"
  [ ! -e "$MARKER" ]
  dispatch "$(guarded_edit)"
  [ -f "$MARKER" ]
  [ -f "$HASH" ]
  [ -f "$PLAN" ]
}

@test "background architect accepts the canonical H2 PASS and rejects conflicting verdicts" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(stop '## Architecture Review: PASS')"
  dispatch "$(guarded_edit)"
  [ -f "$MARKER" ]

  rm -f "$MARKER" "$HASH" "$PLAN"
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(stop '**Architecture Review: PASS**\n**Architecture Review: ISSUES FOUND**')"
  dispatch "$(guarded_edit)"
  [ ! -e "$MARKER" ]
}

@test "expired architect registrations do not make a current background review ambiguous" {
  dispatch "$(spawn wr-architect:agent)"
  live="$(find "$TMPDIR/codex-review-transport" -name 'registration-*.json' -print -quit)"
  stale="$TMPDIR/codex-review-transport/registration-$(printf 'a%.0s' {1..64}).json"
  jq '.parentSession = "expired-parent" | .createdAt = 0' "$live" > "$stale"

  dispatch "$(stop '**Architecture Review: PASS**')"
  dispatch "$(guarded_edit)"

  [ ! -e "$stale" ]
  [ -f "$MARKER" ]
}

@test "architect transport failures fail open without creating authorization" {
  blocker="$TMPDIR/codex-review-transport"
  printf 'not a directory\n' > "$blocker"

  run dispatch "$(spawn wr-architect:agent)"

  [ "$status" -eq 0 ]
  [ ! -e "$MARKER" ]
}

@test "issues and malformed output do not create PASS receipts" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(close '**Architecture Review: ISSUES FOUND**')"
  [ ! -e "$MARKER" ]
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(close 'review complete')"
  [ ! -e "$MARKER" ]
}

@test "unmatched close and non-architect target do not unlock" {
  dispatch "$(close '**Architecture Review: PASS**')"
  [ ! -e "$MARKER" ]
  dispatch "$(spawn default)"
  dispatch "$(close '**Architecture Review: PASS**')"
  [ ! -e "$MARKER" ]
}

@test "reused target clears stale architect identity" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(spawn default)"
  dispatch "$(close '**Architecture Review: PASS**')"
  [ ! -e "$MARKER" ]
}


native_start() {
  jq -cn --arg session "$SESSION" --arg cwd "$CLAUDE_PROJECT_DIR" --arg id "${1:-$TARGET}" '{session_id:$session,cwd:$cwd,hook_event_name:"SubagentStart",agent_type:"wr-architect:agent",agent_id:$id}'
}
native_registration() {
  local path
  for path in "$TMPDIR"/codex-review-transport/registration-*.json; do
    if jq -e --arg target "$TARGET" '.source == "subagent-start" and .target == $target' "$path" >/dev/null; then
      printf '%s\n' "$path"
      return
    fi
  done
  return 1
}
native_stop() {
  jq -cn --arg session "$SESSION" --arg cwd "$CLAUDE_PROJECT_DIR" --arg id "${1:-$TARGET}" '{session_id:$session,cwd:$cwd,hook_event_name:"SubagentStop",agent_type:"wr-architect:agent",agent_id:$id,last_assistant_message:"**Architecture Review: PASS**"}'
}
@test "native architecture without attributable dispatch advises without approval" {
  dispatch "$(native_start)"
  dispatch "$(native_stop)"
  [ ! -e "$MARKER" ]
  dispatch "$(guarded_edit)"
  [ ! -e "$MARKER" ]
  run bash -c 'printf "%s" "$1" | "$2/architect-enforce-edit.sh"' -- "$(guarded_edit)" "$HOOK_DIR"
  [ "$status" -eq 0 ]
}
@test "native architecture stop cannot use task alias to mask wrong opaque id" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(native_start)"
  dispatch "$(native_stop wrong-id | jq -c --arg alias "$TARGET" '.task_name=$alias')"
  dispatch "$(guarded_edit)"
  [ ! -e "$MARKER" ]
}
@test "native architecture stop cannot select another parent" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(native_start)"
  dispatch "$(native_stop | jq -c '.session_id="other-parent"')"
  dispatch "$(guarded_edit)"
  [ ! -e "$MARKER" ]
}
@test "native architecture duplicate start preserves age and binding" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(native_start)"
  first="$(cat "$(native_registration)")"
  dispatch "$(native_start)"
  [ "$(cat "$(native_registration)")" = "$first" ]
  echo changed > "$CLAUDE_PROJECT_DIR/docs/decisions/new.md"
  dispatch "$(native_start)"
  [ "$(cat "$(native_registration)")" = "$first" ]
  dispatch "$(native_stop)"
  dispatch "$(guarded_edit)"
  [ ! -e "$MARKER" ]
}
@test "native architecture completion is not refreshed by late legacy close" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(native_start)"
  dispatch "$(native_stop)"
  dispatch "$(guarded_edit)"
  [ -f "$MARKER" ]
  rm -f "$MARKER" "$HASH" "$PLAN"
  dispatch "$(close '**Architecture Review: PASS**')"
  dispatch "$(native_start)"
  dispatch "$(native_stop)"
  dispatch "$(guarded_edit)"
  [ ! -e "$MARKER" ]
}

@test "native architecture availability cannot consume an old legacy pending receipt" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(stop '**Architecture Review: PASS**')"
  dispatch "$(native_start)"
  dispatch "$(guarded_edit)"
  [ ! -e "$MARKER" ]
}
@test "native architecture expired registration cannot authorize an edit" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(native_start)"
  node -e 'const fs=require("fs");const p=process.argv[1];const d=JSON.parse(fs.readFileSync(p));d.createdAt=Date.now()-4000000;fs.writeFileSync(p,JSON.stringify(d));' "$(native_registration)"
  dispatch "$(native_stop)"
  dispatch "$(guarded_edit)"
  [ ! -e "$MARKER" ]
}
@test "native architecture registrations support concurrent exact identities" {
  TARGET=first-id
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(native_start first-id)"
  TARGET=second-id
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(native_start second-id)"
  dispatch "$(native_stop second-id)"
  dispatch "$(guarded_edit)"
  [ -f "$MARKER" ]
  rm -f "$MARKER" "$HASH" "$PLAN"
  dispatch "$(native_stop first-id)"
  dispatch "$(guarded_edit)"
  [ -f "$MARKER" ]
}


close_text() {
  jq -cn --arg session "$SESSION" --arg cwd "$CLAUDE_PROJECT_DIR" --arg target "$TARGET" --arg text "$1" \
    '{session_id:$session,cwd:$cwd,tool_name:"multi_agent_v1__close_agent",tool_input:{target:$target},tool_response:{previous_status:{completed:$text}}}'
}

@test "verdict contract: native completion accepts the unquoted alias and ignores quoted history" {
  local text
  for text in \
    '**Architecture verdict: PASS, with advisories.** The scoped change is compliant.' \
    $'## Architecture review: PASS\n\n> **architecture review: ISSUES FOUND**\n```markdown\n**architecture verdict: ISSUES FOUND**\n```' \
    $'**Architecture Review: PASS**\n\n> **Architecture Review: ISSUES FOUND**\n\n```markdown\n**Architecture verdict: ISSUES FOUND**\n```'; do
    rm -f "$MARKER" "$HASH" "$PLAN"
    TARGET="contract-valid-$RANDOM"
    dispatch "$(spawn wr-architect:agent)"
    dispatch "$(close_text "$text")"
    [ -f "$MARKER" ]
    [ -f "$HASH" ]
    [ -f "$PLAN" ]
  done
}

@test "verdict contract: native quotes conflicts and malformed headings supply no PASS receipt" {
  local text
  for text in \
    '> **Architecture Review: PASS**' \
    '> **Architecture verdict: PASS**' \
    '## Architecture review: pass' \
    $'**Architecture Review: PASS**\n## architecture review: ISSUES FOUND' \
    $'**Architecture Review: PASS**\n**architecture verdict: UNKNOWN**' \
    'The example says **Architecture verdict: PASS**' \
    $'```markdown\n**Architecture verdict: PASS**\n```' \
    $'**Architecture Review: PASS**\n**Architecture verdict: ISSUES FOUND**' \
    $'**Architecture verdict: PASS** **Architecture Review: ISSUES FOUND**' \
    $'**Architecture Review: PASS**\n**Architecture verdict: UNKNOWN**' \
    $'**Architecture Review: PASS**\n```markdown\nunfinished' \
    '**Architecture verdict: ISSUES FOUND**' \
    '**Architecture verdict: NEEDS DIRECTION**'; do
    rm -f "$MARKER" "$HASH" "$PLAN"
    TARGET="contract-invalid-$RANDOM"
    dispatch "$(spawn wr-architect:agent)"
    dispatch "$(close_text "$text")"
    [ ! -e "$MARKER" ]
    [ ! -e "$HASH" ]
    [ ! -e "$PLAN" ]
  done
}

@test "verdict contract: unknown native evidence remains advisory without inventing approval" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(close_text '> **Architecture Review: PASS**')"
  [ ! -e "$MARKER" ]
  run bash -c 'printf "%s" "$1" | "$2/architect-enforce-edit.sh"' -- "$(guarded_edit)" "$HOOK_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *'action permitted'* ]]
  [ ! -e "$MARKER" ]
}

@test "plain verdict: native completion consumes explicit values without presentation markup" {
  local value expected text
  for value in PASS 'ISSUES FOUND' 'NEEDS DIRECTION'; do
    rm -f "$MARKER" "$HASH" "$PLAN"
    TARGET="plain-value-$RANDOM"
    text="Architecture Review: $value"
    dispatch "$(spawn wr-architect:agent)"
    dispatch "$(close_text "$text")"
    expected="$value"
    [ "$value" != 'ISSUES FOUND' ] || expected=FAIL
    run bash -c 'source "$1"; architect_verdict' -- "$HOOK_DIR/lib/architect-verdict.sh" <<< "$text"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
    if [ "$value" = PASS ]; then
      [ -f "$MARKER" ]
      [ -f "$HASH" ]
      [ -f "$PLAN" ]
    else
      [ ! -e "$MARKER" ]
      [ ! -e "$HASH" ]
      [ ! -e "$PLAN" ]
    fi
  done
}

@test "plain verdict: native completion preserves quoted history and rejects mixed authority" {
  local text
  text=$'Architecture Review: PASS\n> Architecture Review: ISSUES FOUND\n```markdown\nArchitecture Review: NEEDS DIRECTION\n```'
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(close_text "$text")"
  [ -f "$MARKER" ]
  for text in \
    '> Architecture Review: PASS' \
    'The example says Architecture Review: PASS' \
    $'```markdown\nArchitecture Review: PASS\n```' \
    'Architecture Review: PASS unless approved' \
    $'Architecture Review: PASS\n**Architecture Review: ISSUES FOUND**' \
    $'**Architecture Review: PASS**\nArchitecture Review: ISSUES FOUND' \
    $'Architecture Review: PASS\nArchitecture Review: PASS' \
    $'Architecture Review: PASS\nArchitecture Review: UNKNOWN' \
    $'Architecture Review: PASS\n```markdown\nunfinished'; do
    rm -f "$MARKER" "$HASH" "$PLAN"
    TARGET="plain-invalid-$RANDOM"
    dispatch "$(spawn wr-architect:agent)"
    dispatch "$(close_text "$text")"
    [ ! -e "$MARKER" ]
    [ ! -e "$HASH" ]
    [ ! -e "$PLAN" ]
  done
}

@test "advisory annotation: native completion consumes the same nonblocking PASS suffix across presentations" {
  local text
  for text in \
    '**Architecture Review: PASS** (with advisories)' \
    '## Architecture Review: PASS (with advisories)' \
    'Architecture Review: PASS (with advisories)' \
    '**Architecture verdict: PASS** (with advisories)'; do
    rm -f "$MARKER" "$HASH" "$PLAN"
    TARGET="advisory-valid-$RANDOM"
    dispatch "$(spawn wr-architect:agent)"
    dispatch "$(close_text "$text")"
    [ -f "$MARKER" ]
    [ -f "$HASH" ]
    [ -f "$PLAN" ]
  done
}

@test "advisory annotation: native completion does not promote quoted conditional or conflicting output" {
  local text
  for text in \
    '> **Architecture Review: PASS** (with advisories)' \
    'The example says **Architecture Review: PASS** (with advisories)' \
    $'```markdown\n**Architecture Review: PASS** (with advisories)\n```' \
    '**Architecture Review: PASS** (unless approved)' \
    '**Architecture Review: PASS** (with advisories) unless approved' \
    $'**Architecture Review: PASS** (with advisories)\nArchitecture Review: ISSUES FOUND' \
    $'**Architecture Review: PASS** (with advisories) **Architecture Review: ISSUES FOUND**' \
    $'**Architecture Review: PASS** (with advisories)\n**Architecture Review: PASS**' \
    '**Architecture Review: ISSUES FOUND** (with advisories)'; do
    rm -f "$MARKER" "$HASH" "$PLAN"
    TARGET="advisory-invalid-$RANDOM"
    dispatch "$(spawn wr-architect:agent)"
    dispatch "$(close_text "$text")"
    [ ! -e "$MARKER" ]
    [ ! -e "$HASH" ]
    [ ! -e "$PLAN" ]
  done
}
