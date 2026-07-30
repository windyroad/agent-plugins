#!/usr/bin/env bats
# Behavioural tests for migrate-story-status-mirror.sh — the P474 one-time
# migration that removes the redundant `**Status**:` body mirror from story
# artefacts and carries their existing ratification forward.
#
# Why the mirror goes rather than getting normalised out of the hash: the body
# line only repeats the frontmatter `status:` the fingerprint already excludes,
# and every mirror discovered otherwise costs another normaliser rule (this was
# the fourth in a family of three). Maintainer direction 2026-07-29 — kill the
# class, not the instance.
#
# The load-bearing safety property is that this RE-FINGERPRINTS, never
# RE-RATIFIES. `human-oversight: confirmed` records that a human confirmed
# something and is never written here; `oversight-hash` only identifies WHICH
# content that confirmation covered. Recomputing it over content whose only
# delta is an excluded mechanical mirror removes zero ratified substance. The
# `stored == hash(before)` gate is what makes that provable per artefact — drop
# the gate and this becomes a blanket re-bless, i.e. the P348 hollow-marker
# class.
#
# @problem P474  @adr ADR-090 ADR-101

setup() {
  SCRIPTS="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  MIGRATE="$SCRIPTS/migrate-story-status-mirror.sh"
  # shellcheck source=/dev/null
  source "$SCRIPTS/../lib/story-oversight.sh"
  TMPD="$(mktemp -d)"; cd "$TMPD"
  mkdir -p docs/stories/draft docs/stories/accepted
}
teardown() { cd /; rm -rf "$TMPD"; }

# Independent mode probe for assertions. Shape-validated for the same reason the
# script's own helper is: GNU `stat -f` prints a filesystem blob with exit 0, so
# an exit-status-only chain silently accepts garbage as a mode.
mode_of() {
  local m
  for m in "$(stat -c %a "$1" 2>/dev/null)" "$(stat -f %Lp "$1" 2>/dev/null)"; do
    case "$m" in [0-7][0-7][0-7] | [0-7][0-7][0-7][0-7]) printf '%s' "$m"; return 0 ;; esac
  done
  printf 'UNKNOWN'
}

# Write a story whose stored hash is valid for its current content.
seed_ratified() {
  local path="$1" fm_status="$2" body_status="$3"
  printf -- '---\nstatus: %s\nstory-id: x\nhuman-oversight: confirmed\noversight-hash: PLACEHOLDER\n---\n\n# STORY-901: a story\n\n**Status**: %s\n**Reported**: 2026-07-29\n\n## User value\n\nvalue prose.\n\n## Acceptance criteria\n\n- [ ] a criterion\n' \
    "$fm_status" "$body_status" > "$path"
  local h; h="$(oversight_content_hash "$path")"
  sed -i.bak "s/oversight-hash: PLACEHOLDER/oversight-hash: $h/" "$path" && rm -f "$path.bak"
}

@test "removes the body Status mirror when it agrees with frontmatter" {
  seed_ratified docs/stories/draft/STORY-901-x.md draft draft
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  ! grep -qE '^\*\*Status\*\*:' docs/stories/draft/STORY-901-x.md
  # Everything else survives.
  grep -q '^\*\*Reported\*\*: 2026-07-29' docs/stories/draft/STORY-901-x.md
  grep -q 'value prose.' docs/stories/draft/STORY-901-x.md
}

@test "a currently-ratified story is still ratified after migration" {
  seed_ratified docs/stories/draft/STORY-901-x.md draft draft
  run is_story_map_ratified docs/stories/draft/STORY-901-x.md
  [ "$status" -eq 0 ]
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  run is_story_map_ratified docs/stories/draft/STORY-901-x.md
  [ "$status" -eq 0 ]
}

# The whole point: after migration, the accept transition must stop drifting.
@test "after migration an accept transition does NOT drift the hash" {
  seed_ratified docs/stories/draft/STORY-901-x.md draft draft
  bash "$MIGRATE" docs/stories
  # Advance status the way manage-story does: frontmatter + a criterion tick.
  sed -i.bak 's/^status: draft/status: accepted/; s/- \[ \] a criterion/- [x] a criterion/' \
    docs/stories/draft/STORY-901-x.md && rm -f docs/stories/draft/STORY-901-x.md.bak
  run is_story_map_ratified docs/stories/draft/STORY-901-x.md
  [ "$status" -eq 0 ]
}

@test "SKIPS and REPORTS a story whose body Status carries extra information" {
  # `superseded (was: draft)` and `in-progress (2026-07-23)` both exist in the
  # real corpus — the line is carrying provenance the frontmatter does not, so
  # deleting it would lose content rather than de-duplicate it.
  seed_ratified docs/stories/draft/STORY-902-y.md superseded 'superseded (was: draft)'
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  grep -qE '^\*\*Status\*\*: superseded \(was: draft\)' docs/stories/draft/STORY-902-y.md
  [[ "$output" == *"STORY-902"* ]]
  [[ "$output" == *"disagree"* ]] || [[ "$output" == *"SKIP"* ]]
}

@test "does NOT revive an already-drifted story" {
  seed_ratified docs/stories/draft/STORY-903-z.md draft draft
  # Real substance edit after ratification → drifted before migration runs.
  printf '\nAn edit made after ratification.\n' >> docs/stories/draft/STORY-903-z.md
  run is_story_map_ratified docs/stories/draft/STORY-903-z.md
  [ "$status" -ne 0 ]
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  run is_story_map_ratified docs/stories/draft/STORY-903-z.md
  [ "$status" -ne 0 ]
}

@test "never writes human-oversight — an unconfirmed story stays unconfirmed" {
  printf -- '---\nstatus: draft\nhuman-oversight: unconfirmed\n---\n\n# STORY-904\n\n**Status**: draft\n\n## User value\n\nv.\n' \
    > docs/stories/draft/STORY-904-w.md
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  grep -q '^human-oversight: unconfirmed' docs/stories/draft/STORY-904-w.md
  ! grep -q '^human-oversight: confirmed' docs/stories/draft/STORY-904-w.md
}

# ADR-101: the post-hoc drain finds AFK-accepted stories via oversight-basis.
# Migration must not strip it, or those stories stop surfacing for review.
@test "preserves oversight-basis so the ADR-101 post-hoc drain still finds it" {
  seed_ratified docs/stories/accepted/STORY-905-v.md accepted accepted
  printf -- '%s\n' "$(sed 's/^human-oversight: confirmed/human-oversight: confirmed\noversight-basis: pure-decomposition/' docs/stories/accepted/STORY-905-v.md)" \
    > docs/stories/accepted/STORY-905-v.md
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  grep -q '^oversight-basis: pure-decomposition' docs/stories/accepted/STORY-905-v.md
}

@test "is idempotent — a second run changes nothing" {
  seed_ratified docs/stories/draft/STORY-901-x.md draft draft
  bash "$MIGRATE" docs/stories
  cp docs/stories/draft/STORY-901-x.md /tmp/after-first-$$.md
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  diff /tmp/after-first-$$.md docs/stories/draft/STORY-901-x.md
  rm -f /tmp/after-first-$$.md
}

@test "leaves README.md alone — it documents the template, it is not a story" {
  printf -- '# Stories\n\n**Status**: <status>\n\nTemplate docs.\n' > docs/stories/README.md
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  grep -qE '^\*\*Status\*\*: <status>' docs/stories/README.md
  [[ "$output" != *"README.md"* ]]
}

@test "reports the touched set so the re-fingerprint is auditable" {
  seed_ratified docs/stories/draft/STORY-901-x.md draft draft
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  [[ "$output" == *"STORY-901"* ]]
}

# The migration writes via mktemp+mv, and mktemp creates 0600. Without an
# explicit mode carry-over every migrated story loses its group/other read bit.
# `chmod --reference` is GNU-only, so the portable stat read is what makes this
# hold on darwin — where the earlier --reference form silently fell through to a
# hardcoded 644 while the call site claimed to preserve the mode.
@test "preserves the story file's mode across the rewrite" {
  seed_ratified docs/stories/draft/STORY-906-mode.md draft draft
  chmod 640 docs/stories/draft/STORY-906-mode.md
  before="$(mode_of docs/stories/draft/STORY-906-mode.md)"
  [ "$before" = "640" ]
  run bash "$MIGRATE" docs/stories
  [ "$status" -eq 0 ]
  after="$(mode_of docs/stories/draft/STORY-906-mode.md)"
  [ "$after" = "640" ]
}
