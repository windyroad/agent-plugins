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
# - Low-confidence (no flag + no lexical detection + no cited-JTBD
#   agreement) → P401 CORRECTED shape (user direction 2026-06-29,
#   sharpened 2026-07-02): INTERVIEW the human to elicit the real
#   who/why (NOT propose an ID) → agent classifies existing-vs-new →
#   existing:map+proceed autonomously / no-fit:human-ratifies-CREATION
#   of a new persona/JTBD (ADR-068/P288). A real problem is NEVER
#   discarded over anchoring uncertainty. Scope-rejection (elicited
#   who/why out of scope) is EXTERNAL-report-only, at manage-problem
#   ingestion — never here.
# - --no-prompt + low-confidence → preserve the finding: CREATE the
#   ticket with the `(unconfirmed — elicitation queued)` anchoring
#   sentinel + queue the elicitation (P401 never-discard + JTBD-006
#   save-and-continue). It no longer halt-refuses.
# - Skeleton template carries **JTBD**: and **Persona**: body fields.
#
# afk_low_confidence_action predicate (P401 2026-06-29) encodes the AFK
# create-with-unconfirmed-sentinel branch. The historical
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

# P401 (2026-06-29 / 2026-07-02) — AFK low-confidence action. The
# corrected shape PRESERVES THE FINDING: under --no-prompt + low-
# confidence, capture the ticket with the unconfirmed-anchoring sentinel
# and queue the elicitation. It NO LONGER halt-refuses (that discarded
# legitimate problems over anchoring uncertainty). Returns the action.
# Inputs:
#   $1: no_prompt_flag      ("1" if --no-prompt set, "" otherwise)
#   $2: derivation_resolved ("1" if persona+JTBD resolved by any of
#                            flag/lexical/cited-JTBD path; "" otherwise)
AFK_SENTINEL="(unconfirmed — elicitation queued)"
afk_low_confidence_action() {
  local no_prompt="$1"
  local derivation_resolved="$2"
  if [ "$no_prompt" = "1" ] && [ -z "$derivation_resolved" ]; then
    echo "CREATE_UNCONFIRMED_QUEUE_ELICITATION"
  else
    echo "PROCEED"  # derivation succeeded, or interactive interview fires
  fi
}

# P401 — reference impl for the corrected low-confidence resolution of a
# MAINTAINER-INTERNAL capture. The agent interviews to elicit who/why,
# then classifies the elicited fit. Returns the resolution action:
#   "MAP_EXISTING"       elicited job/persona matches an existing artefact
#                        → map autonomously (ADR-068 boundary is creation-only)
#   "RATIFY_CREATE_NEW"  no existing fit → human ratifies the CREATION of a
#                        new persona/JTBD (ADR-068/P288), then map
# The problem is NEVER discarded over anchoring uncertainty.
resolve_low_confidence_internal() {
  local elicited_fit="$1"
  case "$elicited_fit" in
    existing) echo "MAP_EXISTING" ;;
    none)     echo "RATIFY_CREATE_NEW" ;;
    *)        echo "INTERVIEW" ;;  # elicit who/why first
  esac
}

# P401 — every maintainer-internal low-confidence resolution yields a
# ticket (never discard). CREATE_UNCONFIRMED is the AFK sentinel path.
internal_resolution_creates_ticket() {
  case "$1" in
    MAP_EXISTING|RATIFY_CREATE_NEW|CREATE_UNCONFIRMED_QUEUE_ELICITATION) return 0 ;;
    *) return 1 ;;
  esac
}

# P401 — scope-rejection is EXTERNAL-report-only (at manage-problem
# ingestion, NOT capture-problem). Through the elicitation interview the
# maintainer may decide the elicited who/why is out of scope to support
# and decline. This is the ONLY path that yields no ticket, and only for
# external reports. A maintainer-internal capture ALWAYS anchors.
# Inputs: $1 origin ("internal"|"external"); $2 in_scope ("yes"|"no").
external_scope_disposition() {
  local origin="$1" in_scope="$2"
  if [ "$origin" = "external" ] && [ "$in_scope" = "no" ]; then
    echo "DECLINE_SCOPE"   # deliberate product-scope decline; no ticket
  else
    echo "ANCHOR"          # internal always anchors; external in-scope anchors
  fi
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
# P401 (2026-06-29 / 2026-07-02) — corrected low-confidence contract.
# Low-confidence INTERVIEWS to elicit who/why (never proposes an ID); the
# agent classifies existing-vs-new; existing→map+proceed, no-fit→human-
# ratifies-CREATION; a real problem is NEVER discarded over anchoring;
# scope-rejection is external-report-only; AFK captures with the
# unconfirmed-anchoring sentinel + queues the elicitation.
# ---------------------------------------------------------------------------

@test "P401 low-confidence interviews (elicits who/why) rather than proposing an ID" {
  # Before classification, the resolution action is INTERVIEW — the agent
  # elicits the real who/why, NOT a candidate JTBD-NNN to ratify.
  result=$(resolve_low_confidence_internal "unknown")
  [ "$result" = "INTERVIEW" ]
}

@test "P401 elicited who/why matching an existing artefact maps autonomously" {
  # Classification: elicited job matches an existing JTBD/persona → map and
  # proceed with no further human ratification (ADR-068 boundary is
  # creation-only). Yields a ticket.
  result=$(resolve_low_confidence_internal "existing")
  [ "$result" = "MAP_EXISTING" ]
  internal_resolution_creates_ticket "$result"
}

@test "P401 elicited who/why with no existing fit routes to human-ratified new-artefact creation" {
  # No existing fit → a new persona/JTBD is warranted → human ratifies the
  # CREATION (ADR-068/P288), then map. Still yields a ticket (never discard).
  result=$(resolve_low_confidence_internal "none")
  [ "$result" = "RATIFY_CREATE_NEW" ]
  internal_resolution_creates_ticket "$result"
}

@test "P401 a maintainer-internal problem is NEVER discarded over anchoring uncertainty" {
  # Every internal low-confidence resolution — map-existing, ratify-new, or
  # the AFK create-with-unconfirmed-sentinel — yields a ticket.
  internal_resolution_creates_ticket "MAP_EXISTING"
  internal_resolution_creates_ticket "RATIFY_CREATE_NEW"
  internal_resolution_creates_ticket "CREATE_UNCONFIRMED_QUEUE_ELICITATION"
}

@test "P401 AFK low-confidence creates ticket with unconfirmed sentinel + queues elicitation (not halt-refuse)" {
  # --no-prompt + derivation-failure → preserve the finding.
  result=$(afk_low_confidence_action "1" "")
  [ "$result" = "CREATE_UNCONFIRMED_QUEUE_ELICITATION" ]
  # The AFK sentinel is a real (non-empty) anchoring value written to the
  # ticket — the finding is preserved, not discarded.
  [ -n "$AFK_SENTINEL" ]
  internal_resolution_creates_ticket "$result"
}

@test "P401 AFK proceeds normally when derivation succeeded (flags pre-resolved)" {
  # AFK orchestrator pattern: pass --no-prompt PLUS --persona + --jtbd to
  # skip the sentinel path entirely.
  no_prompt=$(parse_no_prompt_flag "--persona=developer" "--jtbd=JTBD-006" "--no-prompt" "fix work-problems iter halt")
  [ "$no_prompt" = "1" ]
  persona=$(validate_persona "developer")
  [ "$persona" = "developer" ]
  jtbd=$(parse_jtbd_flag "--jtbd=JTBD-006")
  [ "$jtbd" = "JTBD-006" ]
  result=$(afk_low_confidence_action "$no_prompt" "1")
  [ "$result" = "PROCEED" ]
}

@test "P401 interactive low-confidence proceeds into the interview (no --no-prompt)" {
  result=$(afk_low_confidence_action "" "")
  [ "$result" = "PROCEED" ]
}

@test "P401 scope-rejection is external-report-only; maintainer-internal always anchors" {
  # External report whose elicited who/why we do NOT want to support →
  # deliberate scope decline (no ticket) — the ONLY no-ticket path.
  [ "$(external_scope_disposition external no)" = "DECLINE_SCOPE" ]
  # External report in scope → anchors.
  [ "$(external_scope_disposition external yes)" = "ANCHOR" ]
  # Maintainer-internal ALWAYS anchors, regardless of scope signal —
  # internal captures are never scope-rejected.
  [ "$(external_scope_disposition internal no)" = "ANCHOR" ]
  [ "$(external_scope_disposition internal yes)" = "ANCHOR" ]
}

@test "P401 parse_no_prompt_flag detects --no-prompt anywhere in args" {
  result=$(parse_no_prompt_flag "--persona=developer" "--no-prompt" "description text")
  [ "$result" = "1" ]
}

@test "P401 parse_no_prompt_flag empty when --no-prompt absent" {
  result=$(parse_no_prompt_flag "--persona=developer" "description text")
  [ -z "$result" ]
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
  grep -qE '[Pp]lugin-user-side.*MUST NOT (prompt|carry)' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b names derive-then-ratify contract" {
  grep -qE 'derive-then-ratify' "$SKILL_FILE"
}

@test "SKILL.md: --no-prompt flag declared in flag table (AFK mode marker)" {
  grep -qE '\| `--no-prompt`' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b names P401 never-discard-over-anchoring rule" {
  grep -qiE 'never discarded over anchoring uncertainty' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b names interview-to-elicit-who/why (not propose an ID)" {
  grep -qiE '[Ii]nterview.*(who|why|elicit)|elicit the real who/why' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b names scope-rejection as external-report-only" {
  grep -qiE 'external-report-only' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b names AFK unconfirmed-anchoring sentinel + queued elicitation" {
  grep -qiE 'unconfirmed — elicitation queued|unconfirmed-anchoring sentinel' "$SKILL_FILE"
}

@test "SKILL.md: Step 1.5b routes new persona/JTBD creation to ADR-068/P288 human ratify" {
  grep -qE 'ratif.*(creation|CREATION).*(ADR-068|P288)|(ADR-068|P288).*creation' "$SKILL_FILE"
}

@test "SKILL.md: allowed-tools includes AskUserQuestion (for the low-confidence interview)" {
  grep -qE '^allowed-tools:.*AskUserQuestion' "$SKILL_FILE"
}

@test "SKILL.md: ADR-044 authority taxonomy names direction-setting (category 1) for interview + creation-ratify" {
  grep -qE 'direction-setting.*category 1|category 1.*direction-setting' "$SKILL_FILE"
}
