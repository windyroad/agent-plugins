#!/usr/bin/env bats

# @problem P508 — a fix proposal draws a release row, never a document, so an
# RFC identity must be allocated against BOTH tiers. The previous rule —
# highest-wins over the RFC document directory — could not see release rows,
# and rows already held identities above the document maximum, so the next
# allocation collided with a row that already existed.
#
# ONE definition of "the next free identity", called by every surface that
# needs one. A second copy in a calling skill is the drift class this corpus
# has removed repeatedly.
#
# Behavioural per ADR-052: assert on the allocator's stdout given fixture
# corpora, never on its source text.
#
# Contract:
#   - Scans RFC identities in the document dir, in the story-map corpus, and
#     in git history (an identity can survive only in history), returning the
#     first identity none of them holds.
#   - Identities are never reused, so the answer is one past the highest seen,
#     not the lowest gap.
#   - Output is a single `RFC-NNN` line, zero-padded to three digits.
#
# @adr ADR-119 (identity allocated by scanning row identities incl. history)
# @adr ADR-115 (identities are never reused)
# @adr ADR-052 (behavioural bats default)

setup() {
  SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/next-rfc-id.sh"
  WORK="$(mktemp -d)"
  RFCS="$WORK/docs/rfcs"
  MAPS="$WORK/docs/story-maps"
  mkdir -p "$RFCS" "$MAPS"
}

teardown() {
  rm -rf "$WORK"
}

run_alloc() {
  run "$SCRIPT" --rfcs-dir "$RFCS" --maps-dir "$MAPS" --no-git
}

write_doc() {
  : > "$RFCS/RFC-$1-some-slug.proposed.md"
}

# A map carrying one release row with an RFC identity, in the authored data
# island shape the renderer reads.
write_map() {
  local id="$1" rfc="$2"
  cat > "$MAPS/STORY-MAP-$id-fixture.html" <<EOF
<!DOCTYPE html><html><head>
<meta name="story-map-id" content="STORY-MAP-$id">
<script id="story-map-data" type="application/json">
{"storyMapId":"STORY-MAP-$id","releases":[{"id":"row","name":"n","rfc":"$rfc"}],"tasks":[]}
</script>
</head><body></body></html>
EOF
}

@test "empty corpus allocates the first identity" {
  run_alloc
  [ "$status" -eq 0 ]
  [ "$output" = "RFC-001" ]
}

@test "documents alone: one past the highest document" {
  write_doc 005
  write_doc 059
  run_alloc
  [ "$status" -eq 0 ]
  [ "$output" = "RFC-060" ]
}

@test "a release row above the highest document wins — the collision this fixes" {
  write_doc 059
  write_map 011 RFC-069
  run_alloc
  [ "$status" -eq 0 ]
  [ "$output" = "RFC-070" ]
}

@test "identities are never reused: a gap below the maximum is not offered" {
  write_doc 001
  write_doc 009
  run_alloc
  [ "$status" -eq 0 ]
  [ "$output" = "RFC-010" ]
}

@test "a row-only corpus with no document directory still answers" {
  rm -rf "$RFCS"
  write_map 002 RFC-042
  run_alloc
  [ "$status" -eq 0 ]
  [ "$output" = "RFC-043" ]
}

@test "output is zero-padded to three digits" {
  write_doc 007
  run_alloc
  [ "$output" = "RFC-008" ]
}

@test "an identity that exists at NO ref tip is still not re-issued" {
  # The never-reuse rule made adversarial. The map is committed and then
  # deleted on the SAME branch, so the identity survives only in an ancestor
  # commit — it is in no working tree and at no ref tip. A scan of ref tips
  # (or, worse, one whose revision arguments were silently eaten as pathspecs
  # and which therefore re-greps the working tree) re-issues it.
  cd "$WORK"
  git init -q .
  git config user.email t@e.st
  git config user.name t
  git config commit.gpgsign false
  write_map 003 RFC-088
  git add -A
  git commit -qm "seed the map"
  git rm -q "$MAPS/STORY-MAP-003-fixture.html"
  git commit -qm "delete the map"

  [ ! -f "$MAPS/STORY-MAP-003-fixture.html" ]
  run "$SCRIPT" --rfcs-dir "$RFCS" --maps-dir "$MAPS"
  [ "$status" -eq 0 ]
  [ "$output" = "RFC-089" ]
}

@test "--no-git ignores history, so the deleted identity IS re-offered" {
  # The control for the case above: same corpus, history half switched off.
  # If this returned RFC-089 too, the previous test would prove nothing about
  # the history scan.
  cd "$WORK"
  git init -q .
  git config user.email t@e.st
  git config user.name t
  git config commit.gpgsign false
  write_map 003 RFC-088
  git add -A
  git commit -qm "seed the map"
  git rm -q "$MAPS/STORY-MAP-003-fixture.html"
  git commit -qm "delete the map"

  run "$SCRIPT" --rfcs-dir "$RFCS" --maps-dir "$MAPS" --no-git
  [ "$status" -eq 0 ]
  [ "$output" = "RFC-001" ]
}

@test "outside a git repository the scan degrades to the working tree" {
  # cd matters: run from the repo root, the history half would scan THIS
  # repository and answer from its corpus rather than the fixture's.
  cd "$WORK"
  write_doc 012
  run "$SCRIPT" --rfcs-dir "$RFCS" --maps-dir "$MAPS"
  [ "$status" -eq 0 ]
  [ "$output" = "RFC-013" ]
}
