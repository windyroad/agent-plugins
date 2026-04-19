#!/usr/bin/env bats
# Doc-lint guard: architect agent.md must include the runtime-path
# performance-review step per ADR-023 (wr-architect agent performance
# review scope). Closes P046 (wr-architect agent misses performance
# implications on high-traffic endpoints).
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011).
#
# Cross-reference:
#   P046 (wr-architect agent misses per-request performance implications)
#   ADR-023 (wr-architect agent performance review scope)
#   @jtbd JTBD-002 (ship with confidence)
#   @jtbd JTBD-101 (extend the suite with clear patterns)

setup() {
  AGENT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  AGENT_FILE="${AGENT_DIR}/agent.md"
}

@test "agent.md contains a runtime-path performance review section (ADR-023)" {
  run grep -nE "[Pp]erformance [Rr]eview|[Rr]untime-[Pp]ath" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md lists the runtime-path trigger categories (cache / throttle / rate-limit / per-request handler)" {
  # Cache directives
  run grep -niE "cache-control|etag|last-modified" "$AGENT_FILE"
  [ "$status" -eq 0 ]
  # Rate limiting / throttle
  run grep -niE "rate[- ]limit|throttl|quota" "$AGENT_FILE"
  [ "$status" -eq 0 ]
  # Per-request handler
  run grep -niE "per-request|per request handler" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md requires quantification: per-request cost delta (ADR-023 Confirmation criterion 2a)" {
  run grep -niE "per-request cost delta|cost delta per request" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md requires request-frequency estimate with cited source (ADR-023)" {
  run grep -niE "[Rr]equest[- ][Ff]requency" "$AGENT_FILE"
  [ "$status" -eq 0 ]
  # Must require citing a source (ADR/JTBD/telemetry/worst-case)
  run grep -niE "cite|source" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md requires product (cost x frequency) computation" {
  run grep -niE "(cost.*frequency|frequency.*cost|aggregate load|product)" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md bans qualitative-only performance claims (ADR-023 Confirmation criterion 2b)" {
  # The prompt must forbid phrases like "load is negligible", "microseconds only"
  run grep -niE "(must not|MUST NOT).*(qualitative|negligible|microsecond)" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md references performance-budget ADR convention by name (ADR-023 Confirmation criterion 2c)" {
  run grep -niE "performance[- ]budget" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md instructs a verdict against any in-scope performance-budget ADR" {
  # Must describe what to do when a budget is present vs missing
  run grep -niE "verdict|recommend creating|no performance budget" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md cross-references ADR-023 so readers can trace the rule's origin" {
  run grep -n "ADR-023" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}
