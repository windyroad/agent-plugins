#!/usr/bin/env bash
# Fails when a package's published tarball carries a source-repository identifier
# (decision, problem, RFC, story, job or risk numbers). Adopters never receive the
# corpora those numbers index, so a published rule must state its substance inline.
#
# Usage: check-published-internal-ids.sh [package-dir ...]
# With no arguments, scans every workspace package under packages/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Packages whose published artefacts still carry identifiers. Their drift is
# reported as a count rather than blocked, until their migration slice lands.
PENDING=" ${WR_PUBLISHED_IDS_PENDING-connect itil jtbd retrospective risk-scorer tdd voice-tone} "

ID_RE='\b(ADR-\d{3,}|P-?\d{3}|RFC-\d{3,}|JTBD-\d{3,}|STORY(?:-MAP)?-\d{3,}|R-?\d{3})\b'

CURRENT_DIR=""
restore_current() {
  # npm runs postpack itself on the normal path; this covers an aborted pack
  # leaving a prepack-transformed tree behind.
  [ -n "$CURRENT_DIR" ] || return 0
  (cd "$CURRENT_DIR" && npm run --if-present postpack) >/dev/null 2>&1 || true
}
trap restore_current EXIT

# scan <package-dir> -> one "<path>:<line>:<id>" per hit, paths relative to the tarball root
scan() {
  local dir="$1" work
  work="$(mktemp -d)"
  npm pack "$dir" --pack-destination "$work" --loglevel=error >/dev/null
  tar -xzf "$work"/*.tgz -C "$work"
  while IFS= read -r -d '' file; do
    case "$file" in
      # Structured source annotations are maintainer provenance, not adopter prose.
      *.md|*.json|*.yaml|*.yml)
        perl -ne 'next if /^\s*(?:#\s*)?\@(?:adr|problem|rfc|jtbd|story|risk)\b/i; while (/'"$ID_RE"'/g) { print "$ARGV:$.:$1\n" }' "$file"
        ;;
      *)
        perl -ne 'next if /^\s*(?:#|\/\/|\/\*|\*)/; while (/'"$ID_RE"'/g) { print "$ARGV:$.:$1\n" }' "$file"
        ;;
    esac
  done < <(find "$work/package" -type f -print0) | sed "s#${work}/package/##"
  rm -rf "$work"
}

targets=("$@")
if [ ${#targets[@]} -eq 0 ]; then
  for dir in "$REPO_ROOT"/packages/*/; do
    [ -f "${dir}package.json" ] && targets+=("${dir%/}")
  done
fi

failed=0
for dir in "${targets[@]}"; do
  name="$(basename "$dir")"
  CURRENT_DIR="$dir"
  hits="$(scan "$(cd "$dir" && pwd)")"
  CURRENT_DIR=""
  count="$(printf '%s' "$hits" | grep -c . || true)"
  [ "$count" -eq 0 ] && continue
  if [[ "$PENDING" == *" $name "* ]]; then
    echo "PENDING $name drift=$count"
    continue
  fi
  printf '%s\n' "$hits" | sed "s#^#$name/#" >&2
  failed=1
done

if [ "$failed" -eq 1 ]; then
  echo "check-published-internal-ids: packed artefacts contain source-repository identifiers" >&2
  exit 1
fi
