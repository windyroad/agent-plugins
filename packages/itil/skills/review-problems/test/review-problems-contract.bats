#!/usr/bin/env bats
# Contract assertions for /wr-itil:review-problems (P071 split slice 2).
#
# This skill hosts the "re-assess every open / known-error problem,
# auto-transition, fire the verification prompt, and rewrite the README
# cache" user intent previously hidden behind /wr-itil:manage-problem
# review. Unlike list-problems (slice 1, pure read-only) this skill
# owns the README cache write and the auto-transition path, so it
# requires the full governance tool surface (Write, Edit, Bash,
# AskUserQuestion, Skill for the commit-gate fallback).
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# @problem P071
# @jtbd JTBD-001 (enforce governance without slowing down — discoverable surface)
# @jtbd JTBD-101 (extend the suite with clear patterns — one skill per distinct user intent)
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   ADR-010 amended (Skill Granularity section) — split naming + forwarder contract
#   ADR-022 — Verification Pending status conventions (review-problems owns the queue prompt)
#   ADR-014 — governance skills commit their own work
#   ADR-015 — commit-gate delegation pattern
#   ADR-037 — contract-assertion bats pattern

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists and has frontmatter" {
  [ -f "$SKILL_FILE" ]
  run head -1 "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "---" ]
}

@test "SKILL.md frontmatter name is wr-itil:review-problems (P071 + ADR-010 amended)" {
  # Split naming convention per ADR-010 amendment: <verb>-<object> pair.
  # The new skill's name must match the phased-landing plan pinned in P071.
  run grep -n "^name: wr-itil:review-problems$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter description names the review intent (P071)" {
  # Description must name "re-assess" or "review" + "problem" so
  # Claude Code autocomplete surfaces the user intent rather than a
  # generic name.
  run grep -inE "^description:.*(re-assess|review).*problem|^description:.*problem.*(re-assess|review)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools includes Write + Edit (owns README refresh)" {
  # Review owns the README cache write and auto-transition Edits.
  # Unlike list-problems (pure read-only), this skill MUST carry Write
  # and Edit so the commit gate contract from ADR-014 holds.
  run grep -nE "^allowed-tools:.*Write" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Edit" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools includes Skill (commit-gate fallback)" {
  # Step 6 commit-gate fallback invokes /wr-risk-scorer:assess-release
  # when the pipeline subagent is unavailable. That fallback requires
  # the Skill tool per ADR-015.
  run grep -nE "^allowed-tools:.*Skill" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools includes AskUserQuestion (Verification prompt)" {
  # Step 4 fires AskUserQuestion for every .verifying.md ticket per
  # ADR-022. The AFK branch degrades gracefully (ADR-013 Rule 6) but
  # the primary path requires the tool.
  run grep -nE "^allowed-tools:.*AskUserQuestion" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the re-scoring scan scope (P071)" {
  # The skill reads .open.md and .known-error.md files and writes back
  # Priority + Effort + WSJF. .verifying.md and .parked.md are NOT
  # re-scored (multiplier 0) but are shown in dedicated sections.
  # The SKILL.md must name all four glob patterns so the contract is legible.
  run grep -inE "\.open\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\.known-error\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\.verifying\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\.parked\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md owns the README.md refresh write (P062 + ownership boundary)" {
  # Review is the canonical writer of docs/problems/README.md. The
  # sibling list-problems skill explicitly defers here. If this
  # contract drifts (e.g. list-problems starts writing the README or
  # review stops writing it), the fast-path cache goes stale.
  run grep -inE "docs/problems/README\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "(rewrite|write[ /]+overwrite|refresh|rewrites).*README\.md|README\.md.*(rewrite|refresh|overwrite|write)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md fires the Verification Queue prompt per ADR-022 (Step 4)" {
  # Step 4 is the structured path that transitions Verification Pending
  # → Closed. Without it, verifyings accumulate forever. The prompt
  # MUST include a fix summary per ADR-022 (not just ID + title +
  # version).
  run grep -inE "Verification (Queue|Pending)|verifying\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "Fix Released|fix summary" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md declares the auto-transition path (Open → Known Error)" {
  # Step 2.10 auto-transitions Open tickets with documented root cause
  # + workaround to Known Error. This is a defining behaviour of the
  # review skill; drift here means the backlog lingers in Open forever.
  run grep -inE "Auto-transition|auto.transition|Open.+Known Error|known-error" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md satisfies the commit gate per ADR-014 + ADR-015" {
  # Review is a governance skill per ADR-014: it commits its own work
  # after satisfying the commit gate. Per ADR-015 the gate has two
  # paths (primary subagent delegation + fallback assess-release
  # skill). Both MUST be documented so P035 stays closed.
  run grep -inE "wr-risk-scorer:pipeline|wr-risk-scorer:assess-release" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "ADR-014|ADR-015" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites the P057 staging trap on auto-transitions" {
  # Any git mv + Edit combo in this skill (Step 2.10 auto-transition,
  # Step 4 verification close) MUST re-stage explicitly. P057
  # codifies this; drift here means content edits leak into later
  # commits.
  run grep -inE "staging trap|P057|re-stage" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md reuses the RISK-POLICY.md risk framework (no hardcoded scale)" {
  # Step 1 reads RISK-POLICY.md for the current Impact/Likelihood
  # scales and label bands. Hardcoding a scale causes drift when the
  # policy is amended (ISO 31000 alignment axis).
  run grep -inE "RISK-POLICY\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites P071 and ADR-010 amended (P071 + ADR-025)" {
  # ADR-025 inheritance per ADR-037: contract-assertion bats should
  # reflect traceability cites on the skill spec document.
  run grep -inE "P071|ADR-010" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md does not carry a deprecated-arguments frontmatter flag (clean-split skill)" {
  # Architect advisory: review-problems is a clean-split skill with no
  # argument-subcommands itself. ADR-010 amendment's
  # `deprecated-arguments: true` flag is only valid on host skills with
  # forwarder routes — review-problems is the forwarder TARGET, not the
  # host.
  run grep -E "^deprecated-arguments:" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not use word-argument subcommand branching (P071 regression guard)" {
  # The whole point of P071: Claude Code autocomplete does not surface
  # arguments. A clean-split skill must not reintroduce word-arg
  # subcommand routing. The SKILL.md must not contain `If arguments
  # start with "list"` / `If arguments contain "work"` / etc. patterns.
  run grep -inE "If arguments start with|If arguments contain" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}
