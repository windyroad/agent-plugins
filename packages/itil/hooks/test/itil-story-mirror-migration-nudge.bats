#!/usr/bin/env bats
# Behavioural tests for itil-story-mirror-migration-nudge.sh — the P474 / RFC-059
# self-firing cadence for the story `**Status**:` mirror migration.
#
# Why this exists: the migration is a PATH shim, so it does not surface in
# autocomplete, and its only announcement was the release note. Release notes
# cannot fire in an adopter's repo — prose counts as zero control paths — so
# artefacts predating the fix would keep the defect indefinitely while newly
# captured stories were immune. A maintenance action with no automatic trigger
# does not happen.
#
# Three contract conditions this suite locks, per the JTBD-009 review:
#   1. Nudge-only, never auto-run — JTBD-009's "I review the rewritten artefacts
#      before they ship" is a ratified outcome, so the hook must not migrate.
#   2. Names the PATH shim, never a repo-relative `packages/...` path, which
#      would only resolve in the source monorepo (P151/P153/P219/P317).
#   3. Silent when clean, so steady state costs nothing.
#
# @problem P474  @adr ADR-049 ADR-090  @story STORY-054

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/itil/hooks/itil-story-mirror-migration-nudge.sh"
  TMPD="$(mktemp -d)"
  mkdir -p "$TMPD/docs/stories/draft" "$TMPD/docs/stories/accepted"
  # AFK iters export the shared oversight guard; unset so the positive cases do
  # not false-RED inside one (the P391 hermeticity class).
  unset WR_SUPPRESS_OVERSIGHT_NUDGE
}
teardown() { unset WR_SUPPRESS_OVERSIGHT_NUDGE; rm -rf "$TMPD"; }

seed_with_mirror() {
  printf -- '---\nstatus: draft\n---\n\n# STORY-901: x\n\n**Status**: draft\n**Reported**: 2026-07-30\n' \
    > "$TMPD/docs/stories/draft/STORY-901-x.md"
}
seed_clean() {
  printf -- '---\nstatus: draft\n---\n\n# STORY-902: y\n\n**Reported**: 2026-07-30\n' \
    > "$TMPD/docs/stories/draft/STORY-902-y.md"
}

@test "fires when a story still carries the **Status** mirror" {
  seed_with_mirror
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  [[ "$output" == *"[wr-itil]"* ]]
}

@test "names the PATH shim so it resolves in an adopter install" {
  seed_with_mirror
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [[ "$output" == *"wr-itil-migrate-story-status-mirror"* ]]
}

# The recurring adopter-portability class: a repo-relative path resolves only in
# the source monorepo, so source-repo dogfooding hides the breakage.
@test "never emits a repo-relative packages/ path" {
  seed_with_mirror
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [[ "$output" != *"packages/itil"* ]]
  [[ "$output" != *"scripts/migrate-story-status-mirror.sh"* ]]
}

@test "silent when no story carries the mirror" {
  seed_clean
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when there is no stories directory at all" {
  run env CLAUDE_PROJECT_DIR="$(mktemp -d)" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "counts affected stories rather than reporting a bare flag" {
  seed_with_mirror
  printf -- '---\nstatus: draft\n---\n\n# STORY-903: z\n\n**Status**: draft\n' \
    > "$TMPD/docs/stories/accepted/STORY-903-z.md"
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [[ "$output" == *"2"* ]]
}

# Ratified JTBD-009 outcome: the developer reviews the rewrite before it ships.
# A nudge that migrated on its own would breach that, so assert the file is
# untouched — this is the condition that keeps the hook inside the job.
@test "NEVER migrates — the story file is left exactly as found" {
  seed_with_mirror
  local before; before="$(cat "$TMPD/docs/stories/draft/STORY-901-x.md")"
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$before" = "$(cat "$TMPD/docs/stories/draft/STORY-901-x.md")" ]
  grep -qE '^\*\*Status\*\*: draft' "$TMPD/docs/stories/draft/STORY-901-x.md"
}

@test "self-suppresses under the shared AFK oversight guard" {
  seed_with_mirror
  run env WR_SUPPRESS_OVERSIGHT_NUDGE=1 CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "only the literal value 1 suppresses" {
  seed_with_mirror
  run env WR_SUPPRESS_OVERSIGHT_NUDGE=yes CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ -n "$output" ]
}

# README documents the template and legitimately shows the field; scanning it
# would make the nudge fire forever on a clean corpus.
@test "ignores docs/stories/README.md" {
  printf -- '# Stories\n\n**Status**: <status>\n' > "$TMPD/docs/stories/README.md"
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "registered on SessionStart startup in hooks.json" {
  run grep -c 'itil-story-mirror-migration-nudge.sh' "$REPO_ROOT/packages/itil/hooks/hooks.json"
  [ "$output" -ge 1 ]
}
