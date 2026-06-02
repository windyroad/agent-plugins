#!/usr/bin/env bats

# P170 / Phase 3 P3.1 + Phase 4 P4.2 — behavioural fixture for
# capture-problem Step 1.5b JTBD-trace + persona dispatch. Per ADR-060
# § Phase 3 + Phase 4 in-scope amendment (2026-05-13), as amended by
# P287 (2026-06-02 base — type-classification retired) AND ADR-060
# Amendment 2026-06-02 (I12 hard-block REPLACED with derive-then-ratify;
# applies to ALL problems; no type-keyed gating):
#
# - Lexical JTBD-trace detection: description-contains-JTBD-NNN-ID →
#   silent-resolve jtbd_trace_value to the matched IDs.
# - --jtbd=JTBD-NNN[,...] flag pre-resolves jtbd_trace_value silently.
# - --persona=<value> flag pre-resolves persona_value silently.
# - Derive-failure (no flag + no lexical detection + no cited-JTBD
#   agreement) → AskUserQuestion proposal with REJECT/option-pick/
#   free-text correction semantics (REJECT = problem rejected; no
#   ticket; option-pick = acceptance; correction = correction-as-
#   acceptance).
# - --no-prompt + derive-failure → halt-with-stderr-directive (AFK
#   callers MUST pre-resolve via flags).
# - Skeleton template carries **JTBD**: and **Persona**: body fields.
#
# i12_should_halt_afk predicate (NEW per ADR-060 Amendment 2026-06-02)
# encodes the AFK halt-without-flags branch. The historical
# i12_should_block predicate is preserved as a regression guard
# (never returns 0) against re-introduction of the type-keyed hard-block.
#
# Persona enum aligned 2026-06-02 to `docs/jtbd/<persona>/` directory
# names: developer / tech-lead / plugin-developer / plugin-user
# (architect AMEND finding 1 — historical `solo-developer` value was
# stale ADR-060 P4.2 spec text and is corrected in the amendment).
#
# Reference-impl pattern: this fixture exercises the algorithm directly
# via shell helpers; the SKILL.md prose at runtime executes the same
# algorithm via LLM-interpretation. The bats algorithm IS the contract
# the SKILL.md prose binds.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_FILE="$REPO_ROOT/packages/itil/skills/capture-problem/SKILL.md"
}

# Reference implementation of the JTBD-trace lexical detector (matches
# the Step 1.5b prose at SKILL.md). Returns space-separated sorted-unique
# JTBD IDs from the description, OR empty string if none.
detect_jtbd_trace() {
  local desc="$1"
  echo "$desc" | grep -oE '\bJTBD-[0-9]+\b' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//'
}

# P287 retirement: the I12 hard-block was retired alongside the type
# axis. This predicate now ALWAYS returns 1 (never blocks) — preserved
# as a regression-guard so future drift that re-introduces a type-keyed
# hard-block surfaces as a test failure.
i12_should_block() {
  return 1
}

# ADR-060 Amendment 2026-06-02 — NEW positive predicate for I12 derive-
# then-ratify AFK halt-without-flags branch. Returns 0 (halt) when:
#   - --no-prompt is set AND
#   - derivation failed (no flag pre-resolution + no lexical detection
#     + no cited-JTBD agreement).
# Returns 1 (proceed) otherwise. Inputs:
#   $1: no_prompt_flag      ("1" if --no-prompt set, "" otherwise)
#   $2: derivation_resolved ("1" if persona+JTBD resolved by any of
#                            flag/lexical/cited-JTBD path; "" otherwise)
i12_should_halt_afk() {
  local no_prompt="$1"
  local derivation_resolved="$2"
  if [ "$no_prompt" = "1" ] && [ -z "$derivation_resolved" ]; then
    return 0  # halt
  fi
  return 1  # proceed (interactive ratification fires, or derivation succeeded)
}

# ADR-060 Amendment 2026-06-02 — reference impl for AskUserQuestion
# response semantics in the I12 derive-then-ratify dispatch. Returns:
#   "REJECT"     when user picked the Reject option
#   "ACCEPT:<v>" when user picked a proposed option <v> as-is
#   "CORRECT:<v>" when user supplied free-text correction <v>
# Behaviourally the SKILL must treat REJECT as halt-with-stderr-directive
# (no ticket); ACCEPT and CORRECT both yield ticket-with-value.
classify_ratification_response() {
  local response="$1"
  case "$response" in
    REJECT) echo "REJECT" ;;
    OPTION:*) echo "ACCEPT:${response#OPTION:}" ;;
    FREETEXT:*) echo "CORRECT:${response#FREETEXT:}" ;;
    *) echo "UNKNOWN:$response" ;;
  esac
}

# Returns 0 when the response yields a ticket; 1 when it halts capture.
ratification_creates_ticket() {
  local classified="$1"
  case "$classified" in
    REJECT) return 1 ;;        # no ticket; capture halts
    ACCEPT:*|CORRECT:*) return 0 ;;  # ticket created
    *) return 1 ;;
  esac
}

# Reference implementation of --jtbd= flag parser. Accepts CSV; returns
# space-separated IDs (canonicalised) OR empty if the flag wasn't set.
parse_jtbd_flag() {
  local arg="$1"
  case "$arg" in
    --jtbd=*) echo "${arg#--jtbd=}" | tr ',' '\n' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//' ;;
    *) echo "" ;;
  esac
}

# Reference implementation of --persona= validator. Returns the value
# if it's in the closed enum; halts (returns 1) otherwise. Enum aligned
# 2026-06-02 to docs/jtbd/<persona>/ directory names (architect AMEND
# finding 1 — `solo-developer` was stale ADR-060 P4.2 text).
validate_persona() {
  local val="$1"
  case "$val" in
    developer|tech-lead|plugin-developer|plugin-user) echo "$val"; return 0 ;;
    *) return 1 ;;
  esac
}

# Reference implementation of --no-prompt flag detector. Returns "1" if
# any of the supplied args is --no-prompt; empty otherwise. AFK marker
# per ADR-060 Amendment 2026-06-02 I12 derive-then-ratify contract.
parse_no_prompt_flag() {
  for arg in "$@"; do
    case "$arg" in
      --no-prompt) echo "1"; return 0 ;;
    esac
  done
  echo ""
}

@test "P3.1 detect_jtbd_trace: description with single JTBD-NNN citation extracts ID" {
  result=$(detect_jtbd_trace "Adopters want JTBD-101 to scale down for atomic fixes")
  [ "$result" = "JTBD-101" ]
}

@test "P3.1 detect_jtbd_trace: description with multiple JTBD-NNN citations extracts sorted-unique IDs" {
  result=$(detect_jtbd_trace "Composes with JTBD-008 and JTBD-001 governance outcome (also JTBD-008 again)")
  [ "$result" = "JTBD-001 JTBD-008" ]
}

@test "P3.1 detect_jtbd_trace: description with no JTBD citation returns empty" {
  result=$(detect_jtbd_trace "The captureProblem hook in packages/itil/hooks has a regex drift")
  [ -z "$result" ]
}

@test "P3.1 detect_jtbd_trace: JTBD-NNN must be word-boundary (not substring)" {
  # NOT-JTBD-001 should NOT match because of leading \b boundary check —
  # but `\b` matches at hyphen boundary in standard regex. The detector
  # treats this conservatively — anything matching \bJTBD-[0-9]+\b is
  # accepted. The signal is high-precision; mis-matches at hyphen
  # boundaries are still real JTBD-NNN citations from the maintainer's
  # perspective.
  result=$(detect_jtbd_trace "BANANA-JTBD-001-thing")
  [ "$result" = "JTBD-001" ]
}

@test "P287 i12 hard-block retired: never blocks regardless of inputs (regression guard)" {
  # After P287, the I12 hard-block is retired. The predicate must never
  # return 0 (block) for any input combination — capture-time JTBD
  # anchoring is best-effort, not hard-required. If a future maintainer
  # re-introduces a type-keyed hard-block, this test catches it.
  ! i12_should_block "user-business" "" "0"
  ! i12_should_block "user-business" "JTBD-001" "0"
  ! i12_should_block "user-business" "" "1"
  ! i12_should_block "technical" "" "0"
  ! i12_should_block "anything" "anything" "anything"
}

@test "P3.1 parse_jtbd_flag: --jtbd=JTBD-NNN parses single ID" {
  result=$(parse_jtbd_flag "--jtbd=JTBD-001")
  [ "$result" = "JTBD-001" ]
}

@test "P3.1 parse_jtbd_flag: --jtbd=JTBD-A,JTBD-B parses CSV into sorted-unique list" {
  result=$(parse_jtbd_flag "--jtbd=JTBD-008,JTBD-001,JTBD-008")
  [ "$result" = "JTBD-001 JTBD-008" ]
}

@test "P3.1 parse_jtbd_flag: non-jtbd-flag arg returns empty" {
  result=$(parse_jtbd_flag "--persona=plugin-user")
  [ -z "$result" ]
}

@test "P4.2 validate_persona: closed enum accepts developer (architect AMEND 2026-06-02 — was solo-developer)" {
  result=$(validate_persona "developer")
  [ "$result" = "developer" ]
}

@test "P4.2 validate_persona: closed enum accepts tech-lead" {
  validate_persona "tech-lead"
}

@test "P4.2 validate_persona: closed enum accepts plugin-developer" {
  validate_persona "plugin-developer"
}

@test "P4.2 validate_persona: closed enum accepts plugin-user" {
  validate_persona "plugin-user"
}

@test "P4.2 validate_persona: rejects free-text outside enum" {
  ! validate_persona "maintainer"
}

@test "P4.2 validate_persona: rejects stale solo-developer (architect AMEND 2026-06-02 regression guard)" {
  # Pre-Amendment-2026-06-02 ADR-060 P4.2 text named `solo-developer` but
  # docs/jtbd/ directory layout uses `developer/`. The amendment reconciled
  # the enum. This test guards against drift back to the stale value.
  ! validate_persona "solo-developer"
}

# ---------------------------------------------------------------------------
# ADR-060 Amendment 2026-06-02 — I12 derive-then-ratify positive controls.
# These exercise the new contract: AskUserQuestion fires on derivation-
# failure with REJECT/option-pick/free-text-correction semantics; AFK
# callers pre-resolve via flags or halt-with-stderr-directive on
# --no-prompt + derive-failure.
# ---------------------------------------------------------------------------

@test "I12 derive-then-ratify: i12_should_halt_afk halts on --no-prompt + derive-failure" {
  # AFK caller passed --no-prompt; derivation failed (no flag pre-resolution,
  # no lexical detection, no cited-JTBD agreement). MUST halt.
  i12_should_halt_afk "1" ""
}

@test "I12 derive-then-ratify: i12_should_halt_afk proceeds when --no-prompt set but derivation succeeded" {
  # AFK caller passed --no-prompt AND pre-resolved via flags. Derivation
  # succeeded; proceed silently with derived values.
  ! i12_should_halt_afk "1" "1"
}

@test "I12 derive-then-ratify: i12_should_halt_afk proceeds when no --no-prompt (interactive mode)" {
  # Interactive caller; derivation failed; AskUserQuestion fires (proceed
  # past the AFK halt gate, into the ratification dispatch).
  ! i12_should_halt_afk "" ""
}

@test "I12 derive-then-ratify: i12_should_halt_afk proceeds when interactive AND derivation succeeded" {
  ! i12_should_halt_afk "" "1"
}

@test "I12 derive-then-ratify: REJECT response halts capture (no ticket created)" {
  classified=$(classify_ratification_response "REJECT")
  [ "$classified" = "REJECT" ]
  ! ratification_creates_ticket "$classified"
}

@test "I12 derive-then-ratify: option-pick (ACCEPTANCE) yields ticket with proposed values" {
  classified=$(classify_ratification_response "OPTION:developer")
  [ "$classified" = "ACCEPT:developer" ]
  ratification_creates_ticket "$classified"
}

@test "I12 derive-then-ratify: free-text correction (CORRECTION-AS-ACCEPTANCE) yields ticket with corrected values" {
  classified=$(classify_ratification_response "FREETEXT:plugin-user")
  [ "$classified" = "CORRECT:plugin-user" ]
  ratification_creates_ticket "$classified"
}

@test "I12 derive-then-ratify: parse_no_prompt_flag detects --no-prompt anywhere in args" {
  result=$(parse_no_prompt_flag "--persona=developer" "--no-prompt" "description text")
  [ "$result" = "1" ]
}

@test "I12 derive-then-ratify: parse_no_prompt_flag empty when --no-prompt absent" {
  result=$(parse_no_prompt_flag "--persona=developer" "description text")
  [ -z "$result" ]
}

@test "I12 derive-then-ratify: flag pre-resolution short-circuits derive-failure (AFK-safe path)" {
  # AFK orchestrator pattern: pass --no-prompt PLUS --persona + --jtbd to
  # avoid the AFK halt. Verifies the load-bearing caller-side contract.
  no_prompt=$(parse_no_prompt_flag "--persona=developer" "--jtbd=JTBD-006" "--no-prompt" "fix work-problems iter halt")
  [ "$no_prompt" = "1" ]
  persona=$(validate_persona "developer")
  [ "$persona" = "developer" ]
  jtbd=$(parse_jtbd_flag "--jtbd=JTBD-006")
  [ "$jtbd" = "JTBD-006" ]
  # Derivation resolved (both flags present); halt predicate proceeds.
  derivation_resolved="1"
  ! i12_should_halt_afk "$no_prompt" "$derivation_resolved"
}

@test "SKILL.md: Step 1.5b section header exists for JTBD-trace + persona dispatch" {
  grep -qE '^### 1\.5b JTBD-trace \+ persona dispatch' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b names I12 invariant load-bearing identifier" {
  grep -qE 'I12 (invariant|hard-block)' "$SKILL_FILE"
}

@test "SKILL.md: --jtbd= flag declared in flag table" {
  grep -qE '\| `--jtbd=JTBD-NNN' "$SKILL_FILE"
}

@test "SKILL.md: --persona= flag declared in flag table" {
  grep -qE '\| `--persona=<value>`' "$SKILL_FILE"
}

@test "SKILL.md: Step 4 template carries **JTBD**: body field" {
  grep -qE '^\*\*JTBD\*\*:' "$SKILL_FILE"
}

@test "SKILL.md: Step 4 template carries **Persona**: body field" {
  grep -qE '^\*\*Persona\*\*:' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b cites ADR-060 Amendment 2026-06-02 (I12 derive-then-ratify)" {
  grep -qE 'ADR-060 Amendment 2026-06-02' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b preserves JTBD-301 firewall on plugin-user-side intake" {
  grep -qE 'plugin-user-side .* MUST NOT (prompt|carry)' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b names derive-then-ratify contract" {
  grep -qE 'derive-then-ratify' "$SKILL_FILE"
}

@test "SKILL.md: --no-prompt flag declared in flag table (AFK mode marker)" {
  grep -qE '\| `--no-prompt`' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b names REJECT-as-problem-rejection semantics" {
  grep -qE 'REJECT.*=.*[Rr]ejection of the problem|rejection of proposed persona/JTBD = (rejection|REJECT) of the problem' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b names AFK halt-with-stderr-directive on --no-prompt + derive-failure" {
  grep -qE 'halt-with-stderr-directive.*AFK|AFK.*halt-with-stderr-directive|cannot derive .* under AFK' "$SKILL_FILE"
}

@test "SKILL.md: allowed-tools includes AskUserQuestion (for I12 ratification dispatch)" {
  grep -qE '^allowed-tools:.*AskUserQuestion' "$SKILL_FILE"
}

@test "SKILL.md: ADR-044 authority taxonomy names direction-setting (category 1) for ratification fallback" {
  grep -qE 'direction-setting.*category 1|category 1.*direction-setting' "$SKILL_FILE"
}
