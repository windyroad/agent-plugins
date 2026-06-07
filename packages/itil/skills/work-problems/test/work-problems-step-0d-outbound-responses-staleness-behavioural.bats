#!/usr/bin/env bats

# Step 0d behavioural fixture per P220 + ADR-062 § JTBD-006 driver:
# work-problems pre-flights /wr-itil:check-upstream-responses when the
# outbound-responses cache is stale or missing AND there exist local
# tickets carrying `## Reported Upstream` back-link sections. The
# staleness decision lives in
# `packages/itil/lib/check-outbound-responses-staleness.sh::should_promote_outbound_responses_preflight`
# so the SKILL.md Step 0d prose is a thin source-and-call wrapper
# around a behaviorally-testable shell function (P081 / user feedback:
# prefer behavioural over structural-grep tests).
#
# Cases covered (symmetric to Step 0b cases plus the back-link discovery
# axis that replaces channels-config):
#   1. No tickets with `## Reported Upstream` section → "no-back-link-tickets"
#      (downstream-adopter non-obligation; analogue to no-channels-config).
#   2. Back-link ticket present, cache absent → "first-run-cache-absent".
#   3. Back-link ticket present, cache present, last_checked null → "first-run-last-checked-null".
#   4. Back-link ticket present, cache fresh within TTL → "fresh-within-ttl".
#   5. Back-link ticket present, cache older than TTL → "ttl-expiry" (with age + ttl in the reason).
#   6. Custom ttl_seconds in cache honored (not hardcoded default).
#   7. Missing ttl_seconds field defaults to 86400 (24h symmetric with inbound).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  HELPER="$REPO_ROOT/packages/itil/lib/check-outbound-responses-staleness.sh"

  FIXTURE="$(mktemp -d)"
  mkdir -p "$FIXTURE/docs/problems"
}

teardown() {
  rm -rf "$FIXTURE"
}

# Helper: write a back-link ticket fixture under docs/problems/.
_write_backlink_ticket() {
  local ticket_path="$1"
  cat > "$ticket_path" <<'EOF'
# Problem 999: example back-link fixture

**Status**: Open

## Description

Fixture for Step 0d behavioural test.

## Reported Upstream

- **Repo**: example/upstream
- **URL**: https://github.com/example/upstream/issues/999
- **Filed**: 2026-06-08
EOF
}

@test "helper exists at the contracted path" {
  [ -f "$HELPER" ]
}

@test "case 1: no back-link tickets → no-back-link-tickets" {
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_outbound_responses_preflight "$FIXTURE"
  [ "$status" -eq 0 ]
  [ "$output" = "no-back-link-tickets" ]
}

@test "case 1b: tickets without ## Reported Upstream section → no-back-link-tickets" {
  cat > "$FIXTURE/docs/problems/100-no-back-link.open.md" <<'EOF'
# Problem 100: no upstream link

## Description

Local-only ticket.
EOF
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_outbound_responses_preflight "$FIXTURE"
  [ "$status" -eq 0 ]
  [ "$output" = "no-back-link-tickets" ]
}

@test "case 2: back-link ticket present, cache absent → first-run-cache-absent" {
  _write_backlink_ticket "$FIXTURE/docs/problems/100-back-link.open.md"
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_outbound_responses_preflight "$FIXTURE"
  [ "$status" -eq 0 ]
  [ "$output" = "first-run-cache-absent" ]
}

@test "case 2b: back-link in per-state subdir layout (RFC-002) is discovered" {
  mkdir -p "$FIXTURE/docs/problems/known-error"
  _write_backlink_ticket "$FIXTURE/docs/problems/known-error/220-cadence-gap.md"
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_outbound_responses_preflight "$FIXTURE"
  [ "$status" -eq 0 ]
  [ "$output" = "first-run-cache-absent" ]
}

@test "case 3: cache present, last_checked null → first-run-last-checked-null" {
  _write_backlink_ticket "$FIXTURE/docs/problems/100-back-link.open.md"
  cat > "$FIXTURE/docs/problems/.outbound-responses-cache.json" <<'EOF'
{ "last_checked": null, "tickets": {} }
EOF
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_outbound_responses_preflight "$FIXTURE"
  [ "$status" -eq 0 ]
  [ "$output" = "first-run-last-checked-null" ]
}

@test "case 4: cache fresh within TTL → fresh-within-ttl (silent-pass)" {
  _write_backlink_ticket "$FIXTURE/docs/problems/100-back-link.open.md"
  # last_checked 1 hour ago — well within 24h default TTL.
  local recent_iso
  recent_iso="$(python3 -c "import datetime; print((datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=1)).strftime('%Y-%m-%dT%H:%M:%SZ'))")"
  cat > "$FIXTURE/docs/problems/.outbound-responses-cache.json" <<EOF
{ "last_checked": "$recent_iso", "tickets": {} }
EOF
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_outbound_responses_preflight "$FIXTURE"
  [ "$status" -eq 0 ]
  [ "$output" = "fresh-within-ttl" ]
}

@test "case 5: cache older than TTL → ttl-expiry with age + ttl in the reason" {
  _write_backlink_ticket "$FIXTURE/docs/problems/100-back-link.open.md"
  # last_checked 2 days ago — past 24h default TTL.
  local stale_iso
  stale_iso="$(python3 -c "import datetime; print((datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=2)).strftime('%Y-%m-%dT%H:%M:%SZ'))")"
  cat > "$FIXTURE/docs/problems/.outbound-responses-cache.json" <<EOF
{ "last_checked": "$stale_iso", "tickets": {} }
EOF
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_outbound_responses_preflight "$FIXTURE"
  [ "$status" -eq 0 ]
  # Format: "ttl-expiry age=<N>s ttl=<M>s"
  [[ "$output" =~ ^ttl-expiry\ age=[0-9]+s\ ttl=86400s$ ]]
}

@test "case 6: custom ttl_seconds in cache is honored (not hardcoded default)" {
  # 1-hour TTL; last_checked 90 minutes ago → stale under the custom TTL,
  # but would be FRESH under the 86400s default. Confirms the helper reads
  # ttl_seconds from cache rather than hardcoding 86400.
  _write_backlink_ticket "$FIXTURE/docs/problems/100-back-link.open.md"
  local mid_iso
  mid_iso="$(python3 -c "import datetime; print((datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(minutes=90)).strftime('%Y-%m-%dT%H:%M:%SZ'))")"
  cat > "$FIXTURE/docs/problems/.outbound-responses-cache.json" <<EOF
{ "last_checked": "$mid_iso", "tickets": {}, "ttl_seconds": 3600 }
EOF
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_outbound_responses_preflight "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^ttl-expiry\ age=[0-9]+s\ ttl=3600s$ ]]
}

@test "case 7: missing ttl_seconds defaults to 86400 (symmetric with inbound)" {
  _write_backlink_ticket "$FIXTURE/docs/problems/100-back-link.open.md"
  local recent_iso
  recent_iso="$(python3 -c "import datetime; print((datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=1)).strftime('%Y-%m-%dT%H:%M:%SZ'))")"
  cat > "$FIXTURE/docs/problems/.outbound-responses-cache.json" <<EOF
{ "last_checked": "$recent_iso", "tickets": {} }
EOF
  # shellcheck disable=SC1090
  source "$HELPER"
  run should_promote_outbound_responses_preflight "$FIXTURE"
  [ "$status" -eq 0 ]
  [ "$output" = "fresh-within-ttl" ]
}
