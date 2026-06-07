#!/usr/bin/env bash
# Outbound-responses cache staleness check — Step 0d of /wr-itil:work-problems.
# P220 + ADR-062 § JTBD-006 driver: work-problems should pre-flight
# /wr-itil:check-upstream-responses when the outbound-responses cache is
# stale or missing AND local tickets carry `## Reported Upstream` back-link
# sections, so AFK loops keep upstream-reporter responses visible without
# the maintainer remembering to invoke check-upstream-responses first.
#
# The staleness comparison is the outbound symmetric counterpart of
# check-upstream-cache-staleness.sh's inbound-discovery contract. Any
# change to TTL semantics MUST update this helper, the check-upstream-
# responses SKILL.md Confirmation, and the Step 0d block in work-problems
# SKILL.md in the same commit.
# <!-- OUTBOUND-RESPONSES-STALENESS-CONTRACT-SOURCE: packages/itil/skills/check-upstream-responses/SKILL.md ## Confirmation -->
#
# Source this file, then call `should_promote_outbound_responses_preflight`:
#   . packages/itil/lib/check-outbound-responses-staleness.sh
#   reason="$(should_promote_outbound_responses_preflight "$PWD")"
#
# Output (one of):
#   no-back-link-tickets         → no problem tickets carry a `## Reported Upstream`
#                                  section; nothing to poll. Skip silently.
#                                  Downstream-adopter non-obligation; analogue
#                                  to inbound's `no-channels-config`.
#   first-run-cache-absent       → back-link tickets exist, cache file absent.
#                                  Dispatch check-upstream-responses.
#   first-run-last-checked-null  → cache present but last_checked is null.
#                                  Dispatch check-upstream-responses.
#   fresh-within-ttl             → cache within TTL; silent-pass.
#   ttl-expiry age=<N>s ttl=<M>s → cache older than TTL; dispatch.
#
# TTL source: cache.ttl_seconds if present, else 86400 (24h) — symmetric
# with the inbound axis default at packages/itil/lib/check-upstream-cache-staleness.sh.
#
# Dependencies: bash 4+, jq, python3 (for ISO-8601 parsing — portable across
# Linux/BSD date implementations).

should_promote_outbound_responses_preflight() {
  local repo_root="${1:-$PWD}"
  local problems_dir="$repo_root/docs/problems"
  local cache_file="$problems_dir/.outbound-responses-cache.json"

  if [ ! -d "$problems_dir" ]; then
    echo "no-back-link-tickets"
    return 0
  fi

  # Scan for `## Reported Upstream` back-link sections. Dual-tolerant per
  # RFC-002: flat layout `<NNN>-*.<status>.md` AND per-state subdir layout
  # `<status>/<NNN>-*.md`. Use grep -l (files-with-match); silent on
  # zero matches via the `|| true` short-circuit.
  local back_link_count
  back_link_count="$(
    grep -lE '^## Reported Upstream$' \
      "$problems_dir"/[0-9][0-9][0-9]-*.md \
      "$problems_dir"/*/[0-9][0-9][0-9]-*.md \
      2>/dev/null | wc -l | tr -d ' '
  )"

  if [ "${back_link_count:-0}" -eq 0 ]; then
    echo "no-back-link-tickets"
    return 0
  fi

  if [ ! -f "$cache_file" ]; then
    echo "first-run-cache-absent"
    return 0
  fi

  local last_checked
  last_checked="$(jq -r '.last_checked // ""' "$cache_file")"

  if [ -z "$last_checked" ] || [ "$last_checked" = "null" ]; then
    echo "first-run-last-checked-null"
    return 0
  fi

  local ttl_seconds
  ttl_seconds="$(jq -r '.ttl_seconds // 86400' "$cache_file")"

  local last_checked_epoch now_epoch cache_age
  last_checked_epoch="$(python3 -c "import datetime,sys; ts=sys.argv[1].replace('Z','+00:00'); print(int(datetime.datetime.fromisoformat(ts).timestamp()))" "$last_checked" 2>/dev/null || echo "0")"
  now_epoch="$(date +%s)"
  cache_age=$((now_epoch - last_checked_epoch))

  if [ "$cache_age" -gt "$ttl_seconds" ]; then
    echo "ttl-expiry age=${cache_age}s ttl=${ttl_seconds}s"
    return 0
  fi

  echo "fresh-within-ttl"
  return 0
}
