#!/usr/bin/env bats

# P131: itil-claude-space-protection.sh PreToolUse:Write|Edit hook must
# block agent writes to project-scoped `.claude/` paths NOT in the
# user-space allow-list, unless an approval marker is present.
#
# Per ADR-037 + P081 (feedback_behavioural_tests.md): behavioural
# assertions — simulate the hook's payload on stdin and assert on
# emitted JSON permissionDecision and exit status. No source-grep on
# hook content.
#
# References:
#   ADR-009 — marker lifecycle (this hook adds a new persistent class)
#   ADR-013 Rule 6 — non-interactive fail-safe
#   ADR-038 — progressive disclosure (deny message <500 bytes)
#   ADR-045 — hook injection budget (silent on allow path)
#   P131    — user-space write protection driver

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/itil-claude-space-protection.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  mkdir -p .claude/skills/myskill .claude/commands .claude/agents \
    .claude/hooks .claude/projects/abc/memory .claude/worktrees \
    docs/plans
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

run_hook() {
  local tool="$1"
  local file_path="$2"
  local json
  json=$(printf '{"tool_name":"%s","tool_input":{"file_path":"%s"},"session_id":"test-sid"}' \
    "$tool" "$file_path")
  echo "$json" | bash "$HOOK"
}

# Helper: compute approval-marker filename for a project-relative path
marker_path_for() {
  local rel_path="$1"
  local hash
  if command -v shasum >/dev/null 2>&1; then
    hash=$(printf '%s' "$rel_path" | shasum -a 256 | awk '{print $1}')
  else
    hash=$(printf '%s' "$rel_path" | sha256sum | awk '{print $1}')
  fi
  echo ".claude/.agent-write-approved-${hash}"
}

# --- Core deny path: protected .claude/ writes without marker ---

@test "deny: Write to .claude/plans/foo.md without marker" {
  run run_hook "Write" "$PWD/.claude/plans/foo.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"BLOCKED"* ]]
}

@test "deny: Write to .claude/audits/2026-04-28.md without marker" {
  run run_hook "Write" "$PWD/.claude/audits/2026-04-28.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
}

@test "deny: Edit to existing agent-introduced .claude/plans file" {
  mkdir -p .claude/plans
  echo "stub" > .claude/plans/foo.md
  run run_hook "Edit" "$PWD/.claude/plans/foo.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
}

@test "deny: Write to .claude/scratch/state.json without marker" {
  run run_hook "Write" "$PWD/.claude/scratch/state.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# --- Allow paths: user-space allow-list ---

@test "allow: Write to .claude/settings.json" {
  run run_hook "Write" "$PWD/.claude/settings.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: Write to .claude/settings.local.json" {
  run run_hook "Write" "$PWD/.claude/settings.local.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to .claude/MEMORY.md" {
  run run_hook "Write" "$PWD/.claude/MEMORY.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to .claude/.install-updates-consent" {
  run run_hook "Write" "$PWD/.claude/.install-updates-consent"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to .claude/scheduled_tasks.lock" {
  run run_hook "Write" "$PWD/.claude/scheduled_tasks.lock"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to .claude/skills/install-updates/SKILL.md (skills subtree)" {
  run run_hook "Write" "$PWD/.claude/skills/install-updates/SKILL.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to .claude/commands/foo.md (commands subtree)" {
  run run_hook "Write" "$PWD/.claude/commands/foo.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to .claude/agents/foo.md (agents subtree)" {
  run run_hook "Write" "$PWD/.claude/agents/foo.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to .claude/hooks/foo.sh (hooks subtree)" {
  run run_hook "Write" "$PWD/.claude/hooks/foo.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to .claude/projects/abc/memory/MEMORY.md (Claude Code state)" {
  run run_hook "Write" "$PWD/.claude/projects/abc/memory/MEMORY.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to .claude/worktrees/something (worktrees subtree)" {
  run run_hook "Write" "$PWD/.claude/worktrees/something"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# --- Allow paths: outside .claude/ ---

@test "allow: Write to docs/plans/foo.md (not under .claude/)" {
  run run_hook "Write" "$PWD/docs/plans/foo.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to packages/itil/hooks/foo.sh" {
  mkdir -p packages/itil/hooks
  run run_hook "Write" "$PWD/packages/itil/hooks/foo.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to absolute path outside PWD project root" {
  run run_hook "Write" "/Users/someone/.claude/plans/foo.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Write to ~/.claude path (user home, outside project)" {
  run run_hook "Write" "$HOME/.claude/projects/xyz/foo.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# --- Approval-marker bypass ---

@test "allow: Write to .claude/plans/foo.md WHEN approval marker exists" {
  marker=$(marker_path_for ".claude/plans/foo.md")
  : > "$marker"
  run run_hook "Write" "$PWD/.claude/plans/foo.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "deny: marker for one path does not authorize a different path" {
  marker=$(marker_path_for ".claude/plans/foo.md")
  : > "$marker"
  run run_hook "Write" "$PWD/.claude/plans/bar.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
}

@test "allow: user can Write the approval marker itself" {
  marker=$(marker_path_for ".claude/plans/foo.md")
  run run_hook "Write" "$PWD/$marker"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# --- Tool-name and edge cases ---

@test "allow: Read tool on protected .claude/ path is unaffected" {
  mkdir -p .claude/plans
  echo "stub" > .claude/plans/foo.md
  run bash -c "echo '{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$PWD/.claude/plans/foo.md\"}}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: Glob tool on .claude/ is unaffected (pattern, not file_path)" {
  run bash -c "echo '{\"tool_name\":\"Glob\",\"tool_input\":{\"pattern\":\".claude/**/*.md\"}}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "allow: empty file_path exits 0 without action" {
  run bash -c "echo '{\"tool_name\":\"Write\",\"tool_input\":{}}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# --- Allow-list anchor depth (architect note) ---

@test "deny: .claude/plans/foo.local.json (deeper than root) — *.local.json must not pass at arbitrary depth" {
  run run_hook "Write" "$PWD/.claude/plans/foo.local.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
}

@test "allow: .claude/foo.local.json (root depth) — *.local.json convention" {
  run run_hook "Write" "$PWD/.claude/foo.local.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# --- Deny message contract (ADR-038 progressive disclosure) ---

@test "deny message names P131" {
  run run_hook "Write" "$PWD/.claude/plans/foo.md"
  [[ "$output" == *"P131"* ]]
}

@test "deny message suggests docs/ alternative" {
  run run_hook "Write" "$PWD/.claude/plans/foo.md"
  [[ "$output" == *"docs/"* ]]
}

@test "deny message names the approval-marker bypass" {
  run run_hook "Write" "$PWD/.claude/plans/foo.md"
  [[ "$output" == *".agent-write-approved-"* ]]
}

@test "deny message references project CLAUDE.md MANDATORY rule" {
  run run_hook "Write" "$PWD/.claude/plans/foo.md"
  [[ "$output" == *"CLAUDE.md"* ]]
}

@test "deny message stays under ADR-038 progressive-disclosure 500-byte cap" {
  run run_hook "Write" "$PWD/.claude/plans/foo.md"
  # Extract the permissionDecisionReason value and check its byte length.
  reason=$(echo "$output" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data['hookSpecificOutput']['permissionDecisionReason'])
except Exception as e:
    print('')
")
  byte_len=$(printf '%s' "$reason" | wc -c)
  # Bound: the deny message must be discoverable + actionable but
  # progressive — < 500 bytes per ADR-038.
  [ "$byte_len" -lt 500 ]
}

# --- ADR-045 silent-on-pass: allow path emits zero bytes ---

@test "allow path emits no output (ADR-045 Pattern 1 silent-on-pass)" {
  run run_hook "Write" "$PWD/.claude/settings.json"
  [ "$status" -eq 0 ]
  # Empty stdout — silent on allow.
  [ -z "$output" ]
}

@test "non-Write|Edit tool emits no output (silent-on-pass)" {
  run bash -c "echo '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\"}}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
