#!/usr/bin/env bats
# Behavioural shape contract for the inbound-discovery config + cache
# files (RFC-004 Slice A scaffold; consumed by Slice C orchestration).
#
# These assertions are BEHAVIOURAL per P081 — they parse the actual JSON
# files committed under docs/problems/ and verify the documented shapes
# hold. No SKILL/agent prose grep here; this is config-file content
# tested via jq.
#
# @problem P079
# @rfc RFC-004 (Slice A — scaffold; Slice E — coverage)
# @adr ADR-062 (channel config + cache schemas)
# @adr ADR-031 (docs/problems/ as the directory for cache + config files)
# @adr ADR-052 (behavioural-tests default)
# @adr ADR-037 (bats doc-lint — file-shape contracts)
# @jtbd JTBD-101 (downstream-adopter non-obligation — config file is opt-in)
# @jtbd JTBD-201 (audit-trail replay — cache file deterministic)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  CHANNELS_FILE="${REPO_ROOT}/docs/problems/.upstream-channels.json"
  CACHE_FILE="${REPO_ROOT}/docs/problems/.upstream-cache.json"
  AUDIT_LOG="${REPO_ROOT}/docs/audits/inbound-discovery-log.md"
}

# Skip everything if jq is absent; the maintainer's dev env has jq per
# the existing risk-scorer scripts, but adopter clones may not. Fail-soft.
@test "jq is available for JSON shape assertions" {
  command -v jq
}

# ──────────────────────────────────────────────────────────────────────────────
# docs/problems/.upstream-channels.json (Slice A scaffold — committed)
# ──────────────────────────────────────────────────────────────────────────────

@test "upstream-channels.json exists" {
  [ -f "$CHANNELS_FILE" ]
}

@test "upstream-channels.json is valid JSON" {
  run jq '.' "$CHANNELS_FILE"
  [ "$status" -eq 0 ]
}

@test "upstream-channels.json declares the schema URL" {
  run jq -r '."$schema"' "$CHANNELS_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ upstream-channels ]]
}

@test "upstream-channels.json has a channels[] array" {
  run jq -e '.channels | type == "array"' "$CHANNELS_FILE"
  [ "$status" -eq 0 ]
}

@test "upstream-channels.json carries ttl_seconds (cache freshness)" {
  run jq -e '.ttl_seconds | type == "number"' "$CHANNELS_FILE"
  [ "$status" -eq 0 ]
}

@test "default config polls all three documented channel types (issues / discussions / security-advisories)" {
  # ADR-062 § Channel config defaults: this repo's intake polls all
  # three. Adopters can edit; the default exercises the full pipeline.
  run jq -e '[.channels[] | .type] | contains(["github-issues"])' "$CHANNELS_FILE"
  [ "$status" -eq 0 ]
  run jq -e '[.channels[] | .type] | contains(["github-discussions"])' "$CHANNELS_FILE"
  [ "$status" -eq 0 ]
  run jq -e '[.channels[] | .type] | contains(["github-security-advisories"])' "$CHANNELS_FILE"
  [ "$status" -eq 0 ]
}

@test "each channel entry has a 'type' and 'repo' field (minimum schema)" {
  # Every channel must name what kind (type) and which upstream (repo).
  # Per-type additional fields (label / template / category) are optional
  # and per-channel-kind-specific.
  run jq -e '.channels | all(has("type") and has("repo"))' "$CHANNELS_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# docs/problems/.upstream-cache.json (Slice A scaffold — committed empty)
# ──────────────────────────────────────────────────────────────────────────────

@test "upstream-cache.json exists" {
  [ -f "$CACHE_FILE" ]
}

@test "upstream-cache.json is valid JSON" {
  run jq '.' "$CACHE_FILE"
  [ "$status" -eq 0 ]
}

@test "upstream-cache.json declares the schema URL" {
  run jq -r '."$schema"' "$CACHE_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ upstream-cache ]]
}

@test "upstream-cache.json has last_checked field (null or ISO timestamp)" {
  run jq -e '.last_checked == null or (.last_checked | type == "string")' "$CACHE_FILE"
  [ "$status" -eq 0 ]
}

@test "upstream-cache.json has channels{} object (per-channel cache map)" {
  run jq -e '.channels | type == "object"' "$CACHE_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# docs/audits/inbound-discovery-log.md (Slice D scaffold — committed)
# ──────────────────────────────────────────────────────────────────────────────

@test "inbound-discovery-log.md exists" {
  [ -f "$AUDIT_LOG" ]
}

@test "inbound-discovery-log.md cites ADR-062 (audit-log surface contract)" {
  run grep -nE 'ADR-062' "$AUDIT_LOG"
  [ "$status" -eq 0 ]
}

@test "inbound-discovery-log.md is committed under docs/audits/ per P131 (NOT under .claude/)" {
  # CLAUDE.md P131: project-generated artefacts under docs/, never .claude/.
  # The audit-log path is intentional per ADR-062 § Audit-log surface.
  [[ "$AUDIT_LOG" == */docs/audits/* ]]
  [[ "$AUDIT_LOG" != */.claude/* ]]
}
