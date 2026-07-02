#!/usr/bin/env bash
# mark-story-oversight-confirmed.sh — ADR-090 ratify write-path.
#
# Writes `human-oversight: confirmed` + an `oversight-hash` fingerprint of the
# current content into a story (markdown frontmatter) or story-map (HTML meta).
# Idempotent: re-running recomputes the hash and replaces any existing marker
# (never duplicates). A later content edit changes the content hash, so the
# stored fingerprint no longer matches → the artefact reads as drifted /
# unratified until re-ratified (ADR-090 drift-invalidation).
#
# Usage: mark-story-oversight-confirmed.sh <story-or-map-file>
# Exit:  0 = ratified; 2 = usage / file error.
#
# Authority: ADR-090. Driver: P404 Phase 2. Test: mark-story-oversight-confirmed.bats.
set -euo pipefail

# Adopter-safe: source the shared hash lib RELATIVE TO THIS SCRIPT (P317), never
# repo-relative.
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "mark-story-oversight-confirmed: cannot locate lib dir" >&2; exit 2; }
# shellcheck source=/dev/null
source "$LIB/story-oversight.sh"

f="${1:-}"
if [ -z "$f" ]; then
  echo "mark-story-oversight-confirmed: usage: mark-story-oversight-confirmed.sh <file>" >&2
  exit 2
fi
[ -f "$f" ] || { echo "mark-story-oversight-confirmed: file not found: $f" >&2; exit 2; }

h="$(oversight_content_hash "$f")"
tmp="$(mktemp)"

case "$f" in
  *.html)
    if grep -qi '<head' "$f"; then
      # Insert the two metas after the <head> tag; drop any existing marker metas.
      awk -v H="$h" '
        /<meta[^>]*name="(human-oversight|oversight-hash)"/ { next }
        { print }
        !done && tolower($0) ~ /<head[ >]/ {
          print "  <meta name=\"human-oversight\" content=\"confirmed\">"
          print "  <meta name=\"oversight-hash\" content=\"" H "\">"
          done=1
        }
      ' "$f" > "$tmp"
    else
      # No <head> — prepend the metas (position is irrelevant to the hash).
      { printf '<meta name="human-oversight" content="confirmed">\n'
        printf '<meta name="oversight-hash" content="%s">\n' "$h"
        grep -vE '<meta[^>]*name="(human-oversight|oversight-hash)"' "$f"; } > "$tmp"
    fi
    ;;
  *)
    # Markdown: rewrite frontmatter — drop existing markers, insert both before
    # the closing `---`.
    awk -v H="$h" '
      NR==1 && $0=="---" { infm=1; print; next }
      infm && /^(human-oversight|oversight-hash):/ { next }
      infm && /^---[[:space:]]*$/ && !done {
        print "human-oversight: confirmed"
        print "oversight-hash: " H
        print; done=1; infm=0; next
      }
      { print }
    ' "$f" > "$tmp"
    ;;
esac

mv "$tmp" "$f"
echo "mark-story-oversight-confirmed: ratified $f (oversight-hash ${h:0:12}…)" >&2
exit 0
