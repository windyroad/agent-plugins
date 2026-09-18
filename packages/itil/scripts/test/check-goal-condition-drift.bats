#!/usr/bin/env bats
#
# Behavioural coverage for check-goal-condition-drift.sh — the check-only
# variant of the ADR-017 canonical-plus-check shape (ADR-017 Confirmation
# requires a test set covering the divergence-detection mode, not just CI
# wiring; a containment check with no test of its own can pass vacuously).
#
# Each divergence case perturbs exactly ONE embed. Perturbing the canonical
# and its copies together leaves them agreeing with each other, which is a
# check that proves nothing — that mistake is why these cases are explicit.
#
# @adr ADR-017 (canonical body + --check drift mode + CI step)
# @adr ADR-128 (per-ticket goal anchors each AFK iteration)

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../check-goal-condition-drift.sh"
  SKILL="${BATS_TEST_DIRNAME}/../../skills/work-problems/SKILL.md"
  # Guard the search roots: a bats run against a missing file would otherwise
  # assert nothing and pass green locally while failing on CI.
  [ -f "$SCRIPT" ] || { echo "missing script: $SCRIPT" >&2; return 1; }
  [ -f "$SKILL" ] || { echo "missing skill: $SKILL" >&2; return 1; }
  FIXTURE="${BATS_TEST_TMPDIR}/skill.md"
}

@test "passes against the shipped SKILL.md" {
  run bash "$SCRIPT" "$SKILL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"contain the canonical condition verbatim"* ]]
}

@test "counts only standalone embed markers, not the inline prose mention" {
  # The prose above the canonical block names the marker when explaining the
  # check. A substring match would count it as a third embed.
  run bash "$SCRIPT" "$SKILL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 embed(s)"* ]]
}

@test "detects divergence in the headless launch embed only" {
  sed '/claude -p --permission-mode bypassPermissions/s/ naming the gate that could not complete//' "$SKILL" > "$FIXTURE"
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"DRIFT"* ]]
}

@test "detects divergence in the interactive embed only" {
  sed '/^  \/goal The \/wr-itil:work-problems AFK backlog drain/s|(fresh open/known-error glob) ||' "$SKILL" > "$FIXTURE"
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"DRIFT"* ]]
}

@test "fails rather than passing vacuously when no embeds are present" {
  grep -v 'CANONICAL-CONDITION-EMBED' "$SKILL" > "$FIXTURE"
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no CANONICAL-CONDITION-EMBED blocks found"* ]]
}

@test "exits 2 when the canonical block is missing" {
  grep -v 'CANONICAL-GOAL-CONDITION-SOURCE' "$SKILL" > "$FIXTURE"
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 2 ]
}

@test "exits 2 on a missing file" {
  run bash "$SCRIPT" "${BATS_TEST_TMPDIR}/does-not-exist.md"
  [ "$status" -eq 2 ]
}

@test "accepts --check for symmetry with the sync-script family" {
  run bash "$SCRIPT" "$SKILL" --check
  [ "$status" -eq 0 ]
}

# --- unattended-declaration coupling (ADR-128) ---------------------------
#
# The singular skill's pinned short-circuit keys on a sentence emitted by the
# orchestrator's dispatch prompt. Reword either side and the short-circuit
# silently collapses to "never", re-admitting an unanswerable prompt and an
# off-grain commit into an absent-user subprocess. These cases exist because
# nothing else binds the two files.

# Build a two-skill fixture tree mirroring the real sibling layout, since the
# script resolves the consumer as <dir>/../work-problem/SKILL.md.
setup_pair() {
  PAIR="${BATS_TEST_TMPDIR}/pair"
  mkdir -p "$PAIR/work-problems" "$PAIR/work-problem"
  SIBLING="${BATS_TEST_DIRNAME}/../../skills/work-problem/SKILL.md"
  [ -f "$SIBLING" ] || { echo "missing sibling: $SIBLING" >&2; return 1; }
  cp "$SKILL" "$PAIR/work-problems/SKILL.md"
  cp "$SIBLING" "$PAIR/work-problem/SKILL.md"
}

@test "passes when the unattended declaration matches on both sides" {
  setup_pair
  run bash "$SCRIPT" "$PAIR/work-problems/SKILL.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"unattended declaration matches"* ]]
}

@test "detects a reworded declaration on the dispatcher side" {
  setup_pair
  sed -i.bak 's/\*\*The user is AFK and this run is unattended\.\*\*/**The user is away.**/' "$PAIR/work-problems/SKILL.md"
  run bash "$SCRIPT" "$PAIR/work-problems/SKILL.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unattended declaration differs"* ]]
}

@test "detects a removed consumer marker on the singular-skill side" {
  setup_pair
  grep -v 'UNATTENDED-DECLARATION-CONSUMER' "$PAIR/work-problem/SKILL.md" > "$PAIR/work-problem/SKILL.md.new"
  mv "$PAIR/work-problem/SKILL.md.new" "$PAIR/work-problem/SKILL.md"
  run bash "$SCRIPT" "$PAIR/work-problems/SKILL.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"UNATTENDED-DECLARATION-CONSUMER"* ]]
}

@test "detects a removed declaration on the dispatcher side" {
  setup_pair
  grep -v 'UNATTENDED-DECLARATION-SOURCE' "$PAIR/work-problems/SKILL.md" > "$PAIR/work-problems/SKILL.md.new"
  mv "$PAIR/work-problems/SKILL.md.new" "$PAIR/work-problems/SKILL.md"
  run bash "$SCRIPT" "$PAIR/work-problems/SKILL.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"UNATTENDED-DECLARATION-SOURCE"* ]]
}

@test "extraction is anchored on the marker, not the last bold span on the line" {
  # Regression guard: an unanchored greedy match returned whichever bold span
  # happened to be last, which reported drift on a correct tree.
  setup_pair
  run bash "$SCRIPT" "$PAIR/work-problems/SKILL.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"declared by the dispatcher"* ]]
}
