#!/usr/bin/env bash
# check-fail-soft-skip-discipline.sh — advisory lint for P351 (skills
# fail-soft-skip when their precondition config is missing — should
# auto-bootstrap with user input as needed rather than silently
# skipping).
#
# Detects SKILL.md prose that names the fail-soft-skip pattern without
# a paired auto-bootstrap routine. The default behaviour of skills with
# config-file preconditions has been "fail-soft skip" when the config is
# missing; the right behaviour (per P351) is to recognise the gap and
# auto-bootstrap the missing config — invoking AskUserQuestion for any
# required user input, then proceeding with the original pass. In AFK
# mode where AskUserQuestion is unavailable, queue a config-direction
# outstanding_question and continue other work rather than silently
# skipping a desired capability.
#
# This lint walks `packages/*/skills/*/SKILL.md` files for matching
# patterns and emits one WARN line per match. Per architect review
# (a6747bd57c7953b14): the broad `skipping` pattern false-positives on
# legitimate per-channel skip prose; we tighten to the
# `skipping.*config|skipping.*not configured` shape that is the
# load-bearing signal class.
#
# Usage:
#   check-fail-soft-skip-discipline.sh [<repo-root>]
#     <repo-root> defaults to the current working directory.
#
# Environment:
#   WR_FAIL_SOFT_SKIP_WARN_ONLY=1   Phase 1 advisory (default) — exit 0
#                                    even when violations exist.
#   WR_FAIL_SOFT_SKIP_WARN_ONLY=0   Phase 2 load-bearing — exit 1 when
#                                    violations exist.
#
# Exit codes:
#   0 = clean OR Phase 1 advisory with violations
#   1 = Phase 2 load-bearing with violations
#   2 = usage / path error
#
# Output format (one line per violation, to stderr):
#   WARN  <relpath>:<line>  <matched-pattern>: <line-snippet>
#
# Promotion criteria (Phase 1 → Phase 2):
#   Promote `WR_FAIL_SOFT_SKIP_WARN_ONLY=0` once every affected SKILL.md
#   has been migrated to the auto-bootstrap pattern.
#
# @adr ADR-040 (advisory-then-load-bearing reusable pattern)
# @adr ADR-049 (plugin-bundled scripts; PATH shim)
# @adr ADR-052 (behavioural-tests-default)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — advisory exit 0)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down)
# @jtbd JTBD-101 (Extend the Suite with New Plugins)
# @problem P351 (skills fail-soft-skip when precondition config missing
#                — should auto-bootstrap with user input)

set -uo pipefail

# Self-application: this lint grep / sed / awks SKILL.md content.
export LC_ALL=en_US.UTF-8

REPO_ROOT="${1:-$(pwd)}"
WARN_ONLY="${WR_FAIL_SOFT_SKIP_WARN_ONLY:-1}"

if [ ! -d "$REPO_ROOT" ]; then
  echo "check-fail-soft-skip-discipline: not a directory: $REPO_ROOT" >&2
  exit 2
fi

if [ ! -d "$REPO_ROOT/packages" ]; then
  echo "check-fail-soft-skip-discipline: no packages/ subdir under $REPO_ROOT" >&2
  exit 2
fi

# Patterns tightened per architect review to load-bearing signal class
# (avoid false-positives on legitimate per-channel skip prose like
# "skipping the failing channel/report"):
#   1. `fail-soft skip`            — the canonical name of the pattern.
#   2. `silently skip`             — direct synonym.
#   3. `skipping.*config`          — skipping tied to a config artefact.
#   4. `skipping.*not configured`  — explicit precondition-config skip.
#   5. `not configured.*skip`      — the reverse phrasing.
PATTERNS=(
  'fail-soft skip'
  'silently skip'
  'skipping.*config'
  'skipping.*not configured'
  'not configured.*skip'
)

# Combined extended-regex for a single grep pass.
PATTERN_RE='fail-soft skip|silently skip|skipping.*config|skipping.*not configured|not configured.*skip'

mapfile -t TARGETS < <(
  find "$REPO_ROOT/packages" \
    -mindepth 4 -maxdepth 5 \
    -type f -name 'SKILL.md' \
    -path '*/skills/*' \
    2>/dev/null | sort
)

violations=0
scanned=0

for file in "${TARGETS[@]}"; do
  scanned=$((scanned + 1))
  rel="${file#"$REPO_ROOT"/}"

  # grep -n -E emits "<line_no>:<line>" per match. Read each match and
  # emit a WARN line. We deliberately do NOT attempt to detect a paired
  # auto-bootstrap routine in the same file — Phase 1 emits one WARN per
  # raw pattern hit; SKILL.md authors disambiguate. The promotion
  # criteria for Phase 2 is "every WARN'd file migrated to the
  # auto-bootstrap pattern".
  while IFS= read -r match; do
    [ -z "$match" ] && continue
    line_no="${match%%:*}"
    line_text="${match#*:}"
    # Derive which pattern hit. First-match-wins ordering.
    matched_pattern=''
    for pat in "${PATTERNS[@]}"; do
      if echo "$line_text" | grep -E -i -q "$pat"; then
        matched_pattern="$pat"
        break
      fi
    done
    # Trim the snippet to keep WARN lines readable.
    snippet="${line_text:0:120}"
    echo "WARN  $rel:$line_no  $matched_pattern: $snippet" >&2
    violations=$((violations + 1))
  done < <(grep -E -i -n "$PATTERN_RE" "$file" 2>/dev/null || true)
done

if [ "$violations" -gt 0 ]; then
  echo "" >&2
  echo "check-fail-soft-skip-discipline: $violations potential fail-soft-skip site(s) across $scanned SKILL.md file(s)" >&2
  echo "Phase 1 advisory (WR_FAIL_SOFT_SKIP_WARN_ONLY=$WARN_ONLY). Authors should pair each site with an auto-bootstrap routine per P351." >&2
  if [ "$WARN_ONLY" = "0" ]; then
    exit 1
  fi
fi

exit 0
