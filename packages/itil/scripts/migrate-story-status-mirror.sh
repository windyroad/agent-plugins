#!/usr/bin/env bash
# migrate-story-status-mirror.sh — P474 one-time migration.
#
# Removes the redundant `**Status**:` body line from story artefacts and carries
# each artefact's existing ratification forward.
#
# WHY the mirror is removed rather than normalised out of the oversight hash:
# the body line only repeats the frontmatter `status:` key that
# `oversight_content_hash` already excludes. Left in place, advancing a story
# from draft to accepted changed hashed content, so a story the maintainer had
# just ratified read as unratified and the no-implement gate denied its own
# implementing commit. Normalising the line out of the hash would have worked
# too, but it was the FOURTH such lifecycle mirror in a family of three and a
# fifth was already anticipated — one normaliser rule per mirror, forever.
# Maintainer direction 2026-07-29: kill the class, not the instance.
#
# RE-FINGERPRINT, NOT RE-RATIFY — the safety property this script rests on.
# `human-oversight: confirmed` asserts that a human confirmed something; this
# script NEVER writes it. `oversight-hash` asserts no event at all — it only
# identifies WHICH content the confirmation covered. Recomputing that pointer,
# over content whose sole delta is a mechanical mirror of an already-excluded
# field, removes zero ratified substance from coverage. That argument is what
# distinguishes this from the P348 hollow-marker class, and it holds ONLY
# because of two guards:
#
#   1. Per-artefact validity gate — re-fingerprint only when the stored hash
#      still matches the content as it stands. An artefact that had already
#      drifted stays drifted; nothing is silently revived. Without this the
#      migration is a blanket re-bless, which IS P348.
#   2. Mirror-agreement precondition — if the body line disagrees with the
#      frontmatter, it is carrying independent information (the real corpus had
#      `superseded (was: draft)` and `in-progress (2026-07-23)`), so deleting it
#      would lose content rather than de-duplicate it. Those are SKIPPED and
#      REPORTED for a human to resolve, never rewritten.
#
# Idempotent: an artefact with no body mirror is untouched, so re-running after
# the fix ships is a no-op. Reports every artefact it touches, so the
# re-fingerprint set is auditable from the commit that ran it.
#
# Usage: migrate-story-status-mirror.sh [<stories-dir>...]   (default: docs/stories)
# Exit:  0 = completed (including "nothing to do"); 2 = usage / missing lib.
#
# Authority: ADR-090 (oversight fingerprint), ADR-101 (oversight-basis).
# Driver: P474. Test: migrate-story-status-mirror.bats.

set -euo pipefail

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "migrate-story-status-mirror: cannot locate lib dir" >&2; exit 2; }
# shellcheck source=/dev/null
source "$LIB/story-oversight.sh"

dirs=("$@")
[ "${#dirs[@]}" -eq 0 ] && dirs=("docs/stories")

# Octal mode of a file, portably. Three traps here, all of them hit in practice:
#   1. `chmod --reference` is GNU-only, so BSD hosts silently fell through to a
#      hardcoded 644 while the call site claimed to preserve the mode.
#   2. The two `stat` flavours spell the mode differently — GNU `-c %a`, BSD
#      `-f %Lp` — and a mac with coreutils on PATH has the GNU one.
#   3. Crucially, the wrong flavour does not fail cleanly. GNU `stat -f` means
#      "filesystem information" and prints a multi-line block about the volume
#      with exit 0, so a plain `A || B` chain accepts that blob as a mode.
# Hence: validate the shape rather than trusting the exit status, and only then
# accept the answer. Falls back to 644, the correct mode for these files.
file_mode() {
  local m
  for m in "$(stat -c %a "$1" 2>/dev/null)" "$(stat -f %Lp "$1" 2>/dev/null)"; do
    case "$m" in
      [0-7][0-7][0-7] | [0-7][0-7][0-7][0-7]) printf '%s' "$m"; return 0 ;;
    esac
  done
  printf '644'
}

frontmatter_status() {
  awk '/^---$/{c++; next} c==1 && /^status:/{ sub(/^status:[[:space:]]*/, ""); gsub(/"/, ""); print; exit }' "$1"
}
body_status() {
  # `|| true` is load-bearing: no match makes grep exit 1, which under
  # `set -euo pipefail` would kill the script on the second (no-op) run and
  # silently destroy idempotence.
  grep -m1 -E '^\*\*Status\*\*:' "$1" 2>/dev/null | sed -E 's/^\*\*Status\*\*:[[:space:]]*//' || true
}

removed=0 refingerprinted=0 skipped=0 untouched=0

for d in "${dirs[@]}"; do
  [ -d "$d" ] || continue
  # Story artefacts live one level down in per-state subdirs.
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    body="$(body_status "$f")"
    if [ -z "$body" ]; then
      untouched=$((untouched + 1))
      continue
    fi
    fm="$(frontmatter_status "$f")"
    if [ "$fm" != "$body" ]; then
      printf 'SKIP  %s — body Status disagrees with frontmatter (body=%s frontmatter=%s); it carries information the frontmatter does not, so resolve by hand before removing\n' \
        "$f" "$body" "${fm:-<none>}" >&2
      skipped=$((skipped + 1))
      continue
    fi

    # Was this artefact ratified-and-valid BEFORE we touch it? Decide now: once
    # the line is gone the pre-migration hash is unreproducible.
    was_valid=0
    if is_story_map_ratified "$f"; then was_valid=1; fi

    # Drop the FIRST matching mirror line and nothing else — surrounding blank
    # lines are left exactly as they are. The template puts the mirror in a run
    # of adjacent `**Field**:` lines, so removing it leaves no double blank to
    # collapse; a later prose line that merely starts with the same token is not
    # reached, because `done` latches on the first match.
    tmp="$(mktemp)"
    awk '!(/^\*\*Status\*\*:/ && !done) { print; next } { done=1 }' "$f" > "$tmp"
    # Preserve the original mode — mktemp creates 0600, which would otherwise
    # strip the group/other read bit from every migrated story.
    chmod "$(file_mode "$f")" "$tmp"
    mv "$tmp" "$f"
    removed=$((removed + 1))

    if [ "$was_valid" -eq 1 ]; then
      # Re-point the fingerprint at the same ratified substance. Never touches
      # human-oversight, and never adds an oversight-basis it did not have.
      new_hash="$(oversight_content_hash "$f")"
      tmp="$(mktemp)"
      sed -E "s/^oversight-hash:[[:space:]]*[a-f0-9]{64}.*$/oversight-hash: ${new_hash}/" "$f" > "$tmp"
      chmod "$(file_mode "$f")" "$tmp"
      mv "$tmp" "$f"
      refingerprinted=$((refingerprinted + 1))
      printf 'MIGRATE %s — mirror removed, fingerprint re-pointed (ratification preserved)\n' "$f"
    else
      printf 'MIGRATE %s — mirror removed (was not ratified-and-valid; left unratified)\n' "$f"
    fi
    # STORY-*.md only. `README.md` documents the template and legitimately
    # contains a `**Status**: <status>` example; scanning it would report a
    # spurious disagreement and, worse, a laxer matcher would rewrite the doc.
  done < <(find "$d" -mindepth 1 -maxdepth 2 -name 'STORY-*.md' -type f 2>/dev/null | sort)
done

printf '\nmigrate-story-status-mirror: %d mirror(s) removed, %d re-fingerprinted, %d skipped (disagreement), %d already clean\n' \
  "$removed" "$refingerprinted" "$skipped" "$untouched"
exit 0
