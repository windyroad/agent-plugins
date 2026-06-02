#!/usr/bin/env bats

# R007 paired-capability gap (post-commit 54ecf83 — ADR-060 Amendment
# 2026-06-02 + I12 derive-then-ratify in capture-problem):
#
# The P342 mechanical-stage carve-out at Step 5 iter-prompt authorises
# retro-surfaced recurring class-of-behaviour observations to auto-ticket
# via `/wr-itil:capture-problem`. The new capture-problem contract
# requires AFK callers (iter subprocesses) to pre-resolve persona + JTBD
# via `--no-prompt --persona=<value> --jtbd=JTBD-NNN` flags, OR capture
# halts-with-stderr-directive. The halt stderr is unobservable to the
# AFK user — silent loop-stall.
#
# The fix shape amends the work-problems Step 5 iter-prompt body's P342
# classification taxonomy bullet for "Recurring class-of-behaviour":
#   - Derive persona from iter context; default `developer` on ambiguity.
#   - Validate persona against the enum
#     `{developer | tech-lead | plugin-developer | plugin-user}` before
#     dispatch.
#   - Derive JTBD from iter context. Cite JTBD-006 (AFK-loop-continuity),
#     JTBD-001 (governance), JTBD-101 (plugin-developer).
#   - Dispatch shape:
#       /wr-itil:capture-problem --no-prompt --persona=<derived>
#         --jtbd=<derived> "<description>"
#   - On genuine derive-failure (cannot cleanly resolve, invalid enum):
#     route to outstanding_questions, NOT capture-problem dispatch.
#
# Doc-lint contract assertions per ADR-037 Permitted Exception.
#
# @problem P342 (originating mechanical-stage carve-out)
# @problem P078 (capture-on-correction; sibling caller for the same dispatch)
# @adr ADR-060 Amendment 2026-06-02 (I12 derive-then-ratify)
# @adr ADR-044 (Decision-Delegation Contract — silent-framework cat 4 on
#               derive-success; direction cat 1 on outstanding_questions route)
# @adr ADR-014 (single-commit grain — SKILL + bats + changeset)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — audit-trail outcome:
#                 halt-with-stderr in iter is invisible to AFK user; route to
#                 outstanding_questions or pre-resolve flags to preserve trail)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
}

@test "work-problems R007: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

# ── Dispatch shape: --no-prompt + --persona + --jtbd flags ─────────────────

@test "work-problems R007: iter-prompt dispatch shape names --no-prompt flag" {
  # AFK-mode marker. Without --no-prompt, capture-problem's I12 derive-
  # then-ratify AskUserQuestion fallback could fire inside the iter
  # subprocess where the user is absent.
  run grep -nE '\-\-no-prompt' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt dispatch shape names --persona flag" {
  # Pre-resolves persona to silent-proceed path. Required by capture-
  # problem SKILL.md Step 1.5b silent-framework branch.
  run grep -nE '\-\-persona=' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt dispatch shape names --jtbd flag" {
  # Pre-resolves JTBD-trace to silent-proceed path.
  run grep -nE '\-\-jtbd=' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt cites I12 derive-then-ratify contract authority" {
  # The dispatch contract's upstream authority is ADR-060 Amendment
  # 2026-06-02 + I12 derive-then-ratify. Cite so future authors don't
  # drift on the rationale.
  run grep -nE 'I12 derive-then-ratify|derive-then-ratify.*ADR-060|ADR-060 Amendment 2026-06-02' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt cites R007 paired-capability gap" {
  # R007 names the gap this amendment closes. Cited so the iter-prompt
  # ties back to the originating risk-register entry.
  run grep -nE 'R007.*paired-capability|paired-capability.*R007|R007 paired-capability gap' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Persona derivation contract ────────────────────────────────────────────

@test "work-problems R007: iter-prompt derives persona from iter context" {
  # Derive-don't-ask: persona signals come from the ticket the iter
  # is dispatched against (Origin + RFC + story trace).
  run grep -nE 'derive persona|Persona derivation' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt defaults persona to developer on ambiguity" {
  # Default chosen per JTBD-006 + dominant-persona in this monorepo.
  run grep -nE 'Default to .?developer.?|default to .?developer.? if|default to .?developer.? when' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt names the persona enum for pre-dispatch validation" {
  # capture-problem halts-with-directive on invalid --persona= value
  # (SKILL.md Step 1.5b). Iter must validate against the enum BEFORE
  # dispatch, or fall through to outstanding_questions.
  run grep -nE 'developer.*tech-lead.*plugin-developer.*plugin-user|persona enum' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── JTBD derivation contract ───────────────────────────────────────────────

@test "work-problems R007: iter-prompt derives JTBD from iter context" {
  # Derive-don't-ask: JTBD signals come from iter-prompt content.
  run grep -nE 'derive.*JTBD|JTBD derivation' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt cites JTBD-006 for AFK-loop-continuity contexts" {
  run grep -nE 'JTBD-006.*AFK|AFK.*JTBD-006|JTBD-006.*loop-continuity|JTBD-006.*iter-dispatch' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt cites JTBD-001 for governance contexts" {
  run grep -nE 'JTBD-001.*governance|governance.*JTBD-001|JTBD-001.*ADR|JTBD-001.*decision' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt cites JTBD-101 for plugin-developer contexts" {
  run grep -nE 'JTBD-101.*plugin|plugin.*JTBD-101|JTBD-101.*discoverability|JTBD-101.*suite-extension' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Fall-through to outstanding_questions on derive-failure ────────────────

@test "work-problems R007: iter-prompt routes genuinely-ambiguous derivation to outstanding_questions" {
  # Architect AMEND closed: when derivation cannot cleanly resolve (or
  # persona fails enum validation), do NOT invoke capture-problem with
  # a bad value (would halt-with-stderr-directive into unobservable iter
  # subprocess stderr); instead, queue for orchestrator main-turn Step
  # 2.5 surfacing.
  run grep -nE 'Genuinely-ambiguous|cannot pick persona/JTBD cleanly|fall through to .?outstanding_questions' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: iter-prompt names the unobservable-stderr failure mode" {
  # Documents WHY the dispatch contract matters: the halt stderr does
  # not surface to the AFK user; the loop silently stalls. JTBD-006
  # audit-trail violation framing.
  run grep -nE 'stderr is unobservable|unobservable.*stderr|silent loop-stall|halt stderr' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Composition with the existing P342 carve-out ───────────────────────────

@test "work-problems R007: amendment preserves the P342 mechanical-stage carve-out framing" {
  # The R007 fix is ADDITIVE — it carries the new dispatch shape into
  # the existing Recurring-class auto-ticket bullet. The P342 carve-out
  # itself (mechanical-stage / Step 4a precedent / ADR-013 Rule 5)
  # remains the authority for auto-ticketing at all.
  run grep -nE 'mechanical-stage carve-out|policy-authorised silent proceed' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems R007: Ambiguous bullet reuses the persona+JTBD derivation contract" {
  # The Ambiguous-classification default-to-auto-ticket path also goes
  # through the new dispatch contract (same flag-resolution discipline);
  # otherwise the Ambiguous branch becomes a halt vector.
  run grep -nE 'same persona \+ JTBD derivation contract|using the same persona \+ JTBD derivation' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
