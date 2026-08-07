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
# ADR-103 retired the ADR-101 `--pure-decomposition` flag and its
# `oversight-basis:` record. Nothing here strips a stale one: the only writer
# that did was the markdown leg, and markdown is a story, which is now refused
# outright. No artefact in the corpus carries the field.
#
# Usage: mark-story-oversight-confirmed.sh <story-or-map-file>
# Exit:  0 = ratified; 2 = usage / file error.
#
# Authority: ADR-090, ADR-103. Driver: P404 Phase 2, P456. Test: mark-story-oversight-confirmed.bats.
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

# ADR-103: only a story MAP is ratified. A story carries no oversight marker at
# all — its approval is its map's. Marking a story would re-create the second
# approval surface ADR-103 removed, so refuse rather than silently write one.
# What ADR-103 removes is the STORY-tier marker, and a story is markdown. So the
# refusal is keyed on the encoding, not on a `docs/stories/` path substring: a
# caller working outside that tree — a test fixture, an adopter with a different
# layout — must get the same answer.
#
# Deliberately NOT keyed on the ADR-102 data island, tempting as that is. A map
# predating ADR-102 has no island, and an island test would lock those out of
# ratification entirely. Marking some unrelated .html file is a user error; a
# story marker is a governance hole, and only the second one is worth refusing.
case "$f" in
  *.md|*.markdown)
    echo "mark-story-oversight-confirmed: refusing to mark $f (ADR-103). Only a story MAP is ratified. A story carries no oversight marker; its approval is derived from the maps named in its \`story-maps:\` field, so ratify the map instead." >&2
    exit 2 ;;
esac

h="$(oversight_content_hash "$f")"
tmp="$(mktemp)"

case "$f" in
  *.html)
    if grep -qF '<script id="story-map-data"' "$f"; then
      # ADR-102 map: the data island is the source of truth and every <meta> is
      # GENERATED from it. Writing the marker to <meta> alone would be undone by
      # the next render, silently destroying a human ratification — so the
      # marker goes into the island and the <meta> follows on render.
      #
      # TWO passes, and the order matters. Normalising the island can move a
      # trailing comma onto a line the marker filter does NOT exclude (removing
      # a previously-appended key un-commas the key before it), which would
      # change the very bytes being fingerprinted. So: normalise first, hash the
      # normalised form, then write the hash — a marker-line-only edit, which
      # the filter excludes, so the stored value stays valid.
      _island_normalise() {
        python3 - "$1" "$2" <<'PYMARK'
import json, pathlib, sys
path, digest = pathlib.Path(sys.argv[1]), sys.argv[2]
OPEN = '<script id="story-map-data" type="application/json">'
html = path.read_text()
start = html.index(OPEN) + len(OPEN)
end = html.index('</script>', start)
data = json.loads(html[start:end].replace('\\u003c', '<'))
# Marker keys FIRST, never appended: appending gives the previously-last key a
# trailing comma, a punctuation-only change on an unfiltered line.
MARKERS = ('humanOversight', 'oversightHash', 'oversightDate', 'oversightNote')
ordered = {'humanOversight': 'confirmed', 'oversightHash': digest}
for k in ('oversightDate', 'oversightNote'):
    if k in data:
        ordered[k] = data[k]
ordered.update({k: v for k, v in data.items() if k not in MARKERS})
island = json.dumps(ordered, indent=2, ensure_ascii=False).replace('<', '\\u003c')
path.write_text(html[:start] + "\n" + island + "\n  " + html[end:])
PYMARK
      }
      _island_normalise "$f" "pending"
      h="$(oversight_content_hash "$f")"
      _island_normalise "$f" "$h"
      # Re-render so the generated <meta> block matches the island. Prefer the
      # sibling script over $PATH: this runs from the same package, so the
      # renderer is always beside it even when the bin shim is not on PATH.
      _renderer="$(cd "$(dirname "$0")" && pwd)/render-story-map.sh"
      if [ -x "$_renderer" ]; then
        "$_renderer" "$f" >/dev/null 2>&1 || true
      elif command -v wr-itil-render-story-map >/dev/null 2>&1; then
        wr-itil-render-story-map "$f" >/dev/null 2>&1 || true
      fi
      printf 'mark-story-oversight-confirmed: ratified %s (oversight-hash %s…)\n' "$f" "${h:0:12}" >&2
      rm -f "$tmp"
      exit 0
    elif grep -qi '<head' "$f"; then
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
    # The markdown-frontmatter writer that used to live here was a working
    # writer for the story-level marker ADR-103 removed. It is deleted rather
    # than left unreachable behind the guard above, so that a later relaxation
    # of that guard fails loudly instead of silently restoring story markers.
    echo "mark-story-oversight-confirmed: refusing to mark $f (ADR-103) — no recognised story-map encoding (expected a <script id=\"story-map-data\"> island, or a legacy HTML map)." >&2
    rm -f "$tmp"; exit 2
    ;;
esac

mv "$tmp" "$f"
echo "mark-story-oversight-confirmed: ratified $f (oversight-hash ${h:0:12}…)" >&2
exit 0
