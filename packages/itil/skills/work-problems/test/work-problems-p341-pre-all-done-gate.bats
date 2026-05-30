#!/usr/bin/env bats

# P341: work-problems SKILL must surface outstanding questions THEN run
# a session-level retro BEFORE emitting ALL_DONE. The fix shape adds a
# new step (Step 2.4 — Pre-ALL_DONE gate sequence) that fires
# UNCONDITIONALLY before ALL_DONE emit, sequencing (a) outstanding-
# questions surface + (b) session-level retro + (c) ALL_DONE.
#
# Hard-fail mode: if either gate cannot complete (user not present and
# queue has user-input-required entries, retro fails), the SKILL.md MUST
# direct the orchestrator to halt with a clear directive — NOT emit
# ALL_DONE.
#
# Doc-lint contract assertions per ADR-037 Permitted Exception
# (structural checks on prose contract; behavioural harness for SKILL.md
# pending P081 Phase 2 / P012).
#
# @problem P341
# @adr ADR-044 (Decision-Delegation Contract — direction-class observations are the protected surface this gate enforces)
# @adr ADR-013 (structured user interaction — outstanding-questions surface is the load-bearing application)
# @adr ADR-014 (governance skills commit own work — retro commits its own work)
# @adr ADR-037 (skill-testing-strategy — Permitted Exception for prose contract)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away)
# @jtbd JTBD-201 (audit-trail — ALL_DONE is honest sentinel post-amendment)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
}

@test "work-problems P341: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

# ── Step 2.4 (or named equivalent) gate-sequence subsection presence ────────

@test "work-problems P341: SKILL.md names a Pre-ALL_DONE gate sequence step" {
  # The fix adds a new orchestrator-main-turn step that fires
  # UNCONDITIONALLY before ALL_DONE emit. The step MUST be a markdown
  # heading so cross-references resolve to a single source of truth.
  run grep -nE '^#{3,4} Step 2\.4|Pre-`?ALL_DONE`? gate sequence' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P341: gate-sequence step is unconditional (fires before every ALL_DONE emit)" {
  # The structural gap P341 closes is that Step 2.5 fires conditionally
  # on stop-condition #2. The new step fires UNCONDITIONALLY before
  # ALL_DONE emit regardless of stop-condition.
  run grep -nE 'unconditionally|UNCONDITIONAL|every `?ALL_DONE`? emit|before every `?ALL_DONE`?' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P341: gate-sequence names outstanding-questions surface as gate (a)" {
  # Sequence (a): Read .afk-run-state/outstanding-questions.jsonl; if
  # non-empty, fire Step 2.5b's surfacing routine; truncate on completion.
  run grep -nE 'outstanding-questions\.jsonl|outstanding-questions surface|Step 2\.5b.*surfacing' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P341: gate-sequence names session-level retro as gate (b)" {
  # Sequence (b): Run session-level retro via /wr-retrospective:run-retro
  # — covers cross-iter patterns, friction observations, framework-
  # improvement candidates. Retro commits its own work per ADR-014.
  run grep -nE 'session-level retro|/wr-retrospective:run-retro' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P341: gate-sequence names ALL_DONE emit as gate (c) ONLY after (a) and (b)" {
  # Sequence (c): Emit ALL_DONE ONLY after both (a) and (b) complete.
  # The ordering must be explicit so future authors don't re-permit a
  # short-circuit.
  run grep -nE 'ALL_DONE.*after.*both|ONLY after.*(a).*(b)|Emit `?ALL_DONE`? ONLY' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Hard-fail mode (halt instead of ALL_DONE) ──────────────────────────────

@test "work-problems P341: gate-sequence directs halt-with-directive when either gate cannot complete" {
  # Hard-fail mode: if outstanding-questions surface cannot complete OR
  # retro fails, the SKILL.md MUST direct the orchestrator to halt with a
  # clear directive — NOT emit ALL_DONE. Halt is recoverable; user
  # returns, surfaces, completes the loop with ALL_DONE.
  run grep -nE 'halt with.*directive|MUST.*halt.*NOT emit|halt instead of.*ALL_DONE|halt.*not.*ALL_DONE' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P341: gate-sequence mentions ADR-014 commit-ownership for retro work" {
  # Retro commits its own work per ADR-014 — the orchestrator MUST NOT
  # re-commit retro's output, AND retro is not silently dropped because
  # the orchestrator forgot to invoke it.
  run grep -nE 'retro commits its own work|run-retro.*ADR-014|retro.*per ADR-014' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Output Format ALL_DONE positioning ──────────────────────────────────────

@test "work-problems P341: Output Format section reflects new ALL_DONE sequence" {
  # The Output Format section MUST reference the gate sequence so the
  # rendered ALL_DONE position is documented to follow Step 2.4. This
  # protects against future authors who add new sections between the
  # gate sequence and the ALL_DONE marker.
  run grep -nE 'Step 2\.4|gate sequence|Pre-`?ALL_DONE`? gate' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Decision Table row (cross-reference to gate sequence) ───────────────────

@test "work-problems P341: Non-Interactive Decision Making table carries a pre-ALL_DONE gate row" {
  # The decisions table at the bottom of SKILL.md must carry a row that
  # names the pre-ALL_DONE gate sequence so the decision summary is
  # consistent with the Step prose. This prevents future readers from
  # missing the gate when scanning the decisions table only.
  run grep -nE '\| Pre-`?ALL_DONE`? gate|\| ALL_DONE.*gate sequence|\| Loop-end.*gate sequence' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Cross-reference to P341 + sibling P342 ──────────────────────────────────

@test "work-problems P341: Related section cites P341 as the originating ticket" {
  run grep -nE '\*\*P341\*\*|P341\b' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
