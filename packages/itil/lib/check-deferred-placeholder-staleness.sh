#!/usr/bin/env bash
# Deferred-placeholder + README-cadence staleness check — Step 0c of
# /wr-itil:work-problems (per P271).
#
# P271 driver: /wr-itil:review-problems is the meta-workflow that re-rates
# the deferred-placeholder (Priority + Effort) WSJF inputs that
# /wr-itil:capture-problem leaves behind. Without an auto-fire trigger, the
# placeholders accumulate silently across sessions — 76 → 83 on the
# 2026-05-24 work-problems session evidenced the gap — and the AFK
# orchestrator dispatches iters against stale WSJF rankings until the
# maintainer manually invokes review-problems.
#
# Trigger rule — TWO-AXIS AND (load-bearing per architect verdict on the
# P271 fix shape, Condition 2). Both axes must hold; either alone over-fires:
#
#   1. count of deferred-placeholder tickets ≥ 3
#      Signal: there is work to re-rate. A backlog with <3 placeholders is
#      not stale enough to be worth a heavyweight review pass.
#
#   2. docs/problems/README.md "Last reviewed" line-3 age > 7 days
#      Signal: cadence has slipped. A README updated yesterday but with
#      3 fresh captures is the in-spec deferred-placeholder behaviour
#      (today's captures are tomorrow's review). The age axis filters out
#      this false-positive.
#
#   The intersection (count ≥ 3 AND age > 7 days) is the actual signal —
#   "there is work to do AND the cadence has slipped". Either-axis alone
#   produces false positives that erode trust in the trigger.
#
# Mirrors the Step 0b cache-staleness pattern at
# packages/itil/lib/check-upstream-cache-staleness.sh.
#
# <!-- DEFERRED-PLACEHOLDER-STALENESS-CONTRACT-SOURCE: packages/itil/skills/work-problems/SKILL.md Step 0c -->
#
# Any change to the threshold constants (3 placeholders, 7 days) MUST
# update this helper, work-problems SKILL.md Step 0c, manage-problem
# SKILL.md Step 0.5, and capture-problem SKILL.md Step 7 in the same
# commit — drift here re-opens P271.
#
# Source this file, then call `should_promote_review_problems_dispatch`:
#   . packages/itil/lib/check-deferred-placeholder-staleness.sh
#   reason="$(should_promote_review_problems_dispatch "$PWD")"
#
# Output (one of):
#   no-deferred-placeholders                            → count is 0; silent-pass.
#   below-threshold count=<N> threshold=3               → 0 < count < 3; silent-pass.
#   no-readme count=<N>                                 → README absent OR malformed
#                                                          line 3; first-run dispatch
#                                                          trigger.
#   fresh-readme count=<N> age=<X>s threshold=<Y>s      → README age within window;
#                                                          silent-pass per ADR-013
#                                                          Rule 5.
#   stale-readme count=<N> age=<X>s threshold=<Y>s      → THE auto-dispatch
#                                                          trigger; both axes met.
#
# Glob — DUAL-TOLERANT per ADR-031 RFC-002 migration window. Covers BOTH
# the flat `docs/problems/<NNN>-<title>.<state>.md` layout AND the per-state
# subdir `docs/problems/<state>/<NNN>-<title>.md` layout. Closed and
# verifying tickets are EXCLUDED — they carry no dev-work WSJF per ADR-022
# and their deferred-placeholders are out-of-scope for re-rate.
#
# Dependencies: bash 4+, grep, awk, python3 (for date parsing — portable
# across Linux/BSD).

should_promote_review_problems_dispatch() {
  local repo_root="${1:-$PWD}"
  local problems_dir="$repo_root/docs/problems"

  # Threshold constants — both axes documented above.
  local count_threshold=3
  local age_threshold_seconds=604800  # 7 days × 86400 seconds.

  # Axis 1 — count deferred-placeholder tickets across open + known-error
  # via dual-tolerant globs (RFC-002 migration window).
  local count=0
  local marker='deferred — re-rate at next /wr-itil:review-problems'
  local file
  shopt -s nullglob
  for file in \
    "$problems_dir"/open/*.md \
    "$problems_dir"/known-error/*.md \
    "$problems_dir"/*.open.md \
    "$problems_dir"/*.known-error.md; do
    [ -f "$file" ] || continue
    if grep -qF "$marker" "$file" 2>/dev/null; then
      count=$((count + 1))
    fi
  done
  shopt -u nullglob

  if [ "$count" -eq 0 ]; then
    echo "no-deferred-placeholders"
    return 0
  fi

  if [ "$count" -lt "$count_threshold" ]; then
    echo "below-threshold count=${count} threshold=${count_threshold}"
    return 0
  fi

  # Axis 2 — README.md "Last reviewed" line-3 age.
  local readme="$problems_dir/README.md"

  if [ ! -f "$readme" ]; then
    echo "no-readme count=${count}"
    return 0
  fi

  # Read line 3 — the canonical "Last reviewed" surface per P134 + the
  # SKILL.md contract. Use awk so the read survives BSD/GNU portability.
  local line3
  line3="$(awk 'NR==3' "$readme" 2>/dev/null || echo "")"

  # Parse the ISO date from the "Last reviewed: YYYY-MM-DD" prefix.
  # The line shape is `> Last reviewed: YYYY-MM-DD **<event>** — <summary>`
  # per the P134 inline rotation contract. A missing or malformed line is
  # treated as no-readme (defensive — forces a fresh dispatch rather than
  # silently silent-passing on malformed README state).
  local last_reviewed_date
  last_reviewed_date="$(echo "$line3" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"

  if [ -z "$last_reviewed_date" ]; then
    echo "no-readme count=${count}"
    return 0
  fi

  local last_reviewed_epoch now_epoch age_seconds
  last_reviewed_epoch="$(python3 -c "import datetime,sys; print(int(datetime.datetime.strptime(sys.argv[1], '%Y-%m-%d').replace(tzinfo=datetime.timezone.utc).timestamp()))" "$last_reviewed_date" 2>/dev/null || echo "0")"
  now_epoch="$(date +%s)"
  age_seconds=$((now_epoch - last_reviewed_epoch))

  if [ "$age_seconds" -gt "$age_threshold_seconds" ]; then
    echo "stale-readme count=${count} age=${age_seconds}s threshold=${age_threshold_seconds}s"
    return 0
  fi

  echo "fresh-readme count=${count} age=${age_seconds}s threshold=${age_threshold_seconds}s"
  return 0
}
