#!/usr/bin/env bats
# P206 — work-problems Step 5 iteration-prompt-body must EXPLICITLY require
# AFK iter subprocesses to author a `.changeset/*.md` alongside any fix
# commit that ships shippable code. Hook P141 (itil-changeset-discipline.sh)
# enforces this at git-commit time but depends on the plugin marketplace
# cache being current. The prompt-time constraint composes defence-in-depth
# with the hook so iter subprocesses self-author the changeset rather than
# discovering the gap at commit time (or worse — slipping through when the
# hook is missing from the install).
#
# Reported as inbound from downstream consumer bbstats (their P195) on
# 2026-05-15; covered by ADR-076 Origin field tier.
#
# tdd-review: structural-permitted (justification: SKILL.md is the named
# contract document under ADR-052; behavioural alternative would require a
# synthetic `claude -p` iter dispatch harness that completes a fix commit
# and asserts `.changeset/*.md` co-presence — that harness sits outside the
# skill layer and depends on the Anthropic CLI binary. Same Permitted
# Exception precedent as `work-problems-step-5-delegation.bats:99-105` and
# the P083 / P086 / P089 ScheduleWakeup / retro / stdin-redirect fixtures
# in the same directory).
#
# @problem P206
# @problem P141
# @jtbd JTBD-006
# @jtbd JTBD-007
# @jtbd JTBD-001
#
# Cross-reference:
#   P206 — this ticket (work-problems iter workers don't add changesets)
#   P141 — sibling changeset-discipline hook (hook-level enforcement;
#     prompt-time constraint composes defence-in-depth)
#   bbstats#195 — inbound report from downstream consumer
#   ADR-014 (governance skills commit their own work)
#   ADR-018 (inter-iteration release cadence — changesets are the load-
#     bearing input to ADR-020's auto-release path)
#   ADR-052 (behavioural tests default; structural-permitted with comment)
#   ADR-076 (inbound-reported problems rank ahead via sort tier — Origin
#     field stamping)
#   JTBD-006 (Progress the Backlog While I'm Away) — load-bearing
#   JTBD-007 (Keep Plugins Current Across Projects) — closure depends on
#     release actually shipping

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md Step 5 iteration-prompt-body names changeset as required when fix changes shippable code (P206)" {
  # The iteration-prompt-body must EXPLICITLY require iter subprocesses to
  # author a `.changeset/*.md` alongside any fix commit that ships shippable
  # code. Without the explicit constraint, iter subprocesses can complete
  # fix commits that the orchestrator's Step 6.5 release-cadence drain
  # then has nothing to release — fixes accumulate without an npm publish.
  # The constraint must name `changeset` AND a "shippable code" qualifier
  # so doc-only and test-only commits are correctly exempted.
  run grep -niE "changeset.{0,200}(shippable|publishable|packages/<plugin>)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 iteration-prompt-body exempts doc-only and test-only changes from the changeset requirement (P206)" {
  # Doc-only changes (e.g. JTBD edits, ADR edits, retro additions) and
  # test-only changes (under `test/`) ship no behaviour — requiring a
  # changeset for them would author noise CHANGELOG bullets per release.
  # The constraint must name the exemption explicitly so iter subprocesses
  # do not over-apply the rule.
  run grep -niE "(doc.?only|docs.?only|test.?only).{0,80}(omit|may omit|no changeset|not required)|changeset.{0,80}(omit|exempt)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 iteration-prompt-body cites P141 as the defence-in-depth hook (P206)" {
  # The prompt-time constraint composes with hook P141 (changeset-discipline).
  # Naming P141 inline in the prompt-body makes the defence-in-depth
  # composition self-documenting — a future contributor reading the prompt
  # understands the hook is the second layer, not the only layer.
  run grep -nE "P141" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Related section cites P206 (this fix)" {
  # ADR-037 + ADR-052 self-documenting contract: the contract document
  # carries a Related section listing the problem tickets it satisfies.
  # P206 closure depends on this citation landing.
  run grep -nE "P206" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 iteration-prompt-body cites bbstats#195 as the inbound source (P206 + ADR-076 Origin)" {
  # ADR-076 reported-first tier requires the Origin field to be visible at
  # the contract surface so future contributors understand the constraint
  # was driven by external evidence, not internal speculation. The bbstats
  # back-link is the audit anchor.
  run grep -niE "bbstats.{0,20}195|bbstats/.{0,30}195|bbstats#195" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
