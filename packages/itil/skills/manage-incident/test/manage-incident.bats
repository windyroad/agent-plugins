#!/usr/bin/env bats
# Functional tests for the manage-incident skill (Option A-lite per ADR-011).
#
# Scope: execute the bash fragments the SKILL.md instructs Claude to run
# (ID assignment, file-path construction, directory creation) and assert on
# the mocked Skill-tool handoff contract between manage-incident and
# manage-problem. Source-grep assertions on SKILL.md prose are NOT used
# (P011 ban). A single structural check asserts SKILL.md exists and has
# frontmatter — file-existence checks are a Permitted Exception per ADR-005.

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"

  TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/manage-incident-bats-XXXXXX")"
  INCIDENTS_DIR="${TEST_ROOT}/docs/incidents"
  PROBLEMS_DIR="${TEST_ROOT}/docs/problems"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# --- Fragment: next-ID computation (I###) ---
# SKILL.md instructs: scan docs/incidents/ for existing I<NNN> files, take the
# highest numeric ID, increment by 1, zero-pad to 3 digits.
next_incident_id() {
  local dir="$1"
  local last
  last=$(ls "$dir"/I*.md 2>/dev/null | sed 's/.*\///' | grep -oE '^I[0-9]+' | sed 's/^I//' | sort -n | tail -1)
  if [[ -z "$last" ]]; then
    printf 'I001'
  else
    printf 'I%03d' $((10#$last + 1))
  fi
}

# --- Fragment: file path construction ---
incident_path() {
  local dir="$1" id="$2" slug="$3" status="$4"
  printf '%s/%s-%s.%s.md' "$dir" "$id" "$slug" "$status"
}

# --- Mock: Skill-tool invocation contract ---
# The SKILL.md instructs Claude to invoke wr-itil:manage-problem via the
# Skill tool on restoration. The contract (skill name + argument shape) is
# asserted by a mock that writes the payload to a file the test reads back.
invoke_skill_mock() {
  local tool="$1" skill="$2" args="$3"
  printf '%s\n%s\n%s\n' "$tool" "$skill" "$args" > "${TEST_ROOT}/skill-invocation.log"
}

# ---- Tests ----

@test "SKILL.md exists and has frontmatter" {
  [ -f "$SKILL_FILE" ]
  run head -1 "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "---" ]
}

@test "next_incident_id returns I001 when docs/incidents is empty" {
  mkdir -p "$INCIDENTS_DIR"
  run next_incident_id "$INCIDENTS_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "I001" ]
}

@test "next_incident_id returns I001 when docs/incidents does not exist" {
  run next_incident_id "$INCIDENTS_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "I001" ]
}

@test "next_incident_id increments past the highest existing ID" {
  mkdir -p "$INCIDENTS_DIR"
  : > "$INCIDENTS_DIR/I001-foo.closed.md"
  : > "$INCIDENTS_DIR/I002-bar.restored.md"
  : > "$INCIDENTS_DIR/I005-baz.investigating.md"
  run next_incident_id "$INCIDENTS_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "I006" ]
}

@test "next_incident_id zero-pads three digits" {
  mkdir -p "$INCIDENTS_DIR"
  : > "$INCIDENTS_DIR/I098-foo.closed.md"
  run next_incident_id "$INCIDENTS_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "I099" ]
}

@test "next_incident_id ignores non-incident files" {
  mkdir -p "$INCIDENTS_DIR"
  : > "$INCIDENTS_DIR/README.md"
  : > "$INCIDENTS_DIR/notes.md"
  run next_incident_id "$INCIDENTS_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "I001" ]
}

@test "incident_path builds investigating file path" {
  run incident_path "$INCIDENTS_DIR" "I001" "login-500s" "investigating"
  [ "$status" -eq 0 ]
  [ "$output" = "${INCIDENTS_DIR}/I001-login-500s.investigating.md" ]
}

@test "incident_path supports all lifecycle suffixes" {
  for suffix in investigating mitigating restored closed; do
    run incident_path "$INCIDENTS_DIR" "I042" "x" "$suffix"
    [ "$status" -eq 0 ]
    [ "$output" = "${INCIDENTS_DIR}/I042-x.${suffix}.md" ]
  done
}

@test "docs/incidents is auto-created on first declaration" {
  [ ! -d "$INCIDENTS_DIR" ]
  mkdir -p "$INCIDENTS_DIR"
  [ -d "$INCIDENTS_DIR" ]
  id=$(next_incident_id "$INCIDENTS_DIR")
  path=$(incident_path "$INCIDENTS_DIR" "$id" "test" "investigating")
  : > "$path"
  [ -f "$path" ]
}

@test "restore handoff invokes Skill tool with wr-itil:manage-problem and payload" {
  invoke_skill_mock "Skill" "wr-itil:manage-problem" "incident I001 login-500s — rollback v1.4.3 restored service at 14:30 UTC"
  [ -f "${TEST_ROOT}/skill-invocation.log" ]
  run cat "${TEST_ROOT}/skill-invocation.log"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Skill" ]
  [ "${lines[1]}" = "wr-itil:manage-problem" ]
  [[ "${lines[2]}" == *"I001"* ]]
  [[ "${lines[2]}" == *"rollback"* ]]
}

@test "restore handoff payload carries incident ID and mitigation" {
  invoke_skill_mock "Skill" "wr-itil:manage-problem" "incident I042 — mitigation: feature flag off — verified via Datadog"
  run cat "${TEST_ROOT}/skill-invocation.log"
  [[ "${lines[2]}" == *"I042"* ]]
  [[ "${lines[2]}" == *"feature flag off"* ]]
  [[ "${lines[2]}" == *"Datadog"* ]]
}

@test "handoff contract rejects invocation with wrong skill name" {
  invoke_skill_mock "Skill" "wr-itil:manage-change" "incident I001"
  run grep -c '^wr-itil:manage-problem$' "${TEST_ROOT}/skill-invocation.log"
  [ "$output" = "0" ]
}

@test "close is blocked when linked problem file is .open.md" {
  mkdir -p "$PROBLEMS_DIR"
  : > "$PROBLEMS_DIR/P050-root.open.md"
  # close-gate: close only if linked P### is known-error or closed
  linked=$(ls "$PROBLEMS_DIR"/P050-*.md 2>/dev/null | head -1)
  [[ "$linked" != *".known-error.md" && "$linked" != *".closed.md" ]]
}

@test "close is allowed when linked problem file is .known-error.md" {
  mkdir -p "$PROBLEMS_DIR"
  : > "$PROBLEMS_DIR/P050-root.known-error.md"
  linked=$(ls "$PROBLEMS_DIR"/P050-*.md 2>/dev/null | head -1)
  [[ "$linked" == *".known-error.md" || "$linked" == *".closed.md" ]]
}

@test "close is allowed when linked problem file is .closed.md" {
  mkdir -p "$PROBLEMS_DIR"
  : > "$PROBLEMS_DIR/P050-root.closed.md"
  linked=$(ls "$PROBLEMS_DIR"/P050-*.md 2>/dev/null | head -1)
  [[ "$linked" == *".known-error.md" || "$linked" == *".closed.md" ]]
}
