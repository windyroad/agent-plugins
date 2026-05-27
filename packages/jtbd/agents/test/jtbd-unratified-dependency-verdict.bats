#!/usr/bin/env bats
# Doc-lint guard: jtbd agent.md must carry the [Unratified Dependency] verdict
# (ADR-068 enforcement surface 3 / RFC-011 / P323) — flag a change or plan that
# explicitly cites/implements/serves a persona or job lacking `human-oversight:
# confirmed` (unratified, non-superseded), keyed on the oversight marker NOT
# `status:`. The JTBD twin of the architect side's surface 3 (RFC-010 / P318).
#
# tdd-review: structural-permitted (justification: P176 — agent behaviour is
# prompt-driven with no skill-invocation harness to exercise the verdict
# behaviourally; ADR-052 Surface 2 structural-justified case, NOT an ADR-005
# Permitted Exception). When P176 lands, upgrade to a behavioural test that
# feeds the agent a change citing an unratified persona/job and asserts the
# verdict. The single-artifact predicate IS behaviourally tested today — see
# packages/jtbd/scripts/test/is-job-or-persona-unconfirmed.bats.
#
# Cross-reference:
#   ADR-068 (JTBD oversight marker + drain — surface 3 amendment 2026-05-27)
#   ADR-074 (Confirm a decision's substance before building dependent work)
#   ADR-066 (oversight marker; orthogonal status/oversight axes)
#   RFC-011 / P323 (this enforcement surface); RFC-010 / P318 (the ADR-side twin)
#   ADR-052 Surface 2 (structural-justified verdict) + P176 (harness gap)
#   @jtbd JTBD-202 (pre-flight governance checks) / JTBD-101 (extend the suite)

setup() {
  AGENT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  AGENT_FILE="${AGENT_DIR}/agent.md"
}

@test "agent.md lists [Unratified Dependency] as a verdict/issue type (ADR-068 surface 3)" {
  run grep -n '\[Unratified Dependency\]' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md has an 'Unratified Dependency (build-upon guard' section citing ADR-068" {
  run grep -niE "Unratified Dependency \(build-upon guard" "$AGENT_FILE"
  [ "$status" -eq 0 ]
  run grep -n "ADR-068" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md keys the flag on the oversight marker, NOT on status (orthogonal axes)" {
  # ADR-066 / user correction 2026-05-27: building on a ratified-but-proposed job is fine.
  run grep -niE "NEVER on .?status|not .?\`?status|orthogonal" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md invokes the predicate by exit code (the jtbd agent has Bash; not a prose-grep mirror)" {
  run grep -n "wr-jtbd-is-job-or-persona-unconfirmed" "$AGENT_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "exit code|exit 0|exit 1" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md guards against over-firing on ambient alignment (inverse-P078 / explicit cite)" {
  run grep -niE "explicit(ly)? cite|ambient alignment|over-?fire|NOT fire on that mere match" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md routes the fix to /wr-jtbd:confirm-jobs-and-personas (the surface-2 drain)" {
  run grep -n "/wr-jtbd:confirm-jobs-and-personas" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}
