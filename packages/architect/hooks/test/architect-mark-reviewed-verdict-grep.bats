#!/usr/bin/env bats

# Behavioural tests for architect-mark-reviewed.sh verdict parsing (P181).
# Drives the hook with realistic agent-output payloads and asserts marker
# creation matches the heading-shape contract in
# packages/architect/agents/agent.md "How to Report".
#
# P181 root cause: literal-substring grep `grep -q "ISSUES FOUND"` matches
# anywhere in the response — including prose narrative that mentions the
# verdict string without it being the canonical heading. Anchored heading
# match fixes the false-positive FAIL → silent marker-drop → edit block.

setup() {
  HOOKS_DIR="${ARCHITECT_PACKAGE_ROOT:+$ARCHITECT_PACKAGE_ROOT/hooks}"
  HOOKS_DIR="${HOOKS_DIR:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)}"
  HOOK="$HOOKS_DIR/architect-mark-reviewed.sh"
  TEST_SESSION="bats-arch-verdict-$$-${BATS_TEST_NUMBER}"
  REVIEW_MARKER="/tmp/architect-reviewed-${TEST_SESSION}"
  HASH_MARKER="/tmp/architect-reviewed-${TEST_SESSION}.hash"
  PLAN_MARKER="/tmp/architect-plan-reviewed-${TEST_SESSION}"
  rm -f "$REVIEW_MARKER" "$HASH_MARKER" "$PLAN_MARKER"
}

teardown() {
  rm -f "$REVIEW_MARKER" "$HASH_MARKER" "$PLAN_MARKER"
}

# Build a PostToolUse:Agent input JSON with the given agent-output text.
# Uses python3 (already a hard dep of gate-helpers.sh) for safe escaping.
_make_input() {
  local text="$1"
  python3 -c "
import json, sys
text = sys.argv[1]
print(json.dumps({
    'session_id': '$TEST_SESSION',
    'tool_name': 'Agent',
    'tool_input': {'subagent_type': 'wr-architect:agent'},
    'tool_response': {'content': [{'type': 'text', 'text': text}]}
}))
" "$text" | python3 "$BATS_TEST_DIRNAME/architect-report-fixtures.py"
}

# ---------------------------------------------------------------------------
# Sanity: canonical headings classify correctly
# ---------------------------------------------------------------------------

@test "verdict-grep: marker drops on canonical PASS heading" {
  INPUT=$(_make_input "**Architecture Review: PASS**

No conflicts with existing decisions.")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
  [ -f "$HASH_MARKER" ]
  [ -f "$PLAN_MARKER" ]
}

@test "verdict-grep: marker drops on canonical H2 PASS heading" {
  INPUT=$(_make_input "## Architecture Review: PASS

No conflicts with existing decisions.")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
  [ -f "$HASH_MARKER" ]
  [ -f "$PLAN_MARKER" ]
}

@test "verdict-grep: marker NOT created on canonical ISSUES FOUND heading" {
  INPUT=$(_make_input "**Architecture Review: ISSUES FOUND**

1. [Decision Conflict] — ADR-009 violation.")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
  [ ! -f "$HASH_MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict-grep: marker NOT created on canonical H2 ISSUES FOUND heading" {
  INPUT=$(_make_input "## Architecture Review: ISSUES FOUND

1. ADR-009 conflict.")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
  [ ! -f "$HASH_MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict-grep: quote-only PASS heading supplies no approval" {
  INPUT=$(_make_input "> **Architecture Review: PASS**
> No conflicts.")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
  [ ! -f "$HASH_MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict-grep: marker NOT created on ISSUES FOUND heading with blockquote prefix" {
  INPUT=$(_make_input "> **Architecture Review: ISSUES FOUND**
> 1. [Conflict] ...")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
}

# ---------------------------------------------------------------------------
# P181 bug-fix cases: substring-anywhere false-positive FAIL
# ---------------------------------------------------------------------------

@test "verdict-grep: no marker without a canonical heading" {
  INPUT=$(_make_input "I reviewed the change. The previous review surfaced ISSUES FOUND that have since been addressed; the current proposed change is fine.")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
}

@test "verdict-grep: NEEDS DIRECTION does not unlock edits" {
  INPUT=$(_make_input "**Architecture Review: NEEDS DIRECTION**

A decision must be recorded. This differs from an ISSUES FOUND verdict because the option is not pinned.

- Option A — ...
- Option B — ...")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict-grep: marker drops when PASS heading present and body also says 'ISSUES FOUND' inline" {
  INPUT=$(_make_input "**Architecture Review: PASS**

No conflicts. Note: earlier sessions reported ISSUES FOUND on adjacent files but those are out of scope here.")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
}

@test "verdict-grep: conflicting ISSUES FOUND then PASS headings do not unlock edits" {
  INPUT=$(_make_input "**Architecture Review: ISSUES FOUND**

**Architecture Review: PASS**")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
  [ ! -f "$HASH_MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict-grep: conflicting PASS then ISSUES FOUND headings do not unlock edits" {
  INPUT=$(_make_input "**Architecture Review: PASS**

**Architecture Review: ISSUES FOUND**")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
  [ ! -f "$HASH_MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict-grep: quoted H2 PASS does not unlock edits" {
  INPUT=$(_make_input 'The reviewer wrote `## Architecture Review: PASS`, but gave no verdict.')
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
  [ ! -f "$HASH_MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict-grep: malformed H2 PASS does not unlock edits" {
  INPUT=$(_make_input "## Architecture Review: PASS later")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
  [ ! -f "$HASH_MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict-grep: examples and mixed NEEDS DIRECTION verdicts do not unlock edits" {
  local output
  for output in \
    $'Example only:\n```markdown\n## Architecture Review: PASS\n```' \
    $'## Architecture Review: NEEDS DIRECTION\n\n```markdown\n## Architecture Review: PASS\n```' \
    $'Review follows:\n## Architecture Review: PASS' \
    $'## Architecture Review: PASS\n## Architecture Review: NEEDS DIRECTION' \
    $'**Architecture Review: PASS**\n**Architecture Review: PASS**'; do
    INPUT=$(_make_input "$output")
    echo "$INPUT" | "$HOOK"
    [ ! -f "$REVIEW_MARKER" ]
    [ ! -f "$HASH_MARKER" ]
    [ ! -f "$PLAN_MARKER" ]
  done
}

@test "verdict-grep: blank lines do not make a quoted H2 PASS authoritative" {
  INPUT=$(_make_input $'\n  \n  > ## Architecture Review: PASS\n\nNo conflicts.')
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
  [ ! -f "$HASH_MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict-grep: prose-only approval does not unlock edits" {
  INPUT=$(_make_input "Review complete — no issues found in the diff.")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
}


@test "verdict contract: Claude accepts the bounded unquoted alias with advisories and report text" {
  INPUT=$(_make_input '**Architecture verdict: PASS, with advisories.** The scoped change is compliant.')
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
  [ -f "$HASH_MARKER" ]
  [ -f "$PLAN_MARKER" ]
}

@test "verdict contract: Claude preserves a current verdict beside quoted history" {
  INPUT=$(_make_input $'**Architecture Review: PASS**\n\n> **Architecture Review: ISSUES FOUND**\n\n```markdown\n**Architecture verdict: ISSUES FOUND**\n```')
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
  [ -f "$HASH_MARKER" ]
}

@test "verdict contract: quoted malformed and conflicting Claude reports create no receipt" {
  local text
  for text in \
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
    '**Architecture verdict: PASS unless further approval arrives**' \
    '**Architecture verdict: ISSUES FOUND, with advisories.**' \
    '**Architecture verdict: NEEDS DIRECTION**'; do
    rm -f "$REVIEW_MARKER" "$HASH_MARKER" "$PLAN_MARKER"
    INPUT=$(_make_input "$text")
    echo "$INPUT" | "$HOOK"
    [ ! -e "$REVIEW_MARKER" ]
    [ ! -e "$HASH_MARKER" ]
    [ ! -e "$PLAN_MARKER" ]
  done
}

@test "verdict contract: unknown Claude evidence remains advisory without approval fabrication" {
  local project="$BATS_TEST_TMPDIR/project"
  mkdir -p "$project/docs/decisions"
  INPUT=$(_make_input '> **Architecture Review: PASS**')
  printf '%s' "$INPUT" | env CLAUDE_PROJECT_DIR="$project" "$HOOK"
  [ ! -e "$REVIEW_MARKER" ]
  run bash -c 'printf "%s" "$1" | env CLAUDE_PROJECT_DIR="$2" "$3/architect-enforce-edit.sh"' -- \
    "{\"session_id\":\"$TEST_SESSION\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"src/example.js\"}}" "$project" "$HOOKS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *'action permitted'* ]]
  [ ! -e "$REVIEW_MARKER" ]
}

@test "plain verdict: Claude consumes explicit values without presentation markup" {
  local value expected text
  for value in PASS 'ISSUES FOUND' 'NEEDS DIRECTION'; do
    rm -f "$REVIEW_MARKER" "$HASH_MARKER" "$PLAN_MARKER"
    text="Architecture Review: $value"
    printf '%s' "$(_make_input "$text")" | "$HOOK"
    expected="$value"
    [ "$value" != 'ISSUES FOUND' ] || expected=FAIL
    run bash -c 'source "$1"; architect_verdict' -- "$HOOKS_DIR/lib/architect-verdict.sh" <<< "$text"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
    if [ "$value" = PASS ]; then
      [ -f "$REVIEW_MARKER" ]
      [ -f "$HASH_MARKER" ]
      [ -f "$PLAN_MARKER" ]
    else
      [ ! -e "$REVIEW_MARKER" ]
      [ ! -e "$HASH_MARKER" ]
      [ ! -e "$PLAN_MARKER" ]
    fi
  done
}

@test "plain verdict: Claude preserves quoted history and rejects mixed authority" {
  local text
  text=$'Architecture Review: PASS\n> Architecture Review: ISSUES FOUND\n```markdown\nArchitecture Review: NEEDS DIRECTION\n```'
  printf '%s' "$(_make_input "$text")" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
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
    rm -f "$REVIEW_MARKER" "$HASH_MARKER" "$PLAN_MARKER"
    printf '%s' "$(_make_input "$text")" | "$HOOK"
    [ ! -e "$REVIEW_MARKER" ]
    [ ! -e "$HASH_MARKER" ]
    [ ! -e "$PLAN_MARKER" ]
  done
}

@test "advisory annotation: Claude consumes the same nonblocking PASS suffix across presentations" {
  local text
  for text in \
    '**Architecture Review: PASS** (with advisories)' \
    '## Architecture Review: PASS (with advisories)' \
    'Architecture Review: PASS (with advisories)' \
    '**Architecture verdict: PASS** (with advisories)'; do
    rm -f "$REVIEW_MARKER" "$HASH_MARKER" "$PLAN_MARKER"
    printf '%s' "$(_make_input "$text")" | "$HOOK"
    [ -f "$REVIEW_MARKER" ]
    [ -f "$HASH_MARKER" ]
    [ -f "$PLAN_MARKER" ]
  done
}

@test "advisory annotation: Claude does not promote quoted conditional or conflicting output" {
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
    rm -f "$REVIEW_MARKER" "$HASH_MARKER" "$PLAN_MARKER"
    printf '%s' "$(_make_input "$text")" | "$HOOK"
    [ ! -e "$REVIEW_MARKER" ]
    [ ! -e "$HASH_MARKER" ]
    [ ! -e "$PLAN_MARKER" ]
  done
}

@test "heading label casing preserves bound Claude receipt and shared verdict" {
  local text=$'## Architecture review: PASS\n\n> **architecture review: ISSUES FOUND**\n```markdown\n**architecture verdict: ISSUES FOUND**\n```'
  INPUT=$(_make_input "$text")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
  run bash -c 'source "$1"; architect_verdict' -- "$HOOKS_DIR/lib/architect-verdict.sh" <<< "$text"
  [ "$output" = PASS ]
}
