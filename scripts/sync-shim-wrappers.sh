#!/usr/bin/env bash
# ADR-080 + ADR-049 + ADR-017: regenerate every packages/*/bin/wr-* shim
# from the canonical template at packages/shared/lib/shim-wrapper-template.sh,
# substituting __SCRIPT_NAME__ with each shim's resolved script stem.
#
# Author edits packages/shared/lib/shim-wrapper-template.sh only; this script
# is the distribution mechanism that mirrors the ADR-017 sync-script siblings
# (sync-install-utils.sh, sync-derive-first-dispatch.sh, etc.).
#
# Usage:
#   bash scripts/sync-shim-wrappers.sh          # regenerate all shims
#   bash scripts/sync-shim-wrappers.sh --check  # exit non-zero if any shim drifts
#
# Script-stem resolution: each existing shim contains either
#   - Legacy 3-line ADR-049: `exec "$(dirname "$0")/../scripts/<NAME>.sh" "$@"`
#   - Post-ADR-080 wrapper: the source-repo-guard branch has the same
#     `exec "$SHIM_DIR/../scripts/__SCRIPT_NAME__.sh" "$@"` shape after
#     substitution, so the regex below matches both shapes.
#
# Unparseable shims (no `scripts/<NAME>.sh` exec line found) cause loud
# non-zero exit per architect review note + ADR-080 SQ-080-2 loud-failure
# principle. Files not matching the wr-<plugin>-* grammar (install.mjs,
# check-deps.sh) are SKIPPED silently — they are not ADR-049 shims.
#
# @adr ADR-080 (highest-version-wins shim wrapper plugin scaffold)
# @adr ADR-049 (plugin-bundled scripts resolve via bin/ on $PATH — amended)
# @adr ADR-017 (shared code duplicated into per-package — sync-script pattern)
# @problem P343 (mid-session staleness window)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_ROOT/packages/shared/lib/shim-wrapper-template.sh"

if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: canonical template not found at $TEMPLATE" >&2
  exit 1
fi

MODE="sync"
if [ "${1:-}" = "--check" ]; then
  MODE="check"
fi

# Enumerate wr-<plugin>-* shim files across all packages/*/bin/.
mapfile -t SHIMS < <(find "$REPO_ROOT/packages" -maxdepth 3 -type f -path '*/bin/wr-*' | sort)

if [ "${#SHIMS[@]}" -eq 0 ]; then
  echo "No packages/*/bin/wr-* shim files found." >&2
  exit 1
fi

DIVERGED=0
SYNCED=0
UNPARSEABLE=0

for shim in "${SHIMS[@]}"; do
  # Resolve the script stem from the shim body. Filter to `exec` lines
  # ONLY (skipping comment-line false matches) and match the first
  # `scripts/<NAME>.sh` reference. Covers both legacy 3-line shape
  # (`exec "$(dirname "$0")/../scripts/<NAME>.sh"`) and post-ADR-080
  # source-repo-guard branch (`exec "$SHIM_DIR/../scripts/<NAME>.sh"`).
  # `|| true` keeps an unparseable shim from killing the loop via pipefail —
  # the empty-stem branch below catches it explicitly with a loud error.
  stem=$(grep -E '^[[:space:]]*exec[[:space:]]' "$shim" \
    | grep -Eo 'scripts/[a-zA-Z0-9._-]+\.sh' \
    | head -1 \
    | sed -e 's|^scripts/||' -e 's|\.sh$||' || true)
  if [ -z "$stem" ]; then
    echo "ERROR: cannot resolve script stem from $shim — no scripts/<NAME>.sh exec found" >&2
    UNPARSEABLE=$((UNPARSEABLE + 1))
    continue
  fi

  # Materialise the expected shim content from the template + stem.
  expected=$(sed "s|__SCRIPT_NAME__|$stem|g" "$TEMPLATE")

  if [ "$(cat "$shim")" != "$expected" ]; then
    if [ "$MODE" = "check" ]; then
      echo "DIVERGED: ${shim#$REPO_ROOT/}"
      DIVERGED=$((DIVERGED + 1))
    else
      printf '%s\n' "$expected" > "$shim"
      chmod +x "$shim"
      echo "synced:   ${shim#$REPO_ROOT/}"
      SYNCED=$((SYNCED + 1))
    fi
  fi
done

if [ "$UNPARSEABLE" -gt 0 ]; then
  echo "" >&2
  echo "ERROR: $UNPARSEABLE shim(s) could not be parsed." >&2
  exit 1
fi

if [ "$MODE" = "check" ]; then
  if [ "$DIVERGED" -gt 0 ]; then
    echo "" >&2
    echo "ERROR: $DIVERGED shim(s) have diverged from the canonical template." >&2
    echo "Run: bash scripts/sync-shim-wrappers.sh" >&2
    exit 1
  fi
  echo "OK: all ${#SHIMS[@]} shims match packages/shared/lib/shim-wrapper-template.sh"
else
  if [ "$SYNCED" -eq 0 ]; then
    echo "OK: all ${#SHIMS[@]} shims already in sync"
  else
    echo ""
    echo "Synced $SYNCED shim(s). Review with: git diff packages/*/bin/wr-*"
  fi
fi
