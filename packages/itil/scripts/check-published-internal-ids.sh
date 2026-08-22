#!/usr/bin/env bash
set -euo pipefail

PACKAGE_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"; node "$PACKAGE_ROOT/scripts/sync-codex-skills.mjs" --restore-pack >/dev/null 2>&1 || true' EXIT

npm pack "$PACKAGE_ROOT" --pack-destination "$TMP" >/dev/null
tar -xzf "$TMP"/*.tgz -C "$TMP"

if rg -n '\b(ADR-[0-9]{3,}|P-?[0-9]{3}|RFC-[0-9]{3,}|JTBD-[0-9]{3,}|STORY(-MAP)?-[0-9]{3,}|R-?[0-9]{3})\b' "$TMP/package" \
  --glob '!package.json' --glob '!*.map' >"$TMP/leaks"; then
  sed "s#${TMP}/package/##" "$TMP/leaks" >&2
  echo "check-published-internal-ids: packed ITIL artefacts contain source-repository identifiers" >&2
  exit 1
fi
