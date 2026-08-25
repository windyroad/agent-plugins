#!/usr/bin/env bats

# @problem P519 — The Verification Pending -> Closed transition was reserved
#                 for the maintainer across eleven shipped SKILL prose loci, so
#                 evidence-based closure never fired and the verification queue
#                 could not drain (153 tickets, 1/153 evidence cells populated).
#                 The fix makes evidence-backed closure agent-authorised. This
#                 predicate is the machine-checkable half of the carve-out that
#                 keeps ambiguity on the user's surface: a ticket carrying an
#                 explicit DO-NOT-CLOSE marker must keep blocking closure even
#                 when the evidence would otherwise satisfy the close criterion.
#
# Contract: `is-close-blocked.sh <ticket-ref> [<problems-dir>]` reads the ticket
# body and answers ONE question via its EXIT CODE — is closure explicitly
# blocked by a recorded marker?
#
# Exit codes:
#   0 = BLOCKED — the marker is present. Prints the matching line on stdout.
#   1 = not blocked. No stdout.
#   2 = ticket not found / unreadable ref. No stdout; reason on stderr.
#
# Marker shape (line-anchored, per the ADR-079 advisory-A2 lesson that an
# unanchored pattern produces false positives): the literal `DO NOT CLOSE`
# appearing in a markdown HEADING line or a bold/bullet marker line. A mention
# inside a fenced code block or mid-prose is NOT a marker — those are how
# tickets *discuss* the mechanism, and treating discussion as a block would
# re-strand the queue this predicate exists to let drain.
#
# @adr ADR-049 (bin/ on PATH shim — adopter-safe script resolution)
# @adr ADR-022 (Verifying lifecycle — the V->C transition this guards)
# @adr ADR-044 (framework-resolution boundary — the marker is the recorded
#               signal that routes a close back to the user's surface)
# @adr ADR-026 (agent output grounding — blocked/not-blocked is a field read,
#               not a heuristic the next agent must re-derive)
# @adr ADR-005 (Plugin testing strategy — behavioural bats per P081)
# @jtbd JTBD-006 (Progress Backlog AFK — the loop drains the verification queue
#                 on evidence without closing what the maintainer held back)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/is-close-blocked.sh"
  FIXTURE_DIR="$(mktemp -d)"
  cd "$FIXTURE_DIR"
  mkdir -p docs/problems/verifying docs/problems/known-error
}

teardown() {
  cd /
  rm -rf "$FIXTURE_DIR"
}

# Writes a verifying ticket whose body is $2, at id $1.
write_ticket() {
  local id="$1"
  shift
  printf '# Problem %s: fixture\n\n**Status**: Verification Pending\n\n%s\n' \
    "$id" "$*" > "docs/problems/verifying/${id}-fixture.md"
}

# ── Existence ───────────────────────────────────────────────────────────────

@test "is-close-blocked: script exists" {
  [ -f "$SCRIPT" ]
}

@test "is-close-blocked: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Argument handling ───────────────────────────────────────────────────────

@test "is-close-blocked: no arguments -> exit 2 with usage on stderr" {
  run "$SCRIPT"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qi "usage"
}

@test "is-close-blocked: unknown ticket -> exit 2, no stdout" {
  run "$SCRIPT" 999 docs/problems
  [ "$status" -eq 2 ]
}

# ── The blocking case ───────────────────────────────────────────────────────

@test "is-close-blocked: DO NOT CLOSE in a heading -> exit 0 (blocked)" {
  write_ticket 151 '## Regression / incomplete observed 2026-07-25 — DO NOT CLOSE

- **Finding (regression)**: the fix is incomplete; needs reopen.'
  run "$SCRIPT" 151 docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "DO NOT CLOSE"
}

@test "is-close-blocked: DO NOT CLOSE in a bold bullet -> exit 0 (blocked)" {
  write_ticket 152 '## Fix Released

- **DO NOT CLOSE** — the adopter has not confirmed the second half shipped.'
  run "$SCRIPT" 152 docs/problems
  [ "$status" -eq 0 ]
}

@test "is-close-blocked: DO NOT CLOSE in a bold line at column 0 -> exit 0" {
  write_ticket 153 '## Fix Released

**DO NOT CLOSE** until the regression window closes.'
  run "$SCRIPT" 153 docs/problems
  [ "$status" -eq 0 ]
}

@test "is-close-blocked: accepts a P-prefixed ref" {
  write_ticket 154 '### DO NOT CLOSE — partial fix'
  run "$SCRIPT" P154 docs/problems
  [ "$status" -eq 0 ]
}

@test "is-close-blocked: accepts a direct file path" {
  write_ticket 155 '## DO NOT CLOSE'
  run "$SCRIPT" docs/problems/verifying/155-fixture.md
  [ "$status" -eq 0 ]
}

@test "is-close-blocked: finds the ticket in known-error/ too" {
  printf '# Problem 156: fixture\n\n## DO NOT CLOSE\n' \
    > docs/problems/known-error/156-fixture.md
  run "$SCRIPT" 156 docs/problems
  [ "$status" -eq 0 ]
}

# ── The non-blocking cases — these are what keep the queue drainable ────────

@test "is-close-blocked: ordinary verifying ticket -> exit 1 (not blocked)" {
  write_ticket 200 '## Fix Released

Shipped in v1.2.0. Awaiting verification.'
  run "$SCRIPT" 200 docs/problems
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "is-close-blocked: marker inside a fenced code block is NOT a block" {
  write_ticket 201 '## Fix Released

The predicate matches this heading shape:

```markdown
## Regression observed — DO NOT CLOSE
```

Shipped in v1.2.0.'
  run "$SCRIPT" 201 docs/problems
  [ "$status" -eq 1 ]
}

@test "is-close-blocked: marker mid-prose is NOT a block" {
  write_ticket 202 '## Fix Released

A ticket carrying an explicit DO NOT CLOSE marker keeps blocking closure, so
this ticket documents that rule without invoking it.'
  run "$SCRIPT" 202 docs/problems
  [ "$status" -eq 1 ]
}

@test "is-close-blocked: a heading merely naming the predicate is NOT a block" {
  write_ticket 203 '## Fix Released

Shipped `is-close-blocked.sh`, which detects the do-not-close marker.'
  run "$SCRIPT" 203 docs/problems
  [ "$status" -eq 1 ]
}

@test "is-close-blocked: lowercase 'do not close' in prose is NOT a block" {
  write_ticket 204 '## Fix Released

Reviewers should do not close this until CI is green — sic, kept verbatim.'
  run "$SCRIPT" 204 docs/problems
  [ "$status" -eq 1 ]
}

# ── The real-world shape ────────────────────────────────────────────────────

@test "is-close-blocked: the live P151 marker shape blocks" {
  write_ticket 151 'Adopter-side verification path: install and observe.

## Regression / incomplete observed 2026-07-25 — DO NOT CLOSE

- **Finding (regression)**: adopter shows a missing-file error AFTER the fix.
- **Action**: flip back to Known Error (Bucket 3 — never batch-close).

## Fix Applied 2026-07-25 (residual)'
  run "$SCRIPT" 151 docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Regression / incomplete observed"
}
