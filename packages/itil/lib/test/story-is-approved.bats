#!/usr/bin/env bats
# Direct-call contract for `story_is_approved` (ADR-103).
#
# The enforcement OUTCOME is tested through the hook, in
# hooks/test/itil-no-implement-draft-gate.bats — that is where a deny and its
# message live, and it stays the primary surface. This file covers the three
# invariants the hook route structurally cannot reach, because the hook only
# ever calls the predicate one way.
#
# The predicate has three callers and they disagree about shell state:
#   detect-unratified-stories-maps.sh  sets nullglob, then calls
#   itil-no-implement-draft-gate.sh    UNsets nullglob, then calls
#   check-rfc-stories-ratified.sh      never sets it, runs under `set -euo pipefail`
# So a regression that only misbehaves under one of those is invisible to a
# suite that exercises the other.
#
# @adr ADR-103 (map is the approval surface) ADR-090 (drift-invalidated marker)
# @adr ADR-052 (behavioural — invokes the predicate, asserts its verdict)

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  # shellcheck source=/dev/null
  source "$REPO_ROOT/packages/itil/lib/story-oversight.sh"
  MARK="$REPO_ROOT/packages/itil/scripts/mark-story-oversight-confirmed.sh"
  TMP="$BATS_TEST_TMPDIR/w"
  mkdir -p "$TMP/stories" "$TMP/maps/draft" "$TMP/maps/archived"
  cd "$TMP"
}

# Ratification goes through the real writer, never a hand-rolled marker — the
# hash has one definition and a fixture that reimplemented it would drift.
_map() {
  local f="maps/$2/$1-f.html"
  printf '<!DOCTYPE html>\n<body>\n<script id="story-map-data" type="application/json">\n{ "storyMapId": "%s", "backbone": [] }\n</script>\n</body>\n</html>\n' "$1" > "$f"
  [ "${3:-}" = ratified ] && bash "$MARK" "$f" >/dev/null 2>&1
  return 0
}
_story() { printf -- '---\nstatus: accepted\n%s\n---\n\n# STORY-900\n' "$1" > stories/s.md; }

@test "verdict is identical whether the caller has nullglob on or off" {
  # detect-unratified-stories-maps.sh calls with it ON; the commit gate calls
  # with it OFF. A predicate that answered differently would make approval
  # depend on which tool asked.
  _story 'story-maps: [STORY-MAP-940]'
  _map STORY-MAP-940 draft ratified

  shopt -s nullglob; run story_is_approved stories/s.md maps; local on="$status"
  shopt -u nullglob; run story_is_approved stories/s.md maps; local off="$status"
  [ "$on" -eq 0 ]
  [ "$on" -eq "$off" ]
}

@test "an id resolving nowhere denies under BOTH nullglob states" {
  # This is the case the `[ -e "$cand" ]` guard exists for. With nullglob OFF an
  # unmatched glob survives as a literal word, so a predicate that dropped the
  # guard would count it as a match, hand a literal path to
  # is_story_map_ratified, and — since that greps a non-existent file — still
  # deny. It only becomes permissive if the count check is also loosened, so the
  # value here is pinning the guard against a "this looks redundant" removal.
  _story 'story-maps: [STORY-MAP-999]'

  shopt -s nullglob; run story_is_approved stories/s.md maps; [ "$status" -ne 0 ]
  shopt -u nullglob; run story_is_approved stories/s.md maps; [ "$status" -ne 0 ]
}

@test "the call does not mutate the caller's nullglob setting" {
  # The predicate is SOURCED, so a `shopt -s`/`shopt -u` inside it changes the
  # caller's shell. That is not hypothetical: detect-unratified-stories-maps.sh
  # sets nullglob once at the top and relies on it for a later glob over
  # docs/story-maps/*.html — a directory with no top-level .html files. Unset it
  # mid-run and that glob survives as a literal, and the detector reports the
  # literal string `docs/story-maps/*.html` as an unratified artefact path.
  _story 'story-maps: [STORY-MAP-940]'
  _map STORY-MAP-940 draft ratified

  # `shopt -p X` exits NON-ZERO when X is unset, and bats runs under `set -e`,
  # so every capture needs `|| true` — otherwise the unset half of this test
  # dies on its own probe rather than on the property.
  local before after
  shopt -s nullglob
  before="$(shopt -p nullglob || true)"
  story_is_approved stories/s.md maps || true
  after="$(shopt -p nullglob || true)"
  [ "$after" = "$before" ]

  shopt -u nullglob
  before="$(shopt -p nullglob || true)"
  story_is_approved stories/s.md maps || true
  after="$(shopt -p nullglob || true)"
  [ "$after" = "$before" ]
}

@test "a story naming no map is not approved — dropping the field cannot self-approve" {
  # The one branch where a regression GRANTS approval rather than withholding
  # it: an empty id list must not fall through to a vacuous true.
  _story 'estimated-effort: S'
  run story_is_approved stories/s.md maps
  [ "$status" -ne 0 ]

  # And an empty inline list is the same case wearing a different hat.
  _story 'story-maps: []'
  run story_is_approved stories/s.md maps
  [ "$status" -ne 0 ]
}

@test "an ambiguous id denies even when every copy is ratified" {
  # Two copies of one id under different lifecycle dirs, BOTH ratified. An
  # arbitrary-pick implementation approves here; only a count-must-be-one
  # predicate denies. Ratifying both is what makes this isolate ambiguity
  # rather than accidentally testing whichever copy the glob happened to pick.
  _story 'story-maps: [STORY-MAP-940]'
  _map STORY-MAP-940 draft ratified
  _map STORY-MAP-940 archived ratified
  run story_is_approved stories/s.md maps
  [ "$status" -ne 0 ]
}
