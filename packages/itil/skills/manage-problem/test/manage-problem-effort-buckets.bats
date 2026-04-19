#!/usr/bin/env bats
# Doc-lint guard: manage-problem SKILL.md must define the XL effort bucket
# and require effort re-rating at lifecycle transitions.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document conforms to the
# effort-bucket and re-rating contract introduced by P047.
#
# Cross-reference:
#   P047: docs/problems/047-wsjf-effort-bucket-accuracy-gaps.open.md
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away — finer ranking signal)
#   @jtbd JTBD-101 (Extend the Suite with Clear Patterns — consistent WSJF semantics)
#   @jtbd JTBD-001 (Enforce Governance Without Slowing Down — explicit re-rate audit trail)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md effort table includes an XL bucket with divisor 8" {
  # P047 concern (2): the L bucket is open-ended (>4 hours, no upper bound),
  # so multi-day / multi-week work ranks identically to a 4-hour L task.
  # The XL bucket disambiguates the top end of the effort spectrum.
  run grep -En "^\|\s*XL\s*\|\s*8\s*\|" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md step 7 pre-flight checks effort bucket re-rating" {
  # P047 concern (1): effort is set at problem creation and never re-rated.
  # Step 7 (Open → Known Error transition) must prompt the reviewer to
  # re-evaluate the effort bucket against the now-documented fix strategy.
  # Match tight phrasings that can only appear in the new pre-flight item,
  # not incidental co-occurrences on a summary line.
  run grep -inE "effort bucket (reviewed|re-?rated|re-?assessed|re-?estimated)|re-?(rate|estimate|assess)( the)? effort bucket" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md step 9b requires explicit effort re-estimation with reason" {
  # P047 candidate fix (2): step 9b's effort re-rate is implicit today
  # ("Estimate Effort"). The explicit form ("Re-estimate Effort; if the
  # bucket changed since last review, update the file and note the reason")
  # makes the check unmissable and leaves an audit trail.
  run grep -in "re-estimate effort\|re.estimate effort" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # The note-the-reason phrase must appear near the re-estimate instruction
  run grep -inE "note.*reason|reason.*noted|note the reason" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md XL bucket description names its scope as multi-day / cross-package" {
  # P047 scoping: XL must be unambiguously wider than L. The description
  # should reference multi-day or cross-package to distinguish it from L's
  # "> 4 hours, multiple files, significant change".
  run grep -inE "XL.*(multi.?day|multi-?week|cross-?package|multi-?package)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
