#!/usr/bin/env bash
# check-amends-backreference.sh — load-bearing detector for lockstep-amendment drift.
#
# An ADR that declares `amends: [ADR-NNN, ...]` is asserting that it changed those
# decisions' meaning. A reader who lands on the AMENDED ADR must be able to find
# that out from the amended ADR itself — otherwise the old text reads as current
# and the amendment is invisible from the only direction that matters.
#
# This checks the back-reference exists: for every `amends:` entry, the amended
# ADR's body must mention the amending ADR by ID. Cheap, mechanical, and it fires
# at the moment the drift is introduced rather than at a retro months later
# (ADR-051 load-bearing-from-the-start; the R002 sub-class with no detector).
#
# Usage: check-amends-backreference.sh [decisions-dir=docs/decisions]
# Exit:  0 = every declared amendment is back-referenced; 1 = >=1 missing
#        (offenders on stderr); 2 = usage / dir error.
#
# @adr ADR-051 (load-bearing from the start) ADR-031 (per-ADR body authoritative)
#      ADR-052 (behavioural bats) ADR-101 (the five-artefact lockstep that
#      surfaced the gap)
# @problem P456
set -uo pipefail

dir="${1:-docs/decisions}"
[ -d "$dir" ] || { echo "check-amends-backreference: not a directory: $dir" >&2; exit 2; }

missing=""
shopt -s nullglob
for f in "$dir"/[0-9]*.md; do
  self="ADR-$(basename "$f" | grep -oE '^[0-9]+')"
  # `amends:` is frontmatter-only; stop at the closing delimiter so a body
  # mention of the word cannot be mistaken for a declaration.
  amends_line="$(awk 'NR==1&&$0=="---"{fm=1;next} fm&&/^---[[:space:]]*$/{exit} fm&&/^amends:/{print;exit}' "$f")"
  [ -n "$amends_line" ] || continue
  for target in $(printf '%s' "$amends_line" | grep -oE 'ADR-[0-9]+'); do
    # nullglob array, not `ls` — an unmatched glob passes through to ls as a
    # literal and its diagnostics can land in the capture.
    shopt -s nullglob; hits=("$dir"/"${target#ADR-}"-*.md); shopt -u nullglob
    tf="${hits[0]:-}"
    if [ -z "$tf" ]; then
      missing="$missing\n  $self declares amends: $target, which does not resolve in $dir"
      continue
    fi
    grep -qF "$self" "$tf" || \
      missing="$missing\n  $(basename "$tf") is amended by $self but never mentions it — a reader of the amended decision cannot discover the amendment"
  done
done
shopt -u nullglob

if [ -n "$missing" ]; then
  # shellcheck disable=SC2059
  printf "check-amends-backreference: lockstep-amendment drift:$missing\n" >&2
  exit 1
fi
exit 0
