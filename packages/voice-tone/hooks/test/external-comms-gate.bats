#!/usr/bin/env bats
# Tests for packages/voice-tone/hooks/external-comms-gate.sh
# (P038 / ADR-028 amended 2026-05-14).
#
# Behavioural: the gate denies outbound prose tool calls until the
# wr-voice-tone:external-comms subagent has reviewed the draft and the
# per-evaluator marker `external-comms-voice-tone-reviewed-<KEY>` has been
# written. Voice-tone evaluator does NOT run the leak-pattern pre-filter
# (EXTERNAL_COMMS_LEAK_PREFILTER=no in external-comms-evaluator.conf).
# Composition with the risk-scorer evaluator happens at firing level —
# both gates fire on the same PreToolUse event when both plugins installed.

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$HOOKS_DIR/external-comms-gate.sh"

  TEST_SESSION="bats-vt-extcomms-gate-$$-${BATS_TEST_NUMBER}"
  RDIR="${TMPDIR:-/tmp}/claude-risk-${TEST_SESSION}"
  rm -rf "$RDIR"
  mkdir -p "$RDIR"

  # Voice-tone evaluator's policy file is docs/VOICE-AND-TONE.md per the .conf.
  TEST_PROJECT_DIR="$(mktemp -d)"
  mkdir -p "$TEST_PROJECT_DIR/docs"
  printf "## Voice principles\n- Direct\n- No hedging\n## Banned patterns\n- 'happy to help further'\n" \
    > "$TEST_PROJECT_DIR/docs/VOICE-AND-TONE.md"

  unset BYPASS_RISK_GATE
}

teardown() {
  rm -rf "$RDIR"
  rm -rf "$TEST_PROJECT_DIR"
  unset BYPASS_RISK_GATE
}

# ---------- Helpers ----------

build_bash_input() {
  local cmd="$1"
  python3 -c "
import json, sys
print(json.dumps({
    'session_id': '$TEST_SESSION',
    'tool_name': 'Bash',
    'tool_input': {'command': sys.argv[1]},
}))
" "$cmd"
}

build_write_input() {
  local file_path="$1"
  local content="$2"
  python3 -c "
import json, sys
print(json.dumps({
    'session_id': '$TEST_SESSION',
    'tool_name': 'Write',
    'tool_input': {'file_path': sys.argv[1], 'content': sys.argv[2]},
}))
" "$file_path" "$content"
}

# Mock `gh repo view --json visibility` for the git-commit-message surface
# repo-visibility precondition (P365). vis ∈ {PUBLIC,PRIVATE,INTERNAL}; pass the
# literal "FAIL" to simulate gh absent / unauthenticated (non-zero exit).
mock_gh_visibility() {
  local vis="$1"
  mkdir -p "$TEST_PROJECT_DIR/mockbin"
  if [ "$vis" = "FAIL" ]; then
    printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_PROJECT_DIR/mockbin/gh"
  else
    printf '#!/usr/bin/env bash\necho %s\n' "$vis" > "$TEST_PROJECT_DIR/mockbin/gh"
  fi
  chmod +x "$TEST_PROJECT_DIR/mockbin/gh"
}

run_hook() {
  local input="$1"
  run bash -c "cd '$TEST_PROJECT_DIR' && export PATH='$TEST_PROJECT_DIR/mockbin':\$PATH && printf '%s' \"\$1\" | '$HOOK'" _ "$input"
}

# ---------- Tests ----------

@test "non-matching Bash command (ls) is allowed silently" {
  INPUT=$(build_bash_input "ls -la")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "gh issue create with clean draft denies and prompts wr-voice-tone:external-comms delegation (no marker yet)" {
  INPUT=$(build_bash_input "gh issue create --title T --body 'we observed a build failure on Node 20'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
}

# P377/RFC-029: the BYPASS_RISK_GATE env override was removed. The only
# clearance path named in the deny is delegation to the external-comms subagent.
@test "marker-absent deny names the reviewer and offers no env override (P377/RFC-029)" {
  INPUT=$(build_bash_input "gh issue create --title T --body 'we observed a build failure on Node 20'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
  [[ "$output" != *"BYPASS_RISK_GATE=1"* ]]
}

@test "voice-tone evaluator skips leak pre-filter (EXTERNAL_COMMS_LEAK_PREFILTER=no)" {
  # A draft with leak-shaped content (revenue figure with business context) would
  # hard-fail in the risk evaluator. The voice-tone gate must NOT hard-fail; leak
  # detection is the risk evaluator's concern. Voice-tone deny-and-delegates for
  # subagent review, same as any clean draft.
  INPUT=$(build_bash_input "gh issue comment 42 --body 'Acme Corp 2.4M ARR is a real concern'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
  # Must NOT name a leak class.
  [[ "$output" != *"credential"* ]]
  [[ "$output" != *"financial"* ]]
}

@test "BYPASS_RISK_GATE=1 does NOT bypass the gate (removed P377/RFC-029)" {
  INPUT=$(build_bash_input "gh issue create --title T --body 'we observed a build failure'")
  run bash -c "cd '$TEST_PROJECT_DIR' && BYPASS_RISK_GATE=1 printf '%s' \"\$1\" | BYPASS_RISK_GATE=1 '$HOOK'" _ "$INPUT"
  [ "$status" -eq 0 ]
  # The env override no longer short-circuits — the gate still denies the
  # unreviewed external-comms draft.
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
}

@test "per-evaluator marker (external-comms-voice-tone-reviewed-<KEY>) allows the call" {
  DRAFT="we observed a build failure on Node 20"
  SURFACE="gh-issue-create"
  KEY=$(printf '%s\n%s' "$DRAFT" "$SURFACE" | shasum -a 256 | cut -d' ' -f1)
  touch "${RDIR}/external-comms-voice-tone-reviewed-${KEY}"

  INPUT=$(build_bash_input "gh issue create --title T --body '$DRAFT'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "risk-scorer marker (external-comms-risk-reviewed-<KEY>) does NOT satisfy the voice-tone gate" {
  # Independent per-evaluator markers: a risk-evaluator PASS marker does not
  # imply voice-tone has been reviewed.
  DRAFT="we observed a build failure on Node 20"
  SURFACE="gh-issue-create"
  KEY=$(printf '%s\n%s' "$DRAFT" "$SURFACE" | shasum -a 256 | cut -d' ' -f1)
  touch "${RDIR}/external-comms-risk-reviewed-${KEY}"

  INPUT=$(build_bash_input "gh issue create --title T --body '$DRAFT'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
}

@test "docs/VOICE-AND-TONE.md absent yields advisory-only mode (permits)" {
  rm -f "$TEST_PROJECT_DIR/docs/VOICE-AND-TONE.md"
  INPUT=$(build_bash_input "gh issue create --title T --body 'we observed a failure'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  # Must NOT deny when policy file is absent.
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" != *"\"permissionDecision\":\"deny\""* ]]
  # Must surface the advisory systemMessage.
  [[ "$output" == *"docs/VOICE-AND-TONE.md not found"* ]]
}

@test "PreToolUse:Write on .changeset/*.md triggers deny+delegate" {
  INPUT=$(build_write_input ".changeset/test.md" "Add some feature. Happy to help further with details.")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
}

@test "PreToolUse:Write on a non-changeset path is ignored" {
  INPUT=$(build_write_input "src/foo.ts" "happy to help further")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "gh api security-advisories triggers the gate" {
  INPUT=$(build_bash_input "gh api repos/foo/bar/security-advisories --method POST --field summary='vulnerability detail'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
}

@test "npm publish triggers the gate" {
  INPUT=$(build_bash_input "npm publish")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
}

@test "deny message references the on-demand skill (/wr-voice-tone:assess-external-comms)" {
  INPUT=$(build_bash_input "gh issue comment 42 --body 'a draft'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/wr-voice-tone:assess-external-comms"* ]]
}

@test "marker name uses evaluator id from external-comms-evaluator.conf (voice-tone, not risk)" {
  # Regression: the canonical hook sources the .conf and uses its EVALUATOR_ID
  # in the marker filename. The risk-scorer's marker name does NOT satisfy the
  # voice-tone gate even if the KEY matches.
  DRAFT="some draft body"
  SURFACE="gh-issue-create"
  KEY=$(printf '%s\n%s' "$DRAFT" "$SURFACE" | shasum -a 256 | cut -d' ' -f1)
  # Pre-amendment combined marker — should NOT satisfy the new voice-tone gate.
  touch "${RDIR}/external-comms-reviewed-${KEY}"

  INPUT=$(build_bash_input "gh issue create --title T --body '$DRAFT'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

# ---------------------------------------------------------------------------
# P010 / ADR-028 amended 2026-05-25 — deny-after-PASS regression (voice-tone).
# Mirror of the risk-scorer regression: the gate sees the FULL changeset
# content (YAML frontmatter + body) but the mark hook keys the marker on the
# <draft> body. After the fix the gate strips frontmatter before hashing, so
# a body-keyed voice-tone PASS marker permits the changeset Write.
# ---------------------------------------------------------------------------

@test "P010: changeset Write permits when the voice-tone PASS marker is keyed on the <draft> body (frontmatter stripped before hash)" {
  BODY="external-comms gate strips changeset frontmatter before key hash"
  SURFACE="changeset-author"
  KEY=$(printf '%s\n%s' "$BODY" "$SURFACE" | shasum -a 256 | cut -d' ' -f1)
  touch "${RDIR}/external-comms-voice-tone-reviewed-${KEY}"

  CONTENT=$'---\n"@windyroad/voice-tone": patch\n---\n\n'"$BODY"
  INPUT=$(build_write_input ".changeset/p010-fix.md" "$CONTENT")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# P360 — voice-tone evaluator disclaims the git-commit-message surface.
# docs/VOICE-AND-TONE.md § Scope explicitly excludes commit messages ("It does
# NOT apply to: ... Commit messages (covered by ADR-014 + ADR-018)"), so a
# voice-tone review of a commit-message body is a guaranteed-PASS no-op
# (~19K tokens per round-trip). external-comms-evaluator.conf sets
# EXTERNAL_COMMS_SKIP_SURFACES=git-commit-message, so the gate silent-passes the
# prose-review delegation on this surface in EVERY repo — visibility-independent
# (the P360 skip is placed ahead of the P365 visibility precondition). The
# risk-scorer evaluator, whose .conf leaves the skip list empty, still gates
# this surface (its leak check is meaningful) — covered by
# packages/risk-scorer/hooks/test/external-comms-gate.bats.
#
# Supersedes the original P082 Phase 1 voice-tone commit-message tests, which
# asserted DENY on PUBLIC — that gate fire was the no-op P360 removes.
# ---------------------------------------------------------------------------

@test "P360: git commit -m silent-passes (voice-tone disclaims commit messages)" {
  mock_gh_visibility PUBLIC
  INPUT=$(build_bash_input "git commit -m \"I've implemented the feature\"")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P360: git commit --message silent-passes with no marker round-trip" {
  mock_gh_visibility PUBLIC
  INPUT=$(build_bash_input "git commit --message \"happy to help further with this fix\"")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P360: git commit --amend -m silent-passes" {
  mock_gh_visibility PUBLIC
  INPUT=$(build_bash_input "git commit --amend -m \"rewritten subject\"")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P360: git commit HEREDOC body silent-passes without a marker" {
  mock_gh_visibility PUBLIC
  BODY=$'feat(foo): add bar\n\nWe observed a build failure on Node 20.'
  CMD=$'git commit -m "$(cat <<\'EOF\'\n'"$BODY"$'\nEOF\n)"'
  INPUT=$(build_bash_input "$CMD")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P360: commit-message skip is visibility-independent (PRIVATE silent-passes)" {
  mock_gh_visibility PRIVATE
  INPUT=$(build_bash_input "git commit -m \"I've implemented the feature\"")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P360: commit-message skip is visibility-independent (INTERNAL silent-passes)" {
  mock_gh_visibility INTERNAL
  INPUT=$(build_bash_input "git commit -m \"I've implemented the feature\"")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P360: commit-message skip is visibility-independent (indeterminate gh silent-passes)" {
  mock_gh_visibility FAIL
  INPUT=$(build_bash_input "git commit -m \"I've implemented the feature\"")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P082: bare git commit (editor flow) is silently allowed per SC1" {
  # No -m / --message → .git/COMMIT_EDITMSG doesn't exist at PreToolUse
  # time. Phase 1 skip is pragmatic; the editor flow has user-eyeballs.
  INPUT=$(build_bash_input "git commit")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P082: git merge is silently allowed (not a git commit verb)" {
  INPUT=$(build_bash_input "git merge --no-ff feature-branch")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P082→P377/RFC-029: BYPASS_RISK_GATE=1 is inert — does not short-circuit the gate" {
  # gh-issue is an unconditionally-gated external surface (no visibility
  # precondition). Setting BYPASS_RISK_GATE=1 has no effect: the unreviewed
  # draft still denies, identically to the no-env-var case.
  INPUT=$(build_bash_input "gh issue create --title T --body 'we observed a build failure on Node 20'")
  run bash -c "cd '$TEST_PROJECT_DIR' && BYPASS_RISK_GATE=1 printf '%s' \"\$1\" | BYPASS_RISK_GATE=1 '$HOOK'" _ "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
}

@test "P360: the skip is surface-scoped — gh-issue is NOT skipped (still denies+delegates)" {
  # EXTERNAL_COMMS_SKIP_SURFACES lists only git-commit-message; the inherently
  # external gh-issue surface stays gated. Guards against the skip list over-
  # matching (e.g. a substring or blanket-skip regression).
  mock_gh_visibility PUBLIC
  INPUT=$(build_bash_input "gh issue create --title x --body 'a clean issue body'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"wr-voice-tone:external-comms"* ]]
}

@test "P365: PRIVATE visibility does NOT short-circuit the gh-issue surface (still denies+delegates)" {
  mock_gh_visibility PRIVATE
  INPUT=$(build_bash_input "gh issue create --title x --body 'a clean issue body'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"gh-issue-create"* ]]
}

# ---------------------------------------------------------------------------
# P364 — backtick-bearing double-quoted --body marker-key mismatch.
# The voice-tone gate shares the byte-identical canonical external-comms-gate.sh
# (ADR-017 sync), so the P364 shell-unescape fix applies here too: a body with
# backslash-escaped backticks in --body "..." must unescape to the logical
# <draft> body the PostToolUse mark hook hashes, or the PASS marker never
# permits. DISTINCT from P276 / P010 (whitespace / frontmatter).
# ---------------------------------------------------------------------------

@test "P364: backtick-bearing double-quoted --body permits when marker keyed on the unescaped logical body" {
  LOGICAL='Tidied the wording in `external-comms-gate` for the patch.'
  SURFACE="gh-issue-comment"
  KEY=$(printf '%s\n%s' "$LOGICAL" "$SURFACE" | shasum -a 256 | cut -d' ' -f1)
  touch "${RDIR}/external-comms-voice-tone-reviewed-${KEY}"

  CMD='gh issue comment 42 --body "Tidied the wording in \`external-comms-gate\` for the patch."'
  INPUT=$(build_bash_input "$CMD")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P364: single-quoted --body with literal backticks stays literal (no unescaping applied)" {
  LOGICAL='Tidied the wording in `plain_span` here.'
  SURFACE="gh-issue-comment"
  KEY=$(printf '%s\n%s' "$LOGICAL" "$SURFACE" | shasum -a 256 | cut -d' ' -f1)
  touch "${RDIR}/external-comms-voice-tone-reviewed-${KEY}"

  INPUT=$(build_bash_input "gh issue comment 42 --body 'Tidied the wording in \`plain_span\` here.'")
  run_hook "$INPUT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
