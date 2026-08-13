#!/usr/bin/env bats
# Behavioural test for check-rfc-stories-ratified.sh (ADR-090 — an RFC may
# reference only RATIFIED stories). DRIFT-AWARE via the shared lazy-fingerprint
# lib: a listed story counts only when it is `confirmed` AND its stored
# oversight-hash matches current content. Composes with check-rfc-has-stories
# (ADR-089): has-stories checks >=1 exists; this checks each listed one is ratified.
#
# @adr ADR-090
# @problem P404 (implement ADR-089 + ADR-090) — Phase 2

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/check-rfc-stories-ratified.sh"
  MARK="${REPO_ROOT}/packages/itil/scripts/mark-story-oversight-confirmed.sh"
  TMPD="$(mktemp -d)"
  mkdir -p "$TMPD/stories/accepted" "$TMPD/story-maps/draft"
}
teardown() { rm -rf "$TMPD"; }

# ADR-103: a story is approved by its MAP, so `confirmed` here means "sits on a
# ratified map". The map is marked through the real write-path, never a
# hand-rolled fixture — the hash has one definition.
mkmap() { # $1=map-id $2=ratified|unratified
  local f="$TMPD/story-maps/draft/$1-x.html"
  printf '<!DOCTYPE html>\n<body>\n<script id="story-map-data" type="application/json">\n{ "storyMapId": "%s", "backbone": [] }\n</script>\n</body>\n</html>\n' "$1" > "$f"
  [ "$2" = ratified ] && bash "$MARK" "$f" >/dev/null 2>&1
  return 0
}

mkstory() { # $1=id $2=confirmed|unconfirmed|none
  local f="$TMPD/stories/accepted/$1-x.md"
  case "$2" in
    confirmed)
      mkmap STORY-MAP-940 ratified
      printf -- '---\nstatus: accepted\nstory-maps: [STORY-MAP-940]\n---\n# %s\n' "$1" > "$f" ;;
    unconfirmed)
      mkmap STORY-MAP-941 unratified
      printf -- '---\nstatus: accepted\nstory-maps: [STORY-MAP-941]\n---\n# %s\n' "$1" > "$f" ;;
    none)
      printf -- '---\nstatus: accepted\n---\n# %s\n' "$1" > "$f" ;;
  esac
}
mkrfc() { printf -- '---\nstatus: proposed\nstories: [%s]\n---\n# rfc\n' "$1" > "$TMPD/RFC.proposed.md"; }

@test "check-rfc-stories-ratified: empty stories: [] passes vacuously (exit 0)" {
  printf -- '---\nstatus: proposed\nstories: []\n---\n# rfc\n' > "$TMPD/RFC.proposed.md"
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -eq 0 ]
}

@test "check-rfc-stories-ratified: a ratified (confirmed+hash) story is ACCEPTED (exit 0)" {
  mkstory STORY-020 confirmed
  mkrfc STORY-020
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -eq 0 ]
}

@test "check-rfc-stories-ratified: an unconfirmed story is REJECTED" {
  mkstory STORY-020 unconfirmed
  mkrfc STORY-020
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-020"* ]]
}

@test "check-rfc-stories-ratified: a story with NO oversight marker is REJECTED" {
  mkstory STORY-020 none
  mkrfc STORY-020
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-020"* ]]
}

@test "check-rfc-stories-ratified: a story whose MAP has DRIFTED is REJECTED" {
  mkstory STORY-020 confirmed
  # A new activity column is substance: it re-opens the map's approval, and the
  # story goes unapproved with it.
  python3 -c 'import sys,pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
p.write_text(t.replace("\"backbone\": []", "\"backbone\": [{\"id\": \"z\", \"title\": \"Z\"}]"))' \
    "$TMPD/story-maps/draft/STORY-MAP-940-x.html"
  mkrfc STORY-020
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-020"* ]]
}

@test "check-rfc-stories-ratified: editing the STORY does not un-approve it (ADR-103)" {
  # Stories are outside the fingerprint entirely — only the map decides.
  mkstory STORY-020 confirmed
  printf '\nA substance edit to the story body.\n' >> "$TMPD/stories/accepted/STORY-020-x.md"
  mkrfc STORY-020
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -eq 0 ]
}

@test "check-rfc-stories-ratified: a missing story file is REJECTED" {
  mkrfc STORY-099
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-099"* ]]
}

@test "check-rfc-stories-ratified: mixed — one ratified one unconfirmed is REJECTED" {
  mkstory STORY-020 confirmed
  mkstory STORY-021 unconfirmed
  mkrfc "STORY-020, STORY-021"
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-021"* ]]
}
