#!/usr/bin/env bats
# Doc-lint guard: wr-jtbd:agent output contract — the agent MUST emit a
# structured inline verdict in every response, regardless of the
# /tmp/jtbd-verdict file write. Closes P037 (JTBD reviewer sometimes
# returns a bare verdict without remediation reason).
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011).
#
# Cross-reference:
#   P037 (JTBD reviewer bare-verdict bug)
#   @jtbd JTBD-001 (enforce governance without slowing down)

setup() {
  AGENT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  AGENT_FILE="${AGENT_DIR}/agent.md"
}

@test "agent.md contains inline verdict templates (How to Report section)" {
  run grep -n "How to Report" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md declares inline output is REQUIRED in every response (P037)" {
  # Must say inline output is required / must be emitted every time.
  run grep -niE "(always|every|must|required).*inline|inline.*(always|every|must|required)" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md declares the primary communication channel is inline, not the file (P037)" {
  # Must clarify the verdict file is an internal signal, not a replacement for inline output
  run grep -niE "(primary|authoritative).*(inline|user-facing|response)|inline.*(primary|authoritative)" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md requires a specific verdict line on every response (PASS or ISSUES FOUND)" {
  # The verdict line is explicit - bold JTBD Review: PASS / ISSUES FOUND
  run grep -nE "JTBD Review: (PASS|ISSUES FOUND|JOB UPDATE NEEDED|PERSONA UPDATE NEEDED)" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md requires remediation guidance on every FAIL verdict (P037)" {
  # On ISSUES FOUND the agent must include actionable guidance (what to change / what job / what fix)
  run grep -niE "remediation|actionable|what (should|would need)|fix:|issue:" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md cross-references P037 so readers can trace the contract's origin" {
  run grep -n "P037" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md explicitly forbids bare verdict without reason (P037)" {
  # Directly addresses the observed bug: verdict without body
  run grep -niE "(must not|MUST NOT|do not|DO NOT|never) (emit|return|produce) (a )?bare|without (reason|remediation|detail|actionable|explanation)" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}
