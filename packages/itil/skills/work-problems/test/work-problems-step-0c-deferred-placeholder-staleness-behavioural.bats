#!/usr/bin/env bats

# Step 0c behavioural fixture per P271:
# work-problems pre-flights /wr-itil:review-problems when deferred-placeholder
# tickets accumulate AND the docs/problems/README.md "Last reviewed" line is
# stale. Mirrors the Step 0b cache-staleness shape (helper-in-lib + 5-outcome
# enum + behavioural bats) so the SKILL.md Step 0c prose stays a thin
# source-and-call wrapper around a behaviorally-testable shell function.
#
# Trigger rule — two-axis AND per P271 § Recommended fix shape (architect
# Condition 2 — both axes are load-bearing; either alone over-fires):
#   - count of deferred-placeholder tickets ≥ 3 (signal: there is work to
#     re-rate), AND
#   - README.md "Last reviewed" line-3 age > 7 days (signal: cadence has
#     slipped).
#
# Cases covered:
#   1. No deferred placeholders → "no-deferred-placeholders"
#   2. Count below threshold (1 or 2) → "below-threshold count=<N> threshold=3"
#   3. Count ≥ 3 + README absent → "no-readme count=<N>"
#   4. Count ≥ 3 + README fresh (< 7 days) → "fresh-readme count=<N> age=<X>s threshold=<Y>s"
#   5. Count ≥ 3 + README stale (> 7 days) → "stale-readme count=<N> age=<X>s threshold=<Y>s"
#   6. Dual-tolerant glob (per ADR-031 RFC-002 migration window — both flat
#      docs/problems/<NNN>-*.<state>.md AND per-state docs/problems/<state>/<NNN>-*.md
#      contribute to count)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  HELPER="$REPO_ROOT/packages/itil/lib/check-deferred-placeholder-staleness.sh"

  FIXTURE="$(mktemp -d)"
  mkdir -p "$FIXTURE/docs/problems/open"
  mkdir -p "$FIXTURE/docs/problems/known-error"
}

teardown() {
  rm -rf "$FIXTURE"
}

# Helper — write a problem ticket with the deferred-placeholder marker.
write_deferred_ticket() {
  local path="$1"
  cat > "$path" <<'EOF'
# Problem 999: test

**Status**: Open
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

test fixture
EOF
}

# Helper — write a non-deferred (already-rated) ticket.
write_rated_ticket() {
  local path="$1"
  cat > "$path" <<'EOF'
# Problem 998: test

**Status**: Open
**Priority**: 6 (Medium) — Impact: 3 x Likelihood: 2
**Effort**: S

## Description

test fixture
EOF
}

# Helper — write a README.md with a known "Last reviewed" date on line 3.
write_readme_with_date() {
  local path="$1"
  local iso_date="$2"
  cat > "$path" <<EOF
# Problem Backlog

> Last reviewed: $iso_date **review** — test fixture
> Run \`/wr-itil:review-problems\` to refresh WSJF rankings.

## WSJF Rankings
EOF
}

@test "helper exists at the contracted path" {
  [ -f "$HELPER" ]
}

@test "case 1: no deferred placeholders → no-deferred-placeholders" {
  write_rated_ticket "$FIXTURE/docs/problems/open/001-foo.md"
  write_rated_ticket "$FIXTURE/docs/problems/open/002-bar.md"
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  [ "$output" = "no-deferred-placeholders" ]
}

@test "case 2: count below threshold (1) → below-threshold" {
  write_deferred_ticket "$FIXTURE/docs/problems/open/001-foo.md"
  write_rated_ticket "$FIXTURE/docs/problems/open/002-bar.md"
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^below-threshold\ count=1\ threshold=3$ ]]
}

@test "case 2b: count below threshold (2) → below-threshold" {
  write_deferred_ticket "$FIXTURE/docs/problems/open/001-foo.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/002-bar.md"
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^below-threshold\ count=2\ threshold=3$ ]]
}

@test "case 3: count ≥ 3 + README absent → no-readme (first-run dispatch trigger)" {
  write_deferred_ticket "$FIXTURE/docs/problems/open/001-foo.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/002-bar.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/003-baz.md"
  # No README written.
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^no-readme\ count=3$ ]]
}

@test "case 4: count ≥ 3 + README fresh (< 7 days) → fresh-readme silent-pass" {
  write_deferred_ticket "$FIXTURE/docs/problems/open/001-foo.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/002-bar.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/003-baz.md"
  # README dated 3 days ago — fresh under 7-day threshold.
  local recent_iso
  recent_iso="$(python3 -c "import datetime; print((datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=3)).strftime('%Y-%m-%d'))")"
  write_readme_with_date "$FIXTURE/docs/problems/README.md" "$recent_iso"
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^fresh-readme\ count=3\ age=[0-9]+s\ threshold=604800s$ ]]
}

@test "case 5: count ≥ 3 + README stale (> 7 days) → stale-readme (dispatch trigger)" {
  write_deferred_ticket "$FIXTURE/docs/problems/open/001-foo.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/002-bar.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/003-baz.md"
  # README dated 14 days ago — stale under 7-day threshold.
  local stale_iso
  stale_iso="$(python3 -c "import datetime; print((datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=14)).strftime('%Y-%m-%d'))")"
  write_readme_with_date "$FIXTURE/docs/problems/README.md" "$stale_iso"
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^stale-readme\ count=3\ age=[0-9]+s\ threshold=604800s$ ]]
}

@test "case 6: dual-tolerant glob — per-state subdir layout (ADR-031 post-migration)" {
  # Per-state subdir tickets (post-RFC-002-migration shape — the dominant
  # shape in this monorepo).
  write_deferred_ticket "$FIXTURE/docs/problems/open/100-foo.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/101-bar.md"
  write_deferred_ticket "$FIXTURE/docs/problems/known-error/102-baz.md"
  # No README → first-run dispatch.
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^no-readme\ count=3$ ]]
}

@test "case 6b: dual-tolerant glob — flat layout (ADR-031 pre-migration window)" {
  # Flat-layout tickets (pre-RFC-002-migration shape — the legacy shape).
  write_deferred_ticket "$FIXTURE/docs/problems/200-foo.open.md"
  write_deferred_ticket "$FIXTURE/docs/problems/201-bar.open.md"
  write_deferred_ticket "$FIXTURE/docs/problems/202-baz.known-error.md"
  # No README → first-run dispatch.
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^no-readme\ count=3$ ]]
}

@test "case 6c: dual-tolerant glob — mixed layout (RFC-002 migration in progress)" {
  # Mixed-layout tickets — both shapes contribute to the count.
  write_deferred_ticket "$FIXTURE/docs/problems/open/100-foo.md"
  write_deferred_ticket "$FIXTURE/docs/problems/200-bar.open.md"
  write_deferred_ticket "$FIXTURE/docs/problems/known-error/300-baz.md"
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^no-readme\ count=3$ ]]
}

@test "case 7: README missing 'Last reviewed' line → no-readme (defensive fallback)" {
  write_deferred_ticket "$FIXTURE/docs/problems/open/001-foo.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/002-bar.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/003-baz.md"
  # README exists but no "Last reviewed:" marker on line 3.
  cat > "$FIXTURE/docs/problems/README.md" <<'EOF'
# Problem Backlog

Some other line that does not have the Last reviewed marker.

## WSJF Rankings
EOF
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  # Defensive: parse failure routes to no-readme (forces a fresh dispatch
  # rather than silently silent-passing on malformed README).
  [[ "$output" =~ ^no-readme\ count=3$ ]]
}

@test "case 8: closed and verifying tickets do NOT contribute to count" {
  # Only open + known-error tickets are eligible re-rate candidates.
  # .verifying.md and .closed.md tickets carry no WSJF (excluded from
  # dev-work ranking per ADR-022); their deferred-placeholders must not
  # influence the dispatch.
  mkdir -p "$FIXTURE/docs/problems/closed"
  mkdir -p "$FIXTURE/docs/problems/verifying"
  write_deferred_ticket "$FIXTURE/docs/problems/closed/100-foo.md"
  write_deferred_ticket "$FIXTURE/docs/problems/verifying/101-bar.md"
  write_deferred_ticket "$FIXTURE/docs/problems/open/102-baz.md"
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_review_problems_dispatch "$FIXTURE"
  [ "$status" -eq 0 ]
  # Only the open/ ticket counts → below threshold.
  [[ "$output" =~ ^below-threshold\ count=1\ threshold=3$ ]]
}
