#!/usr/bin/env bats
# Substance-confirmation interaction pattern at create-adr Step 5
# (P339 + P340 / user direction 2026-05-31).
#
# tdd-review: structural-permitted (justification: SKILL.md prose contract
# assertions for an interaction-pattern that has no behavioural skill-runtime
# harness yet — P012 + P081 Phase 2 bridge window. Will migrate to
# behavioural form once the harness exists. Isomorphic precedent in this
# directory: create-adr-adr-044-contract.bats and
# create-adr-decision-boundary.bats.)
#
# @problem P339 (create-adr Step 5 bundles substance with draft-acceptance)
# @problem P340 (born-confirmed marker writes on draft-acceptance answer)
# @adr ADR-064 (review-and-confirm-every-ADR; amended for 5 interaction-pattern requirements)
# @adr ADR-066 (born-confirmed marker; amended to gate marker on substantive-answer)
# @adr ADR-074 (substance-confirm-before-build framework; create-adr-surface instance)
# @adr ADR-013 (structured user interaction — AskUserQuestion is the surface)
# @adr ADR-052 (behavioural-by-default with structural bridge window)
# @jtbd JTBD-001 (enforce governance without slowing down — primary)
# @jtbd JTBD-202 (run pre-flight governance checks before release or handover)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
  [ -f "$SKILL_FILE" ]
}

# ----------------------------------------------------------------------
# Step 5 substance-confirm fire — separate from draft-quality fire.
# ----------------------------------------------------------------------

@test "SKILL.md Step 5 names a substance-confirm fire distinct from draft-quality review (P339)" {
  # P339 root cause: Step 5 currently fires ONE bundled AskUserQuestion that
  # confounds substance-of-decision (which option was chosen) with
  # draft-quality (is the prose well-written). The amend SHOULD prescribe
  # TWO separate firings: substance-confirm first; draft-quality optional.
  run awk '/^### 5\. /,/^### 6\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"substance-confirm"* ]] || [[ "$output" == *"substance confirm"* ]]
  [[ "$output" == *"draft-quality"* ]] || [[ "$output" == *"draft quality"* ]] || [[ "$output" == *"draft review"* ]]
}

@test "SKILL.md Step 5 prescribes prose briefing in main-turn text BEFORE the substance-confirm AskUserQuestion fires (P340)" {
  # User direction 2026-05-31: long AskUserQuestion text is NOT readable on
  # some devices (mobile clients, accessibility tooling, certain notification
  # surfaces). Long prose + short question IS readable across the full
  # device matrix. The split is load-bearing — the briefing MUST live in
  # main-turn prose, NOT inside AskUserQuestion text.
  run awk '/^### 5\. /,/^### 6\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"main-turn"* ]] || [[ "$output" == *"main turn"* ]] || [[ "$output" == *"prose briefing"* ]]
  [[ "$output" == *"before"* ]] || [[ "$output" == *"BEFORE"* ]]
}

@test "SKILL.md Step 5 prescribes each-considered-option as a selectable option (not yes/no shape) (P340)" {
  # User direction 2026-05-31: the AskUserQuestion MUST NOT be a yes/no
  # shape. It MUST present each considered option as a selectable option in
  # the AskUserQuestion options array. The user picks the substantive
  # direction positively (chooses an option), not by clicking "yes" on a
  # bundled "is this OK?" question.
  run awk '/^### 5\. /,/^### 6\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"selectable option"* ]] || [[ "$output" == *"each considered option"* ]] || [[ "$output" == *"each option"* ]]
  [[ "$output" == *"not yes/no"* ]] || [[ "$output" == *"not a yes/no"* ]] || [[ "$output" == *"NOT yes/no"* ]] || [[ "$output" == *"NOT a yes/no"* ]]
}

@test "SKILL.md Step 5 prescribes no-IDs-as-explainers in briefing prose or option labels (P340)" {
  # User direction 2026-05-31: the briefing prose, the question, and the
  # options MUST NOT use IDs as explainers. The user does NOT have access
  # to those IDs on all devices. Every option's substance MUST be
  # self-contained in the prose + the option label/description.
  run awk '/^### 5\. /,/^### 6\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no IDs as explainers"* ]] || [[ "$output" == *"NOT use IDs"* ]] || [[ "$output" == *"without IDs"* ]] || [[ "$output" == *"no ID"* ]] || [[ "$output" == *"self-contained"* ]]
}

@test "SKILL.md Step 5 prescribes informed-decision-without-external-document-lookup (P340)" {
  # User direction 2026-05-31: the user MUST be able to make an informed
  # decision without looking up other documents. The briefing +
  # AskUserQuestion is a self-contained surface.
  run awk '/^### 5\. /,/^### 6\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"without external"* ]] || [[ "$output" == *"without looking up"* ]] || [[ "$output" == *"self-contained"* ]] || [[ "$output" == *"without document lookup"* ]]
}

# ----------------------------------------------------------------------
# Born-confirmed marker write — gated on substantive-answer.
# ----------------------------------------------------------------------

@test "SKILL.md Step 5 gates born-confirmed marker write on substance-confirm answer specifying a substantive option (P340)" {
  # P340 mechanism fix: the marker MUST be written ONLY in response to an
  # AskUserQuestion answer that selects ONE specific substantive option from
  # the considered-options set. NOT on draft-acceptance / problem-statement-
  # OK / bundled answers.
  run awk '/^### 5\. /,/^### 6\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"human-oversight: confirmed"* ]] || [[ "$output" == *"born-confirmed"* ]] || [[ "$output" == *"oversight marker"* ]]
  [[ "$output" == *"ONLY"* ]] || [[ "$output" == *"only when"* ]] || [[ "$output" == *"only if"* ]]
  [[ "$output" == *"substantive"* ]] || [[ "$output" == *"substance-confirm"* ]] || [[ "$output" == *"considered options"* ]] || [[ "$output" == *"considered-options"* ]]
}

@test "SKILL.md Step 5 prescribes re-draft + re-fire when user picks a different option than the draft authored (P340)" {
  # User direction 2026-05-31: if the substance-confirm answer selects a
  # DIFFERENT option than the one the draft was authored against, the SKILL
  # MUST re-draft Decision Outcome (+ Consequences + Confirmation +
  # Pros and Cons) against the new choice and re-fire substance-confirm.
  # NOT a soft "warn and proceed" — the marker only ever writes when the
  # draft authored matches the user's substantive pick.
  run awk '/^### 5\. /,/^### 6\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  shopt -s nocasematch
  [[ "$output" == *"re-draft"* ]] || [[ "$output" == *"redraft"* ]] || [[ "$output" == *"re-author"* ]]
  [[ "$output" == *"re-fire"* ]] || [[ "$output" == *"refire"* ]] || [[ "$output" == *"re-run"* ]]
  shopt -u nocasematch
}

@test "SKILL.md Step 5 names draft-quality review fire as OPTIONAL and not gating the marker (P340)" {
  # The draft-quality review fire (prose quality, consulted/informed list,
  # edge cases) is a follow-up to the substance-confirm fire. It MUST NOT
  # gate the born-confirmed marker write — that gate sits on the
  # substance-confirm answer alone.
  run awk '/^### 5\. /,/^### 6\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"does NOT gate"* ]] || [[ "$output" == *"does not gate"* ]] || [[ "$output" == *"NOT gate the marker"* ]] || [[ "$output" == *"not gate the marker"* ]]
}

# ----------------------------------------------------------------------
# No-IDs-as-explainers regression guard — Step 5 prose itself MUST NOT
# require the user to look up IDs to understand the prescribed interaction.
# The PRESCRIPTIVE Step 5 prose is allowed to cite IDs as audit-trail
# annotations (ADR-064, ADR-066, ADR-074, P339, P340 etc.), but the
# EXAMPLE briefing the SKILL prescribes for the agent to emit MUST be
# ID-free. This test checks the prescription, not the prose itself.
# ----------------------------------------------------------------------

@test "SKILL.md Step 5 prescribes example briefing shape is ID-free (P340 — load-bearing for device matrix)" {
  # The Step 5 prose MUST explicitly prescribe that the BRIEFING the agent
  # emits (the prose surfacing options + selected option + rationale) is
  # ID-free. This is the prescription, not a check on the SKILL prose
  # itself.
  run awk '/^### 5\. /,/^### 6\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # Must call out at least one banned ID-shape in the prescription so the
  # contract is unambiguous.
  [[ "$output" == *"ADR-"* ]] || [[ "$output" == *"P-NNN"* ]] || [[ "$output" == *"JTBD-"* ]] || [[ "$output" == *"RFC-"* ]] || [[ "$output" == *"identifier"* ]]
}

# ----------------------------------------------------------------------
# Cross-reference to P339 + P340 and ADR-074 for audit trail.
# ----------------------------------------------------------------------

@test "SKILL.md cites P339 + P340 in Step 5 amend prose or Related section (audit trail)" {
  run grep -nE "P339|P340" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites ADR-074 in Step 5 amend prose (substance-confirm-before-build framework)" {
  run grep -nE "ADR-074" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ----------------------------------------------------------------------
# P081 + P132 bridge marker
# ----------------------------------------------------------------------

@test "bats file carries the tdd-review: structural-permitted marker" {
  run grep -nE "tdd-review:[[:space:]]+structural-permitted" "${BATS_TEST_FILENAME}"
  [ "$status" -eq 0 ]
}
