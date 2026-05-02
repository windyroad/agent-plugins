#!/usr/bin/env bash
# packages/retrospective/scripts/list-plugin-attribution.sh
#
# Read-only diagnostic for per-plugin hooks/skills byte attribution
# consumed by the deep-layer skill `/wr-retrospective:analyze-context`
# (Step 2 — Decompose per-plugin attribution).
#
# Replaces the inline `for plugin_dir in packages/*/hooks; do ... done`
# loops that lived in SKILL.md before P153/ADR-049-reassessment.clause-3.
# Those loops worked in source-repo dev sessions but expanded to nothing
# in adopter sessions (no `packages/` dir under adopter project root),
# emitting zero PLUGIN-HOOKS / PLUGIN-SKILLS rows with no error signal.
#
# This helper resolves both modes:
#   1. Source-tree mode  — walk `<project-root>/packages/<plugin>/{hooks,skills}`.
#   2. Cache-fallback    — sniff `$PATH` for entries shaped like
#                          `*/cache/<owner>/<plugin>/<version>/bin`
#                          and back-walk to each plugin's root.
#   3. Neither resolves  — emit `PLUGIN-ATTRIBUTION not-measured
#                          reason=no-plugin-source-resolvable` per ADR-026.
#
# Usage:
#   list-plugin-attribution.sh [<project-root>]
#
# Default <project-root> is the current working directory.
#
# Output (one row per plugin, terse machine-readable per ADR-038 ≤150 bytes):
#   PLUGIN-HOOKS  <plugin> bytes=<N>
#   PLUGIN-SKILLS <plugin> bytes=<N>
#   PLUGIN-ATTRIBUTION not-measured reason=<reason>
#
# Sorted by row-type then plugin name for stable diffs.
#
# Exit code: 0 always (advisory only — matches measure-context-budget.sh
# contract; missing data is signal, not failure).
#
# @problem P153
# @adr ADR-049 (Plugin-bundled scripts via `bin/` on `$PATH` —
#   reassessment-criteria clause 3 explicitly anticipates this surface)
# @adr ADR-038 (Progressive disclosure — per-row byte budget)
# @adr ADR-026 (Agent output grounding — explicit not-measured sentinels
#   when neither resolution mode resolves)
# @jtbd JTBD-301 (Plugin-user) / JTBD-101 (Plugin-developer)

set -uo pipefail

PROJECT_ROOT="${1:-$(pwd)}"

sum_dir_bytes() {
  local dir="$1"
  local pattern="$2"
  if [ ! -d "$dir" ] || [ ! -r "$dir" ]; then
    echo 0
    return
  fi
  local total=0 b
  while IFS= read -r -d '' f; do
    b=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
    total=$(( total + ${b:-0} ))
  done < <(find "$dir" -type f -name "$pattern" -print0 2>/dev/null)
  echo "$total"
}

declare -a ROWS=()

emit_plugin_row() {
  local row_type="$1"
  local plugin="$2"
  local bytes="$3"
  ROWS+=( "$row_type $plugin bytes=$bytes" )
}

source_resolved=0

if [ -d "$PROJECT_ROOT/packages" ]; then
  shopt -s nullglob
  hook_dirs=( "$PROJECT_ROOT"/packages/*/hooks )
  skill_dirs=( "$PROJECT_ROOT"/packages/*/skills )
  shopt -u nullglob

  for d in ${hook_dirs[@]+"${hook_dirs[@]}"}; do
    plugin=$(basename "$(dirname "$d")")
    bytes=$(sum_dir_bytes "$d" '*.sh')
    emit_plugin_row PLUGIN-HOOKS "$plugin" "$bytes"
    source_resolved=1
  done

  for d in ${skill_dirs[@]+"${skill_dirs[@]}"}; do
    plugin=$(basename "$(dirname "$d")")
    bytes=$(sum_dir_bytes "$d" 'SKILL.md')
    emit_plugin_row PLUGIN-SKILLS "$plugin" "$bytes"
    source_resolved=1
  done
fi

cache_resolved=0

if [ "$source_resolved" -eq 0 ] && [ -n "${PATH:-}" ]; then
  # bash 3.2 on macOS lacks `declare -A` — track seen plugins in a
  # delimiter-bounded string. Membership probe: case "$SEEN_PLUGINS" in
  # *"|$plugin|"*) ;; esac.
  SEEN_PLUGINS="|"
  IFS=':' read -r -a path_entries <<< "$PATH"

  for entry in ${path_entries[@]+"${path_entries[@]}"}; do
    [ -z "$entry" ] && continue
    entry="${entry%/}"
    [[ "$entry" == */bin ]] || continue
    [[ "$entry" == */cache/* ]] || continue

    plugin_root="${entry%/bin}"
    plugin=$(basename "$(dirname "$plugin_root")")
    [ -z "$plugin" ] && continue
    case "$SEEN_PLUGINS" in *"|$plugin|"*) continue ;; esac
    SEEN_PLUGINS="${SEEN_PLUGINS}${plugin}|"

    hooks_dir="$plugin_root/hooks"
    skills_dir="$plugin_root/skills"

    if [ -d "$hooks_dir" ]; then
      bytes=$(sum_dir_bytes "$hooks_dir" '*.sh')
      emit_plugin_row PLUGIN-HOOKS "$plugin" "$bytes"
      cache_resolved=1
    fi
    if [ -d "$skills_dir" ]; then
      bytes=$(sum_dir_bytes "$skills_dir" 'SKILL.md')
      emit_plugin_row PLUGIN-SKILLS "$plugin" "$bytes"
      cache_resolved=1
    fi
  done
fi

if [ "$source_resolved" -eq 1 ] || [ "$cache_resolved" -eq 1 ]; then
  printf '%s\n' ${ROWS[@]+"${ROWS[@]}"} | LC_ALL=C sort
else
  echo "PLUGIN-ATTRIBUTION not-measured reason=no-plugin-source-resolvable"
fi

exit 0
