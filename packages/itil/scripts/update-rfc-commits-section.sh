#!/usr/bin/env bash
# packages/itil/scripts/update-rfc-commits-section.sh
#
# Renders an RFC's `## Commits` section as a DERIVED VIEW from the git history
# (P378/RFC-030 Piece 1; ADR-085). The commit log is the source of truth; the
# section is a projection of `git log --grep "Refs: RFC-NNN"`. Because nothing
# is written per-commit, there is no post-commit working-tree edit and no
# ADR-014 grain problem — the section is regenerated skill-side (manage-rfc on
# every transition/review; reconcile-rfcs) exactly like docs/problems/README.md
# is a rendered index (ADR-031 precedent).
#
# Usage: update-rfc-commits-section.sh <rfc-file>
# Idempotent: rewriting a current section is a byte-stable no-op.
#
# @adr ADR-085 (RFC ## Commits is a git-log-derived view, rendered skill-side)
# @adr ADR-031 (rendered-index precedent) ADR-014 (why not a post-commit hook)
# @problem P378
# @rfc RFC-030

set -uo pipefail

RFC_FILE="${1:-}"
[ -n "$RFC_FILE" ] || { echo "ERROR: missing rfc-file argument" >&2; exit 1; }
[ -f "$RFC_FILE" ] || { echo "ERROR: rfc file not found: $RFC_FILE" >&2; exit 1; }

# RFC id from filename (RFC-NNN-...).
RFC_ID=$(basename "$RFC_FILE" | grep -oE 'RFC-[0-9]{3}' | head -1)
[ -n "$RFC_ID" ] || { echo "ERROR: cannot derive RFC id from $RFC_FILE" >&2; exit 1; }

# Render the commit list from git log (newest first). Fail-open to a sentinel
# line when not in a git tree (e.g. adopter tarball inspection).
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  RENDERED=$(git log --grep="Refs: ${RFC_ID}\b" --format='- `%h` %s — %ad' --date=short 2>/dev/null || true)
else
  RENDERED=""
fi
if [ -z "$RENDERED" ]; then
  RENDERED="(no commits yet — this section is rendered from \`git log --grep \"Refs: ${RFC_ID}\"\`)"
fi

# Rewrite the body of the `## Commits` section in place (everything between the
# `## Commits` heading and the next `## ` heading). awk preserves the rest. The
# rendered (multi-line) content is passed via a file — awk -v cannot carry
# embedded newlines.
TMP="$(mktemp)"
RENDERED_FILE="$(mktemp)"
printf '%s\n' "$RENDERED" > "$RENDERED_FILE"
awk -v rfile="$RENDERED_FILE" '
  BEGIN { in_sec = 0 }
  /^## Commits[[:space:]]*$/ {
    print
    print ""
    while ((getline line < rfile) > 0) print line
    close(rfile)
    print ""
    in_sec = 1
    next
  }
  in_sec && /^## / { in_sec = 0 }   # next section header ends the block
  in_sec { next }                    # drop old body lines
  { print }
' "$RFC_FILE" > "$TMP"
rm -f "$RENDERED_FILE"

# Idempotent: only replace on change.
if ! cmp -s "$TMP" "$RFC_FILE"; then
  cat "$TMP" > "$RFC_FILE"
fi
rm -f "$TMP"
