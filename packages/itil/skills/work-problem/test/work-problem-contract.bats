#!/usr/bin/env bats
# Contract assertions for /wr-itil:work-problem (P071 split slice 3).
#
# This skill hosts the "pick the highest-WSJF ticket and work it" user
# intent previously hidden behind /wr-itil:manage-problem work. Unlike
# the plural orchestrator (/wr-itil:work-problems — batch AFK loop),
# this singular skill runs exactly one ticket per invocation and fires
# the AskUserQuestion selection prompt in interactive mode. Execution
# is delegated to /wr-itil:manage-problem <NNN> to avoid forking the
# per-ticket workflow.
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
#   ADR-013 Rule 1 — structured user interaction (AskUserQuestion selection prompt)
#   ADR-013 Rule 6 — AFK non-interactive fallback
#   ADR-014 — governance skills commit their own work (delegated target owns commits)
#   ADR-032 — governance skill invocation patterns (plural orchestrator delegates here)
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

@test "SKILL.md frontmatter name is wr-itil:work-problem (singular, P071 + ADR-010 amended)" {
  # Split naming convention per ADR-010 amendment: <verb>-<object>.
  # CRITICAL: singular "work-problem", NOT plural "work-problems" — the
  # plural name is reserved for the AFK orchestrator that already exists.
  # Name coexistence is a P071 acknowledged trade-off.
  run grep -n "^name: wr-itil:work-problem$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter name is NOT wr-itil:work-problems (regression guard for name collision)" {
  # Guard against the easy slip of renaming this skill to match the
  # plural orchestrator. If the name drifts to plural, `/wr-itil:`
  # autocomplete shows two plural-looking skills side by side and users
  # cannot tell which is interactive vs batch.
  run grep -n "^name: wr-itil:work-problems$" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md frontmatter description names the pick-and-run intent (P071)" {
  # Description must name "pick" / "work" / "highest-WSJF" so Claude
  # Code autocomplete surfaces the user intent rather than a generic
  # name. Also must mention "singular" or distinguish from the plural
  # orchestrator so users pick the right one.
  run grep -inE "^description:.*(pick|highest.wsjf|work.*problem)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "^description:.*(singular|one ticket|distinct from.*work-problems)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools includes AskUserQuestion (selection prompt)" {
  # Step 2 fires AskUserQuestion for the selection in interactive mode
  # (ADR-013 Rule 1). Without the tool the structured-interaction
  # contract cannot hold.
  run grep -nE "^allowed-tools:.*AskUserQuestion" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools includes Skill (delegation to manage-problem + review-problems)" {
  # Step 1 delegates the cache refresh to /wr-itil:review-problems when
  # stale; Step 3 delegates the per-ticket execution to
  # /wr-itil:manage-problem <NNN>. Both use the Skill tool per ADR-010's
  # thin-router discipline.
  run grep -nE "^allowed-tools:.*Skill" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the singular-vs-plural naming distinction (P071 coexistence)" {
  # The most common user confusion will be work-problem vs
  # work-problems. The SKILL.md must name the distinction explicitly
  # so `/wr-itil:` autocomplete readers can tell them apart. Without
  # this, users will pick the wrong one and either run a single ticket
  # when they wanted the AFK loop or vice-versa.
  run grep -inE "work-problems.*plural|plural.*work-problems|AFK orchestrator" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md delegates execution to /wr-itil:manage-problem (anti-fork discipline)" {
  # Per ADR-010 thin-router: the split skill owns selection, NOT
  # execution. The per-ticket investigate/transition/fix/release flow
  # stays on /wr-itil:manage-problem <NNN>. If this skill re-implements
  # the execution inline, the deprecation window hardens into a
  # permanent fork.
  run grep -inE "/wr-itil:manage-problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "delegate.*manage-problem|Skill tool.*manage-problem|manage-problem.*Skill tool" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md defers README.md cache refresh to /wr-itil:review-problems (P062 ownership)" {
  # P062 makes /wr-itil:review-problems the canonical README.md cache
  # writer. This skill reads the cache but must NOT rewrite it —
  # re-implementing the refresh here would break the one-canonical-
  # writer invariant.
  run grep -inE "/wr-itil:review-problems" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "(delegate|defer|refresh).*review-problems|review-problems.*(refresh|delegate|defer)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md reads README.md cache via the git-history freshness test (P031)" {
  # Same freshness check as list-problems and review-problems — mtime
  # is unreliable in worktrees per P031. Drift here means false
  # cache-hit (serving a stale ranking) or false cache-miss (spamming
  # review refreshes).
  run grep -inE "docs/problems/README\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "git log.*--format.*README\.md|readme_commit" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md fires the AskUserQuestion selection prompt (ADR-013 Rule 1)" {
  # Step 2 is the structured-interaction path: single top-WSJF ticket
  # shown as Recommended, or tied tickets shown as peer options. Never
  # prose "(a)/(b)/(c)".
  run grep -inE "AskUserQuestion" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "Next problem|Recommended|tied" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md forbids prose selection fallback (P053 + ADR-013 Rule 1 regression guard)" {
  # Prose "which would you like?" or "(a)/(b)/(c)" is the anti-pattern
  # ADR-013 Rule 1 and P053 codify against. The SKILL.md must say
  # "never" so the contract is legible at the spec level.
  run grep -inE "never.*prose|never.*\(a\)/\(b\)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the AFK non-interactive branch (ADR-013 Rule 6)" {
  # When /wr-itil:work-problems invokes this skill inside an AFK
  # subagent iteration, AskUserQuestion is unavailable — the selection
  # has already happened at the orchestrator level. The skill must
  # degrade gracefully per Rule 6.
  run grep -inE "AFK|non-interactive|ADR-013 Rule 6|Rule 6" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the scope-expansion AskUserQuestion (3-option shape)" {
  # Effort drift during investigation or architect review must fire the
  # standard Continue / Re-rank / Pick-different three-option prompt,
  # same as /wr-itil:manage-problem's Working a Problem section.
  run grep -inE "Scope change|scope.expansion" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "Continue with expanded scope|Update problem and re-rank|Pick a different problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md runs exactly one ticket per invocation (singular contract)" {
  # The whole point of the singular skill: one ticket, then stop. The
  # SKILL.md must say "do not loop automatically" or equivalent so the
  # contract is explicit. Looping is the plural orchestrator's job.
  run grep -inE "do not loop automatically|one ticket per invocation|singular" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md does not carry a deprecated-arguments frontmatter flag (clean-split skill)" {
  # Architect advisory: work-problem is a clean-split skill with no
  # argument-subcommands itself. ADR-010 amendment's
  # `deprecated-arguments: true` flag is only valid on host skills with
  # forwarder routes — work-problem is a forwarder TARGET, not a host.
  run grep -E "^deprecated-arguments:" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not use word-argument subcommand branching (P071 regression guard)" {
  # The whole point of P071: Claude Code autocomplete does not surface
  # arguments. A clean-split skill must not reintroduce word-arg
  # subcommand routing.
  run grep -inE "If arguments start with|If arguments contain" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md cites P071 and ADR-010 amended (traceability per ADR-037)" {
  # ADR-037 traceability: the skill spec cites the problem it closes
  # and the ADR that authorises the split.
  run grep -inE "P071|ADR-010" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites ADR-032 + P077 (AFK orchestrator delegation target)" {
  # /wr-itil:work-problems Step 5 delegates iterations via the Agent
  # tool (P077). This skill is the execution unit those iterations
  # invoke. The cross-reference documents the pair relationship so
  # future drift to /wr-itil:work-problems doesn't orphan this skill.
  run grep -inE "P077|ADR-032" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
