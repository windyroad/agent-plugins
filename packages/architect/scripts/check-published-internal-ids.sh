#!/usr/bin/env bash
set -euo pipefail

PACKAGE_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

npm pack "$PACKAGE_ROOT" --pack-destination "$TMP" >/dev/null
tar -xzf "$TMP"/*.tgz -C "$TMP"

LEAKS="$TMP/leaks"
: > "$LEAKS"

while IFS= read -r -d '' file; do
  case "$file" in
    *.md|*.json|*.yaml|*.yml)
      perl -ne 'next if /^\s*(?:#\s*)?\@(?:adr|problem|rfc|jtbd|story|risk)\b/i; while (/\b(ADR-\d{3,}|P-?\d{3}|RFC-\d{3,}|JTBD-\d{3,}|STORY(?:-MAP)?-\d{3,}|R-?\d{3})\b/g) { print "$ARGV:$.:$1\n" }' "$file" >> "$LEAKS"
      ;;
    *)
      perl -ne 'next if /^\s*(?:#|\/\/|\/\*|\*)/; while (/\b(ADR-\d{3,}|P-?\d{3}|RFC-\d{3,}|JTBD-\d{3,}|STORY(?:-MAP)?-\d{3,}|R-?\d{3})\b/g) { print "$ARGV:$.:$1\n" }' "$file" >> "$LEAKS"
      ;;
  esac
done < <(find "$TMP/package" -type f -print0)

if [[ -s "$LEAKS" ]]; then
  sed "s#${TMP}/package/##" "$LEAKS" >&2
  echo "check-published-internal-ids: packed artefacts contain source-repository identifiers" >&2
  exit 1
fi
