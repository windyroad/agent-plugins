#!/usr/bin/env bash
# Guard: every directly-invoked plugin entrypoint MUST be tracked executable (git mode 100755).
#
# Claude Code and the shim wrappers exec these paths directly (not via `sh <path>`),
# so a 100644 file is refused with "Permission denied" and the hook/skill/bin is inert.
# npm-tarball extraction preserves the git mode bit, so a 644 entrypoint ships broken to
# every adopter. This guard fails CI before that can happen. (P447 / R074.)
#
# Scope = entrypoints only: hooks/*.sh, scripts/*.sh, bin/* — EXCLUDING */lib/* files,
# which are `source`d (read-only) and correctly ship 100644.
#
# ponytail: pure `git ls-files -s` mode check, no external deps.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

violations=$(git ls-files -s \
    'packages/*/hooks/*.sh' \
    'packages/*/scripts/*.sh' \
    'packages/*/bin/*' \
    'packages/shared/*.sh' \
  | awk '$4 !~ /\/lib\// && $1 != "100755" { print $1 "  " $4 }')

if [ -n "$violations" ]; then
  echo "ERROR: plugin entrypoint(s) are not tracked executable (git mode 100755):" >&2
  echo "$violations" >&2
  echo >&2
  echo "Fix: chmod +x <file> && git update-index --chmod=+x <file>" >&2
  echo "(A non-executable hook/bin is refused by /bin/sh at adopter installs — P447.)" >&2
  exit 1
fi

echo "check:executable-modes — all plugin entrypoints are tracked 100755"
