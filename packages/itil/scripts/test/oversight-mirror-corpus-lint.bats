#!/usr/bin/env bats
# P474 / STORY-055 — corpus lint: no artefact may mirror an excluded key.
#
# This is a LINT, not a behavioural test, and the distinction is deliberate rather
# than an ADR-052 exception. ADR-052's forbidden class is structural assertion on
# document content *as a proxy for behaviour*; all its documented failure modes
# are proxy failures. Here the content IS the deliverable — "no live artefact
# carries a mirror" is a property of data, and data has no behaviour to assert.
# So it homes under ADR-005's script/data-validation authority, which ADR-052
# explicitly leaves intact.
#
# WHY it exists: P474's mirror audit was a one-time inspection, and a one-time
# inspection has no cadence. The fingerprint excludes four frontmatter keys; if
# any of them acquires a body mirror, accepting a story silently drops its own
# ratification and the no-implement gate then denies its own implementing commit.
# That already happened once with `status`.
#
# The behavioural half lives in the last test: it covers a mirror of ANY excluded
# key in ANY shape, including an HTML meta mirror, which the lint's line-anchored
# bold-key pattern structurally cannot reach.
#
# Two things this lint does NOT catch, recorded rather than implied:
#   1. The story-map `href` leg (open P474 task) — a card links
#      `../../stories/<state>/…`, so the lifecycle directory sits inside the map's
#      hashed content while the card's `data-status` is normalised out. No
#      bold-key pattern can see that.
#   2. A mirror written with leading whitespace or inside a list item — the cost
#      of line-anchoring, taken so no exclusion set is needed.
#
# @problem P474  @adr ADR-090 ADR-005 ADR-052  @story STORY-055

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  LIB="${REPO_ROOT}/packages/itil/lib/story-oversight.sh"
  # shellcheck source=/dev/null
  source "$LIB"
  STORIES="$REPO_ROOT/docs/stories"
  MAPS="$REPO_ROOT/docs/story-maps"
  TMPD="$(mktemp -d)"
}
teardown() { rm -rf "$TMPD"; }

# Build the pattern from the lib's own accessor, so a key added to the exclusion
# set is covered without editing this file. Case-INSENSITIVE is load-bearing: the
# accessor holds lowercase keys (`status`) while every real mirror is Title-Case
# (`**Status**:`), so a case-sensitive pattern built from the accessor matches
# nothing on arrival AND stays green when a mirror is reintroduced.
mirror_pattern() {
  local alt; alt="$(oversight_excluded_keys | paste -sd'|' -)"
  printf '^\\*\\*(%s)\\*\\*[[:space:]]*:' "$alt"
}

# Line-anchored on purpose. Unanchored, this matches four lines of legitimate
# prose *about* the defect (the stories README, two lines in STORY-054, and
# STORY-055's own problem trace), which would redden on arrival and require an
# exclusion list growing with every future story that discusses a mirror.
scan() {
  grep -rniE "$(mirror_pattern)" "$@" 2>/dev/null || true
}

@test "lint: the excluded-key accessor is non-empty and the pattern is well-formed" {
  # Guard against a silently-empty pattern — the whole lint would go vacuous.
  local keys; keys="$(oversight_excluded_keys)"
  [ -n "$keys" ]
  [ "$(printf '%s\n' "$keys" | wc -l | tr -d ' ')" -ge 4 ]
  [[ "$(mirror_pattern)" == *'status'* ]]
}

@test "lint: search roots exist and hold artefacts — fails loudly, never vacuously" {
  # A renamed or adopter-relative path must fail here rather than let the scan
  # below pass by matching nothing. This is the shape that reddened main once.
  [ -d "$STORIES" ]
  [ -d "$MAPS" ]
  local n
  n="$(find "$STORIES" -name 'STORY-*.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
  [ "$n" -ge 1 ] || { echo "no STORY-*.md under $STORIES — lint would be vacuous"; false; }
  n="$(find "$MAPS" -name '*.html' -type f 2>/dev/null | wc -l | tr -d ' ')"
  [ "$n" -ge 1 ] || { echo "no maps under $MAPS — lint would be vacuous"; false; }
}

@test "lint: no story artefact mirrors an excluded frontmatter key in its body" {
  local hits
  hits="$(scan "$STORIES"/*/STORY-*.md)"
  [ -z "$hits" ] || {
    printf 'body mirror of an excluded key found — accepting these stories will drop their ratification:\n%s\n' "$hits"
    printf 'remove the line; run `wr-itil-migrate-story-status-mirror docs/stories` for an existing corpus.\n'
    false
  }
}

@test "lint: no story map mirrors an excluded frontmatter key in its body" {
  # The map's own `<meta name="status">` is the key's HOME in the HTML encoding,
  # not a mirror of it, and the lib's filter already excludes it — so the
  # line-anchored bold-key pattern correctly does not flag it.
  local hits
  hits="$(scan "$MAPS"/*/*.html)"
  [ -z "$hits" ] || {
    printf 'body mirror of an excluded key found in a map:\n%s\n' "$hits"
    false
  }
}

@test "lint: RED on an injected mirror — proves the pattern actually fires" {
  mkdir -p "$TMPD/stories/draft"
  printf -- '---\nstatus: accepted\n---\n\n# STORY-999: x\n\n**Status**: accepted\n**Reported**: 2026-07-30\n' \
    > "$TMPD/stories/draft/STORY-999-x.md"
  local hits; hits="$(scan "$TMPD/stories"/*/STORY-*.md)"
  [ -n "$hits" ] || { echo "lint failed to detect an injected line-start **Status**: mirror"; false; }
  [[ "$hits" == *"STORY-999"* ]]
}

@test "lint: prose ABOUT a mirror is not flagged — that is what line-anchoring buys" {
  mkdir -p "$TMPD/prose/draft"
  printf -- '---\nstatus: accepted\n---\n\n# STORY-998: y\n\nThe `**Status**:` line used to be hashed.\n<!-- No **Status**: body line, deliberately. -->\n' \
    > "$TMPD/prose/draft/STORY-998-y.md"
  [ -z "$(scan "$TMPD/prose"/*/STORY-*.md)" ]
}

# The behavioural half. Covers a mirror of ANY excluded key in ANY shape,
# including the HTML meta form the lint's pattern cannot reach.
@test "behavioural: a mirror of any excluded key drifts a ratified artefact" {
  local k
  for k in $(oversight_excluded_keys); do
    # Skip the marker keys themselves — those are excluded BY the marker write,
    # so a "mirror" of them is what the filter is for.
    case "$k" in human-oversight|oversight-hash|oversight-basis) continue ;; esac
    local f="$TMPD/mirror-$k.md"
    printf -- '---\n%s: draft\nhuman-oversight: confirmed\noversight-hash: P\n---\n\n# STORY-997\n\nbody\n' "$k" > "$f"
    local h; h="$(oversight_content_hash "$f")"
    sed -i.bak "s/oversight-hash: P/oversight-hash: $h/" "$f" && rm -f "$f.bak"
    run is_story_map_ratified "$f"
    [ "$status" -eq 0 ]
    # Add a body mirror of that key, then advance BOTH copies the way a
    # transition would. The frontmatter change alone is excluded; the body
    # mirror is not — so ratification must drop, which is P474 exactly.
    printf -- '**%s**: accepted\n' "$k" >> "$f"
    h="$(oversight_content_hash "$f")"
    sed -i.bak "s/^oversight-hash: .*/oversight-hash: $h/" "$f" && rm -f "$f.bak"
    sed -i.bak "s/^${k}: draft/${k}: accepted/; s/^\\*\\*${k}\\*\\*: accepted/**${k}**: DIFFERENT/" "$f" && rm -f "$f.bak"
    run is_story_map_ratified "$f"
    [ "$status" -ne 0 ] || { echo "a body mirror of '$k' did not drift the hash"; false; }
  done
}
