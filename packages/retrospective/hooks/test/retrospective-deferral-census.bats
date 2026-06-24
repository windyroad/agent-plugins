#!/usr/bin/env bats

# ADR-040 / P375: retrospective-deferral-census.sh (SessionStart) emits a one-line
# census + bounded top-offenders list when deferred-work markers exist that lack a
# self-firing trigger, is silent at zero, self-suppresses under the AFK guard
# (WR_SUPPRESS_DEFERRAL_CENSUS=1), respects the ADR-040 Tier-1 ≤2KB budget, scans
# BOTH docs/ and packages/ (.md only — code-comment false-positive guard), and is
# fail-open (never aborts session startup). Behavioural — exercises the hook against
# fixture trees. Marker vocabulary is the single source of truth in
# lib/deferral-markers.sh (P375 "shared vocabulary").

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/retrospective/hooks/retrospective-deferral-census.sh"
  PLUGIN_ROOT="$REPO_ROOT/packages/retrospective"
  DIR="$(mktemp -d)"
  mkdir -p "$DIR/docs/problems" "$DIR/packages/itil/skills/foo"
}

teardown() { rm -rf "$DIR"; }

mk() { mkdir -p "$(dirname "$DIR/$1")"; printf '%s\n' "$2" > "$DIR/$1"; }

@test "emits a census line with the total marker count" {
  mk "docs/problems/001-x.md" "Priority: 3 (deferred — re-rate at next /wr-itil:review-problems)"
  mk "docs/problems/002-y.md" "**Severity**: (deferred to investigation)"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deferred-work marker"* ]]
  [[ "$output" == *"[wr-retrospective]"* ]]
}

@test "lists the worst-offender files" {
  mk "docs/problems/001-x.md" "$(printf '(deferred to A)\n(deferred to B)\n(deferred to C)')"
  mk "docs/problems/002-y.md" "(deferred to D)"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [[ "$output" == *"001-x.md"* ]]
}

@test "scans BOTH docs/ and packages/ .md files" {
  mk "packages/itil/skills/foo/SKILL.md" "section deferred to /wr-itil:manage-rfc accepted transition"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKILL.md"* ]]
}

@test "silent when there are no deferred-work markers" {
  mk "docs/problems/001-x.md" "Everything here is rated and tracked."
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fail-open: silent + exit 0 when neither docs/ nor packages/ exists" {
  EMPTY="$(mktemp -d)"
  run env CLAUDE_PROJECT_DIR="$EMPTY" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  rm -rf "$EMPTY"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fail-open: marker lib unreadable → exit 0, no output, no abort" {
  mk "docs/problems/001-x.md" "(deferred to investigation)"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="/nonexistent/plugin/root" bash "$HOOK"
  [ "$status" -eq 0 ]
}

@test "AFK guard WR_SUPPRESS_DEFERRAL_CENSUS=1 suppresses entirely" {
  mk "docs/problems/001-x.md" "(deferred to investigation)"
  run env WR_SUPPRESS_DEFERRAL_CENSUS=1 CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "guard value other than 1 does not suppress" {
  mk "docs/problems/001-x.md" "(deferred to investigation)"
  run env WR_SUPPRESS_DEFERRAL_CENSUS=yes CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [[ "$output" == *"deferred-work marker"* ]]
}

@test "output respects the ADR-040 Tier-1 budget (<= 2048 bytes) even with many offenders" {
  for i in $(seq 1 50); do
    mk "docs/problems/$(printf '%03d' "$i")-ticket.md" "$(printf '(deferred to X)\n(deferred to Y)\n(deferred to Z)')"
  done
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  bytes=$(printf '%s' "$output" | wc -c | tr -d ' ')
  [ "$bytes" -le 2048 ]
}

@test "excludes archival records (CHANGELOG.md, *-history.md) — they are not rotting work" {
  mk "packages/itil/CHANGELOG.md" "$(printf '(deferred to A)\n(deferred to B)')"
  mk "docs/problems/README-history.md" "(deferred to investigation)"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "catches slice/phase-deferral phrasing (P378 fold) — 'lands in Slice N' etc." {
  mk "packages/itil/skills/foo/SKILL.md" "the executor lands in Slice 3 task B5.T9"
  mk "packages/itil/skills/bar/SKILL.md" "deferred to a hook-source slice"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deferred-work marker"* ]]
  [[ "$output" == *"SKILL.md"* ]]
}

@test "points at a drain path (run-retro / backlog) and cites P375" {
  mk "docs/problems/001-x.md" "(deferred to investigation)"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [[ "$output" == *"P375"* ]]
}
