#!/usr/bin/env bash
# wr-itil — detect RFCs lacking the human-oversight marker (P378/RFC-030).
#
# Clone of the architect/jtbd detect-unoversighted shape (ADR-066/068): greps
# each RFC's YAML frontmatter for `human-oversight: confirmed`. No body reads,
# no per-RFC LLM call. An RFC is "unoversighted" when its frontmatter does not
# carry that marker line (RFCs are born `human-oversight: unconfirmed` at
# capture-rfc; they are ratified at the /wr-itil:manage-rfc accepted transition
# where scope is confirmed).
#
# Usage:
#   detect-unoversighted-rfcs.sh [RFCS_DIR]   (default docs/rfcs)
# Output: one unoversighted RFC file path per line, sorted. Empty = all
# confirmed. Always exits 0 (detector, not a gate).
#
# Consumed by: itil-rfc-oversight-nudge.sh (SessionStart count). Marker
# contract: ADR-066 (human-oversight marker), as extended to RFCs by ADR-070/071.

set -euo pipefail

RFCS_DIR="${1:-docs/rfcs}"

[ -d "$RFCS_DIR" ] || exit 0

shopt -s nullglob
for f in "$RFCS_DIR"/*.md "$RFCS_DIR"/*/*.md; do
  base="$(basename "$f")"
  [ "$base" = "README.md" ] && continue
  # Superseded + closed RFCs are retired/done — ratifying their scope is moot,
  # so they are not part of the "needs oversight" set (keeps the nudge focused
  # on live RFCs the user can still act on).
  case "$base" in *.superseded.md|*.closed.md) continue ;; esac

  fm="$(awk '
    NR==1 && $0 != "---" { exit }
    NR==1 { next }
    /^---[[:space:]]*$/ { exit }
    { print }
  ' "$f")"

  if printf '%s\n' "$fm" | grep -qiE '^human-oversight:[[:space:]]*confirmed[[:space:]]*$'; then
    continue
  fi

  echo "$f"
done | sort
