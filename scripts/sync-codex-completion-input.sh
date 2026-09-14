#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_file="$repo_root/packages/shared/hooks/lib/codex-completion-input.mjs"
targets=(architect jtbd risk-scorer style-guide voice-tone)
check=false
[ "${1:-}" = "--check" ] && check=true

diverged=0
for package in "${targets[@]}"; do
  target="$repo_root/packages/$package/hooks/lib/codex-completion-input.mjs"
  if $check; then
    if ! cmp -s "$source_file" "$target"; then
      echo "ERROR: $target differs from canonical codex-completion-input.mjs" >&2
      diverged=$((diverged + 1))
    fi
  else
    mkdir -p "$(dirname "$target")"
    cp "$source_file" "$target"
  fi
done

if $check; then
  [ "$diverged" -eq 0 ]
  echo "OK: all ${#targets[@]} Codex completion input copies match the canonical helper"
fi
