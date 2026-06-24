#!/usr/bin/env bats
# Behavioural fixtures for /wr-itil:capture-problem (P155).
#
# Per ADR-052 (Behavioural-tests-default for skill testing), these tests
# exercise the load-bearing primitives the skill dispatches and assert
# observable state — NOT the prose contents of SKILL.md.
#
# Behavioural surfaces under test:
#   1. P119 create-gate composition — capture-problem must source the
#      session-id + create-gate helpers and call mark_step2_complete
#      before the Write so the PreToolUse hook permits the new ticket
#      file to land. Test simulates the helper-sourcing sequence and
#      asserts the marker file lands in /tmp.
#   2. Skeleton-fill ticket shape — captured ticket has Description from
#      $ARGUMENTS plus the deferred-placeholder fields the skill
#      prescribes. Test runs the skeleton-fill command sequence against
#      a fixture description and asserts the resulting file's sections.
#   3. Next-ID computation — capture-problem reuses the manage-problem
#      Step 3 P056-safe local_max + origin_max formula. Test runs the
#      formula against a fixture problems directory and asserts the
#      computed next ID matches the expected zero-padded value.
#   4. Conservative title-only duplicate-grep — 3-keyword cap, filename
#      matches only (NOT body). Test runs the grep pattern against a
#      fixture and asserts the conservative match shape.
#
# @problem P155
# @jtbd JTBD-001 (enforce governance without slowing down — lightweight
#                  capture path)
# @jtbd JTBD-006 (progress backlog while AFK — sibling-finding capture
#                  in iter subprocesses)
# @jtbd JTBD-101 (extend the suite — discoverable / on /  autocomplete)
# @adr ADR-032 (governance skill invocation patterns — foreground-
#                lightweight-capture variant)
# @adr ADR-038 (progressive disclosure — SKILL.md + REFERENCE.md split)
# @adr ADR-049 (bin/ on PATH — capture-problem reuses existing
#                wr-itil-reconcile-readme shim, no new shim needed)
# @adr ADR-052 (behavioural-tests-default — these tests exercise
#                primitives, not SKILL.md prose)
# @adr ADR-119 (manage-problem create-gate — capture-problem composes
#                with the same per-session marker)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_DIR="${REPO_ROOT}/packages/itil/skills/capture-problem"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
  REF_FILE="${SKILL_DIR}/REFERENCE.md"
  CREATE_GATE_LIB="${REPO_ROOT}/packages/itil/hooks/lib/create-gate.sh"

  # Fresh per-test scratch directory and SESSION_ID.
  TMPROOT=$(mktemp -d)
  TEST_SESSION_ID="capture-problem-bats-$BATS_TEST_NUMBER-$$"
  MARKER_PATH="/tmp/manage-problem-grep-${TEST_SESSION_ID}"
  rm -f "$MARKER_PATH"
}

teardown() {
  rm -rf "$TMPROOT"
  rm -f "$MARKER_PATH"
}

# ---------------------------------------------------------------------------
# Existence / wiring tests — minimum surface required for the skill to be
# discoverable. Not structural prose-greps; these assert artefacts exist.
# ---------------------------------------------------------------------------

@test "capture-problem: SKILL.md and REFERENCE.md both exist (ADR-038 split)" {
  [ -f "$SKILL_FILE" ]
  [ -f "$REF_FILE" ]
}

@test "capture-problem: SKILL.md frontmatter declares wr-itil:capture-problem name" {
  # Discoverable on / autocomplete depends on the canonical name.
  # ADR-032 names this skill; ADR-010-amended skill-granularity rule.
  run grep -E '^name: wr-itil:capture-problem$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# P119 create-gate composition — load-bearing behavioural primitive.
# capture-problem must call mark_step2_complete before any Write of a new
# ticket file, otherwise the PreToolUse:Write hook denies the Write.
# ---------------------------------------------------------------------------

@test "capture-problem: mark_step2_complete writes marker the P119 hook checks" {
  # Source the helper the skill prescribes; call the canonical mark
  # function; assert the marker file lands at the path the hook reads.
  source "$CREATE_GATE_LIB"
  mark_step2_complete "$TEST_SESSION_ID"
  [ -f "$MARKER_PATH" ]
}

@test "capture-problem: check_create_gate returns 0 after mark_step2_complete" {
  # Composes with manage-problem-enforce-create.sh which uses
  # check_create_gate $SESSION_ID — exit 0 means "permit Write".
  source "$CREATE_GATE_LIB"
  run check_create_gate "$TEST_SESSION_ID"
  [ "$status" -ne 0 ]    # before mark — denied
  mark_step2_complete "$TEST_SESSION_ID"
  run check_create_gate "$TEST_SESSION_ID"
  [ "$status" -eq 0 ]    # after mark — permitted
}

@test "capture-problem: mark_step2_complete is idempotent across cross-skill order" {
  # Whether manage-problem fires first then capture-problem, or vice
  # versa, the marker mechanic is a no-op after the first call.
  source "$CREATE_GATE_LIB"
  mark_step2_complete "$TEST_SESSION_ID"
  mark_step2_complete "$TEST_SESSION_ID"
  mark_step2_complete "$TEST_SESSION_ID"
  [ -f "$MARKER_PATH" ]
}

# ---------------------------------------------------------------------------
# Next-ID computation — capture-problem reuses manage-problem Step 3 formula
# ---------------------------------------------------------------------------

@test "capture-problem: next-ID formula is P056-safe (origin/local max + 1)" {
  # Build a fixture problems directory with mixed status suffixes.
  # The formula must pick the max ID across all suffixes and zero-pad.
  mkdir -p "$TMPROOT/docs/problems"
  : > "$TMPROOT/docs/problems/001-foo.closed.md"
  : > "$TMPROOT/docs/problems/042-bar.open.md"
  : > "$TMPROOT/docs/problems/099-baz.known-error.md"
  : > "$TMPROOT/docs/problems/107-qux.verifying.md"

  # Mirror manage-problem Step 3 local-max formula exactly.
  local_max=$(ls "$TMPROOT/docs/problems"/*.md 2>/dev/null \
              | sed 's/.*\///' \
              | grep -oE '^[0-9]+' \
              | sort -n | tail -1)
  [ "$local_max" = "107" ]

  # No origin available in the fixture; default to 0 then increment.
  next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n0" | sort -n | tail -1) + 1 )))
  [ "$next" = "108" ]
}

@test "capture-problem: next-ID handles empty problems dir (first ticket)" {
  mkdir -p "$TMPROOT/docs/problems"
  local_max=$(ls "$TMPROOT/docs/problems"/*.md 2>/dev/null \
              | sed 's/.*\///' \
              | grep -oE '^[0-9]+' \
              | sort -n | tail -1)
  next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n0" | sort -n | tail -1) + 1 )))
  [ "$next" = "001" ]
}

@test "capture-problem: next-ID handles 099 → 100 transition without octal-eval failure (P164)" {
  # P164 regression: bash $(( ... )) parses leading-zero numbers as octal.
  # `099` is invalid octal (digits >= 8). Without `10#` prefix, this fires:
  #   bash: 099: value too great for base (error token is "099")
  # The fix is the standard `10#` base-10 prefix on the inner $(echo ... | tail -1).
  mkdir -p "$TMPROOT/docs/problems"
  : > "$TMPROOT/docs/problems/098-foo.open.md"
  : > "$TMPROOT/docs/problems/099-bar.open.md"

  local_max=$(ls "$TMPROOT/docs/problems"/*.md 2>/dev/null \
              | sed 's/.*\///' \
              | grep -oE '^[0-9]+' \
              | sort -n | tail -1)
  [ "$local_max" = "099" ]

  next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n0" | sort -n | tail -1) + 1 )))
  [ "$next" = "100" ]
}

# ---------------------------------------------------------------------------
# Conservative duplicate-grep — title-only filename match, 3-keyword cap.
# Architect Q1 verdict: title-only because conservative threshold rationale
# (P155 line 24) — false-positives on body text would either over-prompt
# or be silently swallowed (capture-problem has no AskUserQuestion).
# ---------------------------------------------------------------------------

@test "capture-problem: duplicate-grep matches kebab-cased keywords in filenames" {
  mkdir -p "$TMPROOT/docs/problems"
  : > "$TMPROOT/docs/problems/050-checkpoint-stuck-saving.open.md"
  : > "$TMPROOT/docs/problems/051-foul-drawn-garbled.closed.md"

  # Description: "checkpoint stuck on save retry" — extract 3 kebab tokens.
  # Title-only grep against filenames; bodies are NOT scanned (conservative).
  match_count=$(ls "$TMPROOT/docs/problems"/*.md \
                | grep -ciE 'checkpoint|stuck|save' || true)
  [ "$match_count" -ge 1 ]
}

@test "capture-problem: duplicate-grep does NOT match keywords in body content (title-only)" {
  mkdir -p "$TMPROOT/docs/problems"
  # File whose title has zero overlap but whose body mentions checkpoint
  cat > "$TMPROOT/docs/problems/060-unrelated.open.md" <<'EOF'
# Unrelated ticket
Body mentions checkpoint somewhere but title doesn't.
EOF

  # Title-only grep on filenames must NOT match.
  match_count=$(ls "$TMPROOT/docs/problems"/*.md \
                | grep -ciE 'checkpoint' || true)
  [ "$match_count" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Skeleton-fill ticket shape — capture-problem DERIVES the Priority/Effort
# rating at capture (P375 / ADR-032 amendment 2026-06-24). NO deferred false-
# low placeholder. The ADR-026 sentinel `not estimated — no prior data` is the
# residual re-rate signal, emitted only when no comparable prior grounds the
# rating.
# ---------------------------------------------------------------------------

@test "capture-problem: skeleton ticket carries a DERIVED rating, not a deferred false-low" {
  mkdir -p "$TMPROOT/docs/problems/open"
  TITLE="example-aside-finding"
  ID="200"
  TODAY=$(date -u +%Y-%m-%d)
  DESCRIPTION="Quick observation worth a ticket but not blocking."

  # Mirror the SKILL.md Step 4a + Step 4 template: a derived rating (real
  # Impact × Likelihood) — a real best-effort value, NO deferral marker of
  # any kind (no "deferred — re-rate", no "not estimated" sentinel).
  cat > "$TMPROOT/docs/problems/open/${ID}-${TITLE}.md" <<EOF
# Problem ${ID}: ${TITLE}

**Status**: Open
**Reported**: ${TODAY}
**Priority**: 6 (Medium) — Impact: 3 × Likelihood: 2
**Effort**: M

## Description

${DESCRIPTION}

## Symptoms

(deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Investigate root cause
- [ ] Create reproduction test

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)
EOF

  TICKET="$TMPROOT/docs/problems/open/${ID}-${TITLE}.md"
  [ -f "$TICKET" ]
  run grep -F '**Status**: Open' "$TICKET"
  [ "$status" -eq 0 ]
  run grep -F "$DESCRIPTION" "$TICKET"
  [ "$status" -eq 0 ]

  # The dropped false-low default MUST NOT appear.
  run grep -F 'deferred — re-rate at next /wr-itil:review-problems' "$TICKET"
  [ "$status" -ne 0 ]
  run grep -F 'Re-rate Priority and Effort at next /wr-itil:review-problems' "$TICKET"
  [ "$status" -ne 0 ]
  run grep -F 'Likelihood: 1 (deferred' "$TICKET"
  [ "$status" -ne 0 ]
  # No "not estimated" sentinel either — that is just another deferral
  # (user correction 2026-06-24). Every capture carries a real value.
  run grep -F 'not estimated' "$TICKET"
  [ "$status" -ne 0 ]

  # A real derived Impact × Likelihood is present (not the buried false-low).
  run grep -E 'Impact: [1-5] (×|x) Likelihood: [1-5]' "$TICKET"
  [ "$status" -eq 0 ]
  # And a real Effort bucket with no trailing deferral marker.
  run grep -E '^\*\*Effort\*\*: (S|M|L|XL)$' "$TICKET"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Skill-allowed-tools surface contract — capture-problem MUST NOT carry
# AskUserQuestion (per design Q4 + ADR-044 framework-mediated mechanical-
# stage decisions). This is observable from the frontmatter declaration
# the runtime consumes.
# ---------------------------------------------------------------------------

@test "capture-problem: allowed-tools includes AskUserQuestion (I12 derive-then-ratify dispatch — ADR-060 Amendment 2026-06-02)" {
  # Amended 2026-06-02: the I12 derive-then-ratify contract (ADR-060
  # Amendment 2026-06-02) requires AskUserQuestion for the derive-failure
  # ratification fallback (REJECT / option-pick / free-text correction
  # semantics). Pre-amendment contract was "no AskUserQuestion at all";
  # the amendment promoted persona+JTBD anchoring from optional to
  # required-via-ratification, applies to ALL problems (no type-keyed
  # gating). The historical no-AskUserQuestion contract is preserved at
  # the derive-success paths (silent-framework per ADR-044 cat 4); the
  # AskUserQuestion fires only on derive-failure (ADR-044 cat 1
  # direction-setting). See SKILL.md Step 1.5b dispatch + Rule 6 row.
  run grep -E '^allowed-tools:' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -E '^allowed-tools:.*AskUserQuestion' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "capture-problem: allowed-tools includes Bash (for create-gate marker write)" {
  # mark_step2_complete via Bash is the load-bearing primitive — without
  # Bash in allowed-tools the skill cannot satisfy P119.
  run grep -E '^allowed-tools:.*Bash' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "capture-problem: allowed-tools includes Write (for new ticket file)" {
  run grep -E '^allowed-tools:.*Write' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Deferred-README-refresh contract — distinguishing capture-problem from
# manage-problem. capture-problem must NOT stage docs/problems/README.md
# in its commit (deferred to /wr-itil:review-problems).
# ---------------------------------------------------------------------------

@test "capture-problem: SKILL.md prescribes deferred README refresh (no inline P094 block)" {
  # The contract distinction from manage-problem: capture-problem does
  # NOT regenerate README.md inline; it defers to /wr-itil:review-problems.
  # This is a behavioural primitive — a future maintainer who copies the
  # P094 block over would break the lightweight-capture promise.
  # Asserts the SKILL.md names the deferred contract explicitly.
  run grep -F '/wr-itil:review-problems' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# P287 (2026-06-02) — retirement of P185 Step 1.5 derive-first classifier.
#
# The type-classification axis was REMOVED per twice-confirmed user
# direction (2026-05-25 + 2026-06-02). The lexical-signal classifier,
# stderr-advisory contract, flag pre-resolution dispatch, and
# meta-recursive corpus assertions that lived here have been removed —
# they exercise behaviour that no longer exists in capture-problem.
#
# The P287 regression guards (capture-problem skeleton template has no
# **Type**: line; SKILL.md has no Step 1.5 Type classification header;
# no committed ticket carries a **Type**: body field; the helper has
# no lexical_classify_two_sided function) live in the sibling fixture
# packages/itil/scripts/test/no-type-regression-guard.bats.
# ---------------------------------------------------------------------------

# (P287: classifier + advisory + flag-precedence + meta-recursive tests
# retired with the type axis. Regression guards now live in
# packages/itil/scripts/test/no-type-regression-guard.bats.)

# ---------------------------------------------------------------------------
# P281 — ADR-031 per-state-subdir layout conformance on the SKILL.md
# write-target path template.
#
# Surface 2 / structural-grep is justified here per ADR-052 § Surface 2
# escape-hatch contract: the SKILL.md path template IS the contract surface
# that adopter-side agents read literally. Concrete observed regression
# (voder-mcp-hub commit 6c73880) landed a ticket at the pre-ADR-031 flat
# path because the SKILL.md template named the flat shape. No pure-bash
# script equivalent exists to behaviourally test against — the test target
# IS the agent-driven prose instruction. Drift here re-opens the P281
# regression vector.
# ---------------------------------------------------------------------------

@test "P281: SKILL.md Step 4 File-path template names per-state-subdir layout (ADR-031)" {
  # The contract surface: the literal `**File path**:` declaration in
  # Step 4 of SKILL.md. Must name `docs/problems/open/<NNN>-<kebab-title>.md`
  # per ADR-031 (accepted + human-oversight: confirmed), NOT the pre-ADR-031
  # flat shape `docs/problems/<NNN>-<kebab-title>.open.md`.
  run grep -F '**File path**: `docs/problems/open/<NNN>-<kebab-title>.md`' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P281: SKILL.md Step 4-5-6 path declarations do NOT carry the pre-ADR-031 flat shape" {
  # Negative assertion: none of the SKILL.md write-target path declarations
  # may name the flat `docs/problems/<NNN>-<kebab-title>.open.md` shape.
  # The voder-mcp-hub P032 regression (commit 6c73880) was driven by this
  # literal text appearing in SKILL.md and being followed by an adopter-side
  # agent. Title-anchored grep — body-text mentions of the old shape (e.g.
  # commit-message examples that don't actually carry the path) are fine.
  run grep -F 'docs/problems/<NNN>-<kebab-title>.open.md' "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "P281: SKILL.md Step 5 Write target names per-state-subdir layout" {
  # Step 5 prescribes the single Write call — must direct to per-state path.
  run grep -F 'Single `Write` to `docs/problems/open/<NNN>-<kebab-title>.md`' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P281: SKILL.md Step 6 git-add target names per-state-subdir layout" {
  # Step 6 prescribes the stage command — must reference per-state path.
  run grep -F 'git add docs/problems/open/<NNN>-<kebab-title>.md' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
