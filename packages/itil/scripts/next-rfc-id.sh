#!/usr/bin/env bash
# packages/itil/scripts/next-rfc-id.sh
#
# THE single definition of "the next free RFC identity".
#
# A fix proposal draws a release row on a story map; it does not create a
# standalone RFC document. That leaves one identity space spread across two
# tiers, and the rule that used to allocate from the document directory alone
# cannot see the rows. It was already wrong before the tier changed: rows held
# identities above the highest document, so the next allocation collided with a
# row that already existed.
#
# So the scan is the union of every place an identity can be recorded:
#
#   1. RFC document filenames under the documents directory;
#   2. every `RFC-NNN` occurrence in the story-map corpus, which covers both a
#      row's authored identity in the data island and the derived list in the
#      map's <meta> block;
#   3. the same two, across the whole of git history — an identity can survive
#      on a branch, or in a commit whose file was later deleted, and be present
#      nowhere in the working tree. A live-tree-only scan re-issues it.
#
# Identities are never reused, so the answer is one past the highest seen — a
# gap below the maximum is a deleted identity, not a free slot.
#
# Every surface that needs an identity calls this. A second copy in a calling
# skill is the drift class this corpus has removed repeatedly, and it is the
# specific way the collision above went unnoticed: two rules, two answers, and
# the one nobody was reading was right.
#
# Usage:
#   next-rfc-id.sh [--rfcs-dir DIR] [--maps-dir DIR] [--no-git]
#
# Prints one `RFC-NNN` line, zero-padded to three digits. Defaults are
# `docs/rfcs` and `docs/story-maps`. `--no-git` restricts the scan to the
# working tree, for hermetic tests; outside a git repository the history half
# is skipped automatically.
#
# @adr ADR-119 (a fix proposal draws a release row, never a document; the
#   identity is allocated by scanning row identities including git history)
# @adr ADR-115 (identities are never reused — hence highest+1, not lowest gap)
# @adr ADR-049 (invoked via the wr-itil-next-rfc-id bin shim on $PATH)
# @adr ADR-052 (behavioural bats in packages/itil/scripts/test/next-rfc-id.bats)
# @problem P508

set -uo pipefail

RFCS_DIR="docs/rfcs"
MAPS_DIR="docs/story-maps"
USE_GIT=1

while [ $# -gt 0 ]; do
  case "$1" in
    --rfcs-dir) RFCS_DIR="${2:-}"; shift 2 ;;
    --maps-dir) MAPS_DIR="${2:-}"; shift 2 ;;
    --no-git)   USE_GIT=0; shift ;;
    *) echo "usage: next-rfc-id.sh [--rfcs-dir DIR] [--maps-dir DIR] [--no-git]" >&2; exit 2 ;;
  esac
done

# Every identity seen, one `RFC-NNN` token per line. Callers reduce; this only
# emits.
seen() {
  # 1. Document filenames.
  if [ -d "$RFCS_DIR" ]; then
    find "$RFCS_DIR" -maxdepth 1 -name 'RFC-[0-9][0-9][0-9]-*.md' 2>/dev/null
  fi

  # 2. The story-map corpus, at any nesting depth.
  if [ -d "$MAPS_DIR" ]; then
    grep -rhoE 'RFC-[0-9]{3}' "$MAPS_DIR" 2>/dev/null
  fi

  # 3. Git history. `git grep` takes revisions BEFORE the `--`; anything after
  # it is a pathspec, so piping revisions into xargs as trailing arguments
  # would silently re-grep the working tree and look like it worked — the
  # answer would even be plausible, because the working tree usually holds the
  # highest identity anyway. Hence the sh -c wrapper, which puts "$@" in the
  # revision slot.
  #
  # `git grep` exits 1 on a batch with no match, which xargs reports as 123;
  # both are absorbed so a quiet batch cannot empty the scan under pipefail.
  if [ "$USE_GIT" -eq 1 ] && git rev-parse --git-dir >/dev/null 2>&1; then
    git rev-list --all 2>/dev/null \
      | RFCS_DIR="$RFCS_DIR" MAPS_DIR="$MAPS_DIR" xargs -n 200 sh -c '
          git grep -hoE "RFC-[0-9]{3}" "$@" -- "$RFCS_DIR" "$MAPS_DIR" 2>/dev/null || true
        ' _ 2>/dev/null || true
  fi
}

HIGHEST="$(seen \
  | grep -oE 'RFC-[0-9]{3}' \
  | sed -E 's/^RFC-0*//' \
  | grep -E '^[0-9]+$' \
  | sort -n \
  | tail -1)"

printf 'RFC-%03d\n' "$(( ${HIGHEST:-0} + 1 ))"
