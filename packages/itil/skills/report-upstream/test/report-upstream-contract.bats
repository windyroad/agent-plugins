#!/usr/bin/env bats

# Doc-lint structural test (Permitted Exception per ADR-005 — structural
# SKILL.md content checks, not behavioural). Mirrors the doc-lint pattern
# established in ADR-011 and ADR-027 Confirmation tests.
#
# Asserts the report-upstream skill's SKILL.md encodes the contract
# documented in ADR-024 Confirmation criterion 2:
# - template discovery step
# - security-path routing with SECURITY.md fallback
# - explicit ban on auto-public-issue for security-classified tickets
# - cross-reference back-write step
# - ADR-024 cross-reference
#
# Plus two architect-required additions surfaced during P055 Part B
# implementation review:
# - ADR-027 Step-0 deferral rationale present
# - ADR-028 voice-tone gate interaction documented

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/report-upstream/SKILL.md"
}

@test "report-upstream: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "report-upstream: SKILL.md documents template discovery via ISSUE_TEMPLATE (ADR-024 Confirmation 2.1)" {
  run grep -F 'ISSUE_TEMPLATE' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md routes via SECURITY.md with explicit fallback (ADR-024 Confirmation 2.2)" {
  run grep -ic 'SECURITY.md' "$SKILL_MD"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "report-upstream: SKILL.md explicitly bans auto-opening a public issue for security-classified tickets (ADR-024 Confirmation 2.3)" {
  run grep -iE 'never .*auto-open .*public issue' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md contains the cross-reference back-write step (ADR-024 Confirmation 2.4)" {
  run grep -F '## Reported Upstream' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md cross-references ADR-024 (ADR-024 Confirmation 2.5)" {
  run grep -F 'ADR-024' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md documents the ADR-027 Step-0 deferral rationale (architect review)" {
  run grep -F 'ADR-027' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'step.?0 deferral|step.?0' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md documents the ADR-028 voice-tone gate interaction (architect review)" {
  run grep -F 'ADR-028' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'voice-tone gate' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md encodes three distinct AFK branches (architect review)" {
  # Public-issue path / Security path with declared channel / Security path
  # halt-and-surface / Above-appetite commit. The "AFK behaviour summary"
  # table is the canonical place; assert its presence.
  run grep -F 'AFK behaviour summary' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ─── ADR-033 problem-first classifier contract (P067) ──────────────────────────
#
# ADR-033 partially supersedes ADR-024 Decision Outcome Steps 3 + 5 with a
# problem-first classifier and a problem-shaped structured default body. The
# following assertions pin the SKILL.md to ADR-033's Confirmation clauses
# (lines 157-164 of the ADR).

@test "report-upstream: SKILL.md cross-references ADR-033 (ADR-033 Confirmation)" {
  run grep -F 'ADR-033' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md Step 3 classifier lists problem-first tokens (ADR-033 Step 3)" {
  # Primary classifier tokens per ADR-033: problem / issue / concern / defect / gap.
  # All five must appear in the SKILL.md classifier narrative.
  for token in problem issue concern defect gap; do
    run grep -iE "\`${token}\`|\"${token}\"|'${token}'|${token} shape|${token}," "$SKILL_MD"
    [ "$status" -eq 0 ] || {
      echo "missing classifier token: $token"
      return 1
    }
  done
}

@test "report-upstream: SKILL.md template-discovery cites problem-report.yml first (ADR-033 Step 3)" {
  # Preference order: problem-report.yml / problem.yml BEFORE bug-report.yml.
  run grep -n 'problem-report.yml' "$SKILL_MD"
  [ "$status" -eq 0 ]
  problem_line=$(grep -n 'problem-report.yml' "$SKILL_MD" | head -1 | cut -d: -f1)
  bug_line=$(grep -n 'bug-report.yml' "$SKILL_MD" | head -1 | cut -d: -f1)
  [ -n "$problem_line" ] && [ -n "$bug_line" ]
  [ "$problem_line" -lt "$bug_line" ]
}

@test "report-upstream: SKILL.md retains bug/feature/question fallbacks (ADR-033 Step 3 backward compat)" {
  # Backward-compat fallbacks must still be documented for upstreams that
  # have not adopted problem-first templates.
  run grep -F 'bug-report.yml' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'feature-request.yml' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'question.yml' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md structured default uses problem-shaped section order (ADR-033 Step 5)" {
  # Problem-shaped default body per ADR-033: Description -> Symptoms ->
  # Workaround -> Affected plugin / component -> Frequency -> Environment
  # -> Evidence -> Cross-reference. Assert section order in the primary
  # default block.
  desc_line=$(grep -n '^## Description$' "$SKILL_MD" | head -1 | cut -d: -f1)
  symptoms_line=$(grep -n '^## Symptoms$' "$SKILL_MD" | head -1 | cut -d: -f1)
  workaround_line=$(grep -n '^## Workaround$' "$SKILL_MD" | head -1 | cut -d: -f1)
  affected_line=$(grep -nE '^## Affected plugin' "$SKILL_MD" | head -1 | cut -d: -f1)
  freq_line=$(grep -n '^## Frequency$' "$SKILL_MD" | head -1 | cut -d: -f1)
  env_line=$(grep -n '^## Environment$' "$SKILL_MD" | head -1 | cut -d: -f1)
  evidence_line=$(grep -n '^## Evidence$' "$SKILL_MD" | head -1 | cut -d: -f1)
  xref_line=$(grep -n '^## Cross-reference$' "$SKILL_MD" | head -1 | cut -d: -f1)

  [ -n "$desc_line" ] || { echo "missing ## Description"; return 1; }
  [ -n "$symptoms_line" ] || { echo "missing ## Symptoms"; return 1; }
  [ -n "$workaround_line" ] || { echo "missing ## Workaround"; return 1; }
  [ -n "$affected_line" ] || { echo "missing ## Affected plugin / component"; return 1; }
  [ -n "$freq_line" ] || { echo "missing ## Frequency"; return 1; }
  [ -n "$env_line" ] || { echo "missing ## Environment"; return 1; }
  [ -n "$evidence_line" ] || { echo "missing ## Evidence"; return 1; }
  [ -n "$xref_line" ] || { echo "missing ## Cross-reference"; return 1; }

  [ "$desc_line" -lt "$symptoms_line" ]
  [ "$symptoms_line" -lt "$workaround_line" ]
  [ "$workaround_line" -lt "$affected_line" ]
  [ "$affected_line" -lt "$freq_line" ]
  [ "$freq_line" -lt "$env_line" ]
  [ "$env_line" -lt "$evidence_line" ]
  [ "$evidence_line" -lt "$xref_line" ]
}

@test "report-upstream: SKILL.md cites ADR-033 as authority for Steps 3 + 5 (ADR-033 Confirmation)" {
  # ADR-033 must be cited near the Step 3 / Step 5 headings, not only in the
  # References section, so future maintainers see the authority inline.
  run grep -niE 'adr-033|033.*problem-first' "$SKILL_MD"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -ge 2 ]
}
