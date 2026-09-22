#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_md="${script_dir}/../SKILL.md"
if [[ "${1:-}" =~ /wr-itil:(close-incident|link-incident|mitigate-incident|restore-incident|manage-problem) ]]; then
  skill_md="${script_dir}/../../${BASH_REMATCH[1]}/SKILL.md"
fi

skill_text="$(cat "$skill_md")"
cd "${TMPDIR:-/tmp}"
exec claude -p --tools "" --append-system-prompt "$skill_text" "${1:-}"
