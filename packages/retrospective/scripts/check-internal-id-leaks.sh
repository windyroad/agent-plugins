#!/usr/bin/env bash
# packages/retrospective/scripts/check-internal-id-leaks.sh
#
# Diagnose-only advisory script for plugin-published internal-ID leaks per
# ADR-055 (Plugin-published artefacts use namespace-prefixed permalinks).
#
# Walks shipped-artefact surfaces under `<root-dir>/packages/<plugin>/`:
#   - skills/<skill>/SKILL.md
#   - agents/*.md
#   - hooks/*.sh
#   - CHANGELOG.md
#
# Reports each artefact carrying bare internal-ID tokens that lack the
# `WR-` namespace prefix. Bare tokens are tokens that resolve correctly
# only inside the windyroad-claude-plugin source repo's docs/decisions/,
# docs/jtbd/, and docs/problems/ trees — adopter projects either find
# nothing (failure mode 1, benign) or resolve to UNRELATED IDs in the
# adopter's own tree (failure mode 3, dangerous).
#
# Usage:
#   check-internal-id-leaks.sh [<root-dir>]
#
# Default <root-dir> is `.`.
#
# Token forms detected (case-sensitive, word-boundary):
#   ADR-NNN   (3+ digits)
#   JTBD-NNN  (3+ digits)
#   PNNN      (exactly 3 digits — problem ticket form)
#
# Tokens that DO NOT trigger:
#   WR-ADR-NNN, WR-JTBD-NNN, WR-PNNN  (namespace-prefixed; the strategy)
#   docstring annotation lines beginning with `# @adr` / `# @jtbd` /
#     `# @problem` (maintainer-facing source annotations, never expanded
#     into adopter agent context per ADR-055 §Scope)
#
# Files NOT scanned:
#   REFERENCE.md sibling files (lazy-loaded maintainer surface per ADR-054)
#
# Exit codes:
#   0 = always (advisory only — drift is signal, not failure)
#   2 = parse error (root dir missing or unreadable)
#
# Output format on drift (one line per file with leaks, terse machine-
# readable per ADR-038 progressive-disclosure budget):
#   OVER <plugin>/<relative-path> bare_count=<N>
#
# Followed by a final aggregate summary line:
#   TOTAL packages=<N> with_leaks=<M> drift_instances=<K>
#
# Output is empty (no lines) when no shipped artefact carries bare
# tokens — silent-on-pass per ADR-045 hook injection budget discipline.
#
# Output ordering (deterministic for stable retro-summary diffs):
#   OVER lines sorted by `<plugin>/<relative-path>` identifier.
#   TOTAL line last.
#
# Read-only — does NOT mutate any artefact. Per ADR-052, the bats fixture
# at scripts/test/check-internal-id-leaks.bats is BEHAVIOURAL — asserts
# script output on temp-fixture trees, NOT script source content.
#
# @problem P137 (Plugin-published artefacts reference internal IDs that
#   adopter projects can't resolve)
# @adr ADR-055 (Plugin-published artefacts use namespace-prefixed
#   permalinks — strategy + advisory detector)
# @adr ADR-038 (Progressive disclosure — terse machine-readable signal)
# @adr ADR-045 (Hook injection budget — silent-on-pass discipline)
# @adr ADR-052 (Behavioural-tests-default — fixture pattern)
# @adr ADR-054 (SKILL.md runtime budget — REFERENCE.md exclusion source)
# @adr ADR-005 (Plugin testing strategy)
# @jtbd JTBD-302 (Trust That the README Describes the Plugin I Just
#   Installed — semantic correctness axis of adopter-facing content)

set -uo pipefail

ROOT_DIR="${1:-.}"

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -d "$ROOT_DIR" ]; then
  echo "check-internal-id-leaks: root dir not found: $ROOT_DIR" >&2
  exit 2
fi

# ── Collect artefact paths ──────────────────────────────────────────────────

shopt -s nullglob
declare -a artefacts=()
for path in "$ROOT_DIR"/packages/*/skills/*/SKILL.md; do
  artefacts+=("$path")
done
for path in "$ROOT_DIR"/packages/*/agents/*.md; do
  artefacts+=("$path")
done
for path in "$ROOT_DIR"/packages/*/hooks/*.sh; do
  artefacts+=("$path")
done
for path in "$ROOT_DIR"/packages/*/CHANGELOG.md; do
  artefacts+=("$path")
done
shopt -u nullglob

if [ "${#artefacts[@]}" -eq 0 ]; then
  exit 0
fi

# ── Count bare tokens per file ──────────────────────────────────────────────
# Algorithm (perl one-liner per file):
#   1. Skip lines matching `^\s*#\s*@(adr|jtbd|problem)\b` (docstring annotations).
#   2. On surviving lines, find all `(?<!WR-)\b(ADR-\d{3,}|JTBD-\d{3,}|P\d{3})\b`
#      matches and increment a counter.
#   3. Print the counter as a single integer.
#
# Negative lookbehind `(?<!WR-)` is safe in perl. Word-boundary `\b` keeps
# `WR-ADR-014` matched only at position 3 (after `WR-`), which the
# lookbehind then rejects. Bare `ADR-014` has start-of-string or non-WR-
# char before, lookbehind passes, match counts.
#
# Word-boundary on the `P\d{3}` form requires \b on both ends so that
# `Phase` (no digit follows) and `P3` (only 1 digit) don't match.

declare -a leaks=()
declare -A package_set=()
declare -i total_drift=0

# Strip ROOT_DIR + trailing slash for relative-path display.
strip_root() {
  local full="$1"
  local prefix="$ROOT_DIR/packages/"
  echo "${full#"$prefix"}"
}

for path in "${artefacts[@]}"; do
  count=$(perl -ne '
    next if /^\s*#\s*\@(adr|jtbd|problem)\b/i;
    while (/(?<!WR-)\b(ADR-\d{3,}|JTBD-\d{3,}|P\d{3})\b/g) {
      $n++;
    }
    END { print $n // 0 }
  ' "$path")

  if [ "$count" -gt 0 ]; then
    rel="$(strip_root "$path")"
    leaks+=("$rel $count")
    plugin="${rel%%/*}"
    package_set["$plugin"]=1
    total_drift=$((total_drift + count))
  fi
done

if [ "${#leaks[@]}" -eq 0 ]; then
  exit 0
fi

# ── Emit OVER lines (sorted) ────────────────────────────────────────────────

IFS=$'\n' sorted=($(printf '%s\n' "${leaks[@]}" | sort))
unset IFS

for entry in "${sorted[@]}"; do
  identifier="${entry% *}"
  bare="${entry##* }"
  echo "OVER $identifier bare_count=$bare"
done

# ── Emit TOTAL summary ──────────────────────────────────────────────────────

echo "TOTAL packages=${#package_set[@]} with_leaks=${#leaks[@]} drift_instances=$total_drift"

exit 0
