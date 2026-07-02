#!/usr/bin/env bash
# check-rfc-has-stories.sh — ADR-089 (every RFC has at least one story).
#
# The load-bearing detection half of the manage-rfc `proposed -> accepted` gate:
# an RFC must list >=1 story before it can be accepted. Exits non-zero (with a
# stderr directive) when the RFC's `stories:` frontmatter is empty (`stories: []`)
# or missing; exits 0 when >=1 `STORY-NNN` is listed (inline or block-list).
#
# This removes the pre-ADR-089 empty-stories fallback (the "atomic RFC ships with
# stories: [] / JTBD-101 friction guard" shape). An atomic fix is now an RFC with
# exactly one full story, never an empty list.
#
# Usage: check-rfc-has-stories.sh <rfc-file>
# Exit:  0 = >=1 story; 1 = empty/missing stories; 2 = usage / file error.
#
# Authority: ADR-089. Driver: P404. Behavioural test: check-rfc-has-stories.bats.
set -euo pipefail

rfc="${1:-}"
if [ -z "$rfc" ]; then
  echo "check-rfc-has-stories: usage: check-rfc-has-stories.sh <rfc-file>" >&2
  exit 2
fi
if [ ! -f "$rfc" ]; then
  echo "check-rfc-has-stories: file not found: $rfc" >&2
  exit 2
fi

# The frontmatter `stories:` line (first match; frontmatter is at the top).
stories_line="$(awk '/^stories:/{print; exit}' "$rfc")"

if [ -z "$stories_line" ]; then
  echo "check-rfc-has-stories: $rfc has no 'stories:' field — an RFC must list >=1 story (ADR-089). Decompose the fix into >=1 story before accepting." >&2
  exit 1
fi

# Reject an explicit empty inline list: `stories: []`.
if printf '%s' "$stories_line" | grep -qE '^stories:[[:space:]]*\[[[:space:]]*\][[:space:]]*$'; then
  echo "check-rfc-has-stories: $rfc has empty 'stories: []' — an RFC must list >=1 story (ADR-089; the empty-stories fallback is removed). An atomic fix is an RFC with exactly one full story." >&2
  exit 1
fi

# Accept if a STORY-id appears inline on the stories: line.
if printf '%s' "$stories_line" | grep -qE 'STORY-[0-9]'; then
  exit 0
fi

# Accept if a YAML block-list under stories: carries >=1 STORY-id.
if awk '
  /^stories:/ { inblock=1; next }
  inblock && /^[[:space:]]*-[[:space:]]*STORY-[0-9]/ { found=1 }
  inblock && /^[^[:space:]-]/ { exit }
  END { exit !found }
' "$rfc"; then
  exit 0
fi

echo "check-rfc-has-stories: $rfc 'stories:' lists no STORY- ids — an RFC must list >=1 story (ADR-089)." >&2
exit 1
