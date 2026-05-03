#!/usr/bin/env bats

# tdd-review: structural-permitted (justification: P012 skill testing
#   harness scope is open; no behavioural alternative for SKILL.md prose-
#   template structural assertions today. ADR-052 Migration clause permits
#   structural retrofit-via-justification when the linked harness-gap ticket
#   has not yet shipped the primitives. The whole-file annotation covers all
#   assertions in this fixture, including the P128 `## Versions` schema
#   assertions added 2026-05-03.)
#
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

@test "report-upstream: SKILL.md structured default uses problem-shaped section order (ADR-033 Step 5, amended 2026-05-03 P128)" {
  # Problem-shaped default body per ADR-033 (amended 2026-05-03 by P128):
  # Description -> Symptoms -> Workaround -> Affected plugin / component ->
  # Frequency -> Versions (was Environment pre-amendment) -> Evidence ->
  # Cross-reference. Assert section order in the primary default block.
  #
  # P140 fix-and-continue (Step 6.5 closed allow-list, P081-class stale-grep):
  # iter 16's P128 amendment added a `## Versions` section to the structured
  # default block (~line 293) but TWO other `## Versions` sections coexist —
  # the "Drafted Upstream Report" block (~line 247) and the issue-shaped
  # example block (~line 335). A bare `head -1` picks the earliest match
  # (line 247) and breaks the order assertion `freq_line < versions_line`.
  # Scope the `versions_line` lookup to between `freq_line` and `evidence_line`
  # via awk range so we pick the structured-default block's Versions header.
  # Architect note 2026-05-03: if a second section-name-collides-across-blocks
  # test ever needs the same awk-range scoping, factor a
  # `bats_helpers/section_in_block.bash` helper (P012 / ADR-052 amendment).
  desc_line=$(grep -n '^## Description$' "$SKILL_MD" | head -1 | cut -d: -f1)
  symptoms_line=$(grep -n '^## Symptoms$' "$SKILL_MD" | head -1 | cut -d: -f1)
  workaround_line=$(grep -n '^## Workaround$' "$SKILL_MD" | head -1 | cut -d: -f1)
  affected_line=$(grep -nE '^## Affected plugin' "$SKILL_MD" | head -1 | cut -d: -f1)
  freq_line=$(grep -n '^## Frequency$' "$SKILL_MD" | head -1 | cut -d: -f1)
  evidence_line=$(grep -n '^## Evidence$' "$SKILL_MD" | head -1 | cut -d: -f1)
  xref_line=$(grep -n '^## Cross-reference$' "$SKILL_MD" | head -1 | cut -d: -f1)
  versions_line=$(awk -v lo="${freq_line:-${desc_line:-1}}" -v hi="${evidence_line:-9999}" 'NR>lo && NR<hi && /^## Versions$/{print NR; exit}' "$SKILL_MD")

  [ -n "$desc_line" ] || { echo "missing ## Description"; return 1; }
  [ -n "$symptoms_line" ] || { echo "missing ## Symptoms"; return 1; }
  [ -n "$workaround_line" ] || { echo "missing ## Workaround"; return 1; }
  [ -n "$affected_line" ] || { echo "missing ## Affected plugin / component"; return 1; }
  [ -n "$freq_line" ] || { echo "missing ## Frequency"; return 1; }
  [ -n "$versions_line" ] || { echo "missing ## Versions"; return 1; }
  [ -n "$evidence_line" ] || { echo "missing ## Evidence"; return 1; }
  [ -n "$xref_line" ] || { echo "missing ## Cross-reference"; return 1; }

  [ "$desc_line" -lt "$symptoms_line" ]
  [ "$symptoms_line" -lt "$workaround_line" ]
  [ "$workaround_line" -lt "$affected_line" ]
  [ "$affected_line" -lt "$freq_line" ]
  [ "$freq_line" -lt "$versions_line" ]
  [ "$versions_line" -lt "$evidence_line" ]
  [ "$evidence_line" -lt "$xref_line" ]
}

@test "report-upstream: SKILL.md cites ADR-033 as authority for Steps 3 + 5 (ADR-033 Confirmation)" {
  # ADR-033 must be cited near the Step 3 / Step 5 headings, not only in the
  # References section, so future maintainers see the authority inline.
  run grep -niE 'adr-033|033.*problem-first' "$SKILL_MD"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -ge 2 ]
}

# ─── P070 dedup contract (Step 4b + Step 5c + AFK static heuristic) ────────────
#
# P070 inserts a dedup check between security-path routing (Step 4) and the
# outbound `gh` call (Steps 5 / 6). Two duplication windows close at the same
# insertion point: own re-run (local ticket already has `## Reported Upstream`)
# and third-party search (different reporter filed similar). Step 5c adds a
# comment-on-existing-issue path used when the dedup branch finds a match.
#
# Per architect verdict on P070: the maintainer-annoyance risk evaluator is
# deferred until ADR-028 / P064's `wr-risk-scorer:external-comms` subagent
# ships (ADR-028 line 117 anticipates third evaluators). The interim AFK
# branch uses a static heuristic — no subagent dispatch — that defaults to
# halt-and-save.

@test "report-upstream: SKILL.md contains a Step 4b dedup check (P070)" {
  run grep -nE '^### 4b\.' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md Step 4b.1 detects own-re-run via ## Reported Upstream (P070)" {
  # Own-re-run branch: grep the local ticket for an existing `## Reported
  # Upstream` URL before firing a second upstream report.
  run grep -nE 'Reported Upstream.*(grep|already|existing|previous)' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md Step 4b.2 third-party search uses gh issue list --search (P070)" {
  # Third-party branch: `gh issue list --repo ... --search ...` against the
  # upstream's existing issues. Required tokens.
  run grep -F 'gh issue list' "$SKILL_MD"
  [ "$status" -eq 0 ]
  # `--` before the pattern stops grep from treating `--search` as a flag.
  run grep -F -- '--search' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md Step 4b.2 uses inline LLM judge, not subagent dispatch (P070 Direction decision 2026-04-21)" {
  # Direction decision pins inline LLM check inside the skill's own session.
  # No `wr-itil:dedup-check` subagent dispatch; future promotion is a separate
  # ADR amendment.
  run grep -iE 'inline.*llm|inline semantic|inline.*judge|inline classification' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md contains Step 5c comment path with gh issue comment (P070)" {
  # Step 5c: when dedup match found AND user picks "comment instead", run
  # `gh issue comment <number>` rather than `gh issue create`.
  run grep -nE '^### 5c\.' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'gh issue comment' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md Step 5c records commented-on-existing-issue disclosure path (P070 + ADR-024 amendment)" {
  # ADR-024 amendment extends the disclosure-path enumeration. The literal
  # string MUST appear in the SKILL.md so the ## Reported Upstream back-write
  # records the new path.
  run grep -F 'commented-on-existing-issue' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md AFK branch uses static heuristic, defers maintainer-annoyance evaluator (P070 interim per ADR-028 line 117)" {
  # Architect verdict: maintainer-annoyance evaluator deferred. AFK branch
  # uses a static heuristic and defaults to halt-and-save. The SKILL.md must
  # name the deferral explicitly so future readers know why the static-heuristic
  # path exists; once `wr-risk-scorer:external-comms` lands, this branch
  # gets re-wired.
  run grep -iE 'static heuristic|interim.*heuristic|heuristic.*interim' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'wr-risk-scorer:external-comms|external-comms.*evaluator' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md AFK halt-and-save writes Drafted Upstream Report section (P070 + ADR-024 Consequences)" {
  # AFK halt branch saves the drafted report to the local ticket's
  # `## Drafted Upstream Report` section — same pattern as the security-path
  # halt per ADR-024 Consequences (lines 116, 123).
  run grep -F '## Drafted Upstream Report' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md AFK behaviour summary table includes the dedup branch (P070)" {
  # The "AFK behaviour summary" table at the bottom of the skill must list
  # the new dedup-halt branch alongside the existing public-issue / security
  # / above-appetite branches.
  run grep -iE 'dedup.*halt|step 4b.*halt|halt.*dedup|halt-and-save.*dedup' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ─── P128 consolidated Versions schema (ADR-033 amendment 2026-05-03) ─────────
#
# P128 reshapes Step 5's structured default body: the freeform `## Environment`
# section becomes a labelled `## Versions` section carrying a fixed five-field
# schema. Missing fields render as `not detected` (normative MUST per the
# ADR-033 amendment 2026-05-03). The reshape applies to the problem-shaped
# default AND the bug-shaped fallback default.

@test "report-upstream: SKILL.md problem-shaped default body includes ## Versions section (P128)" {
  # The labelled `## Versions` section MUST appear in the SKILL.md so the
  # structured default emits it. Two occurrences expected: one in the
  # field-mapping table's Versions-schema block, one in the problem-shaped
  # default body, and one in the bug-shaped fallback default body — but the
  # minimum invariant is that the section header exists.
  run grep -F '## Versions' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md ## Versions schema lists all five fields (P128)" {
  # Five-field schema per the ADR-033 amendment 2026-05-03: Local plugin,
  # Upstream package, Claude Code CLI, Node, OS. All five labels must appear
  # in the SKILL.md so the structured default's Versions block emits them.
  run grep -iE '^- Local plugin:' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE '^- Upstream package:' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE '^- Claude Code CLI:' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE '^- Node:' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE '^- OS:' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md documents not-detected rendering rule for missing version fields (P128)" {
  # Normative rendering rule: missing fields render as "not detected".
  # The literal string MUST appear in the SKILL.md so triage distinguishes
  # field-not-applicable from detection-failed.
  run grep -iE '"not detected"|`not detected`' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md cites ADR-033 amendment authority for the Versions schema (P128)" {
  # The Versions schema authority sits in ADR-033's `## Amendments` section
  # dated 2026-05-03. The SKILL.md must cite the amendment so future readers
  # see the authority inline alongside the schema.
  run grep -iE 'ADR-033 amendment|amendment 2026-05-03' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md documents auto-population sources for each Versions field (P128)" {
  # Auto-population sources: package.json / claude plugin list, gh api releases
  # or npm view, claude --version, node --version, uname -srm. The SKILL.md
  # must enumerate the sources so the LLM-driven skill knows where to look.
  run grep -F 'claude --version' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'node --version' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'uname -srm' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'npm view' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md problem-shaped default body no longer uses freeform ## Environment section (P128)" {
  # The problem-shaped default body (lines under "#### Structured default body
  # — problem-shaped (primary, per ADR-033)") MUST NOT contain a `## Environment`
  # section header per the ADR-033 amendment 2026-05-03. The bug-shaped fallback
  # also retired its `## Environment` section. We assert the headers are absent
  # from the SKILL.md (the field-mapping table's reference to `os` field as a
  # template-slot remains, but the top-level section header should be gone).
  run grep -nE '^## Environment$' "$SKILL_MD"
  [ "$status" -ne 0 ]
}
