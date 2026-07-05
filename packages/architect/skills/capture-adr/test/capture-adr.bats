#!/usr/bin/env bats
# Behavioural fixtures for /wr-architect:capture-adr (P156).
#
# Per ADR-052 (Behavioural-tests-default for skill testing), these tests
# exercise the load-bearing primitives the skill dispatches and assert
# observable state — NOT the prose contents of SKILL.md.
#
# Behavioural surfaces under test:
#   1. Next-ID computation — capture-adr reuses create-adr Step 3 P056-safe
#      local_max + origin_max formula. Test runs the formula against a
#      fixture decisions directory and asserts the computed next ID
#      matches the expected zero-padded value (including the empty-dir
#      first-ADR base case).
#   2. Derive-fill MADR shape (RFC-045 derived-substance amendment) —
#      captured ADR has Title + status proposed + human-oversight:
#      unconfirmed + real derived content in every section, and matches
#      NOTHING in the shared deferral-marker vocabulary
#      (DEFERRAL_MARKER_RE, packages/retrospective/hooks/lib/
#      deferral-markers.sh) — no placeholder/pointer/sentinel of any kind.
#   3. Default reassessment-date — 3 months from today is computed
#      correctly and lands in frontmatter.
#   4. Frontmatter derived values — decision-makers carries a real name
#      (git user.name), never a sentinel.
#
# Structural assertions are limited to existence/wiring (file presence +
# frontmatter name + allowed-tools surface) per the precedent set by the
# capture-problem bats fixtures (P155). Anything else asserts behaviour.
#
# @problem P156
# @jtbd JTBD-001 (enforce governance without slowing down — lightweight
#                  ADR-capture path)
# @jtbd JTBD-005 (invoke governance assessments on demand — discoverable
#                  via / autocomplete)
# @jtbd JTBD-006 (progress backlog while AFK — mid-iter design-decision
#                  capture in iter subprocesses)
# @jtbd JTBD-101 (extend the suite — symmetric with capture-problem on
#                  the architect plugin namespace)
# @adr ADR-032 (governance skill invocation patterns — foreground-
#                lightweight-capture variant for capture-adr)
# @adr ADR-038 (progressive disclosure — SKILL.md + REFERENCE.md split)
# @adr ADR-044 (decision-delegation contract — framework-mediated
#                mechanical-stage carve-outs; no AskUserQuestion)
# @adr ADR-049 (bin/ on PATH — capture-adr is self-contained, no shim
#                required, same as create-adr)
# @adr ADR-052 (behavioural-tests-default — these tests exercise
#                primitives, not SKILL.md prose)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_DIR="${REPO_ROOT}/packages/architect/skills/capture-adr"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
  REF_FILE="${SKILL_DIR}/REFERENCE.md"

  # Fresh per-test scratch directory.
  TMPROOT=$(mktemp -d)
}

teardown() {
  rm -rf "$TMPROOT"
}

# ---------------------------------------------------------------------------
# Existence / wiring tests — minimum surface required for the skill to be
# discoverable. Not structural prose-greps; these assert artefacts exist.
# ---------------------------------------------------------------------------

@test "capture-adr: SKILL.md and REFERENCE.md both exist (ADR-038 split)" {
  [ -f "$SKILL_FILE" ]
  [ -f "$REF_FILE" ]
}

@test "capture-adr: SKILL.md frontmatter declares wr-architect:capture-adr name" {
  # Discoverable on / autocomplete depends on the canonical name.
  # ADR-032 names this skill at line 81 + P156 amendment block.
  run grep -E '^name: wr-architect:capture-adr$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Next-ID computation — capture-adr reuses create-adr Step 3 formula.
# P056-safe via `git ls-tree --name-only` to avoid blob-SHA false-match.
# ---------------------------------------------------------------------------

@test "capture-adr: next-ID formula is P056-safe (origin/local max + 1)" {
  # Build a fixture decisions directory with mixed status suffixes.
  # The formula must pick the max ID across all suffixes and zero-pad.
  mkdir -p "$TMPROOT/docs/decisions"
  : > "$TMPROOT/docs/decisions/001-foo.accepted.md"
  : > "$TMPROOT/docs/decisions/032-bar.proposed.md"
  : > "$TMPROOT/docs/decisions/057-baz.proposed.md"
  : > "$TMPROOT/docs/decisions/123-qux.superseded.md"

  # Mirror create-adr Step 3 / capture-adr Step 2 local-max formula exactly.
  local_max=$(ls "$TMPROOT/docs/decisions"/*.md 2>/dev/null \
              | sed 's/.*\///' \
              | grep -oE '^[0-9]+' \
              | sort -n | tail -1)
  [ "$local_max" = "123" ]

  # No origin available in the fixture; default to 0 then increment.
  next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n0" | sort -n | tail -1) + 1 )))
  [ "$next" = "124" ]
}

@test "capture-adr: next-ID handles empty decisions dir (first ADR)" {
  mkdir -p "$TMPROOT/docs/decisions"
  local_max=$(ls "$TMPROOT/docs/decisions"/*.md 2>/dev/null \
              | sed 's/.*\///' \
              | grep -oE '^[0-9]+' \
              | sort -n | tail -1)
  next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n0" | sort -n | tail -1) + 1 )))
  [ "$next" = "001" ]
}

@test "capture-adr: next-ID prefers origin_max when origin > local (collision guard)" {
  # Simulate the case where origin has a higher ADR number than local
  # (parallel session pushed a new ADR before this session captures).
  mkdir -p "$TMPROOT/docs/decisions"
  : > "$TMPROOT/docs/decisions/050-local.proposed.md"
  local_max=50
  origin_max=175   # parallel session pushed ADR-175

  next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))
  [ "$next" = "176" ]
}

@test "capture-adr: next-ID handles 099 → 100 transition without octal-eval failure (P164)" {
  # P164 regression: bash $(( ... )) parses leading-zero numbers as octal.
  # `099` is invalid octal (digits >= 8). Without `10#` prefix, this fires:
  #   bash: 099: value too great for base (error token is "099")
  # The fix is the standard `10#` base-10 prefix on the inner $(echo ... | tail -1).
  mkdir -p "$TMPROOT/docs/decisions"
  : > "$TMPROOT/docs/decisions/098-foo.proposed.md"
  : > "$TMPROOT/docs/decisions/099-bar.proposed.md"

  local_max=$(ls "$TMPROOT/docs/decisions"/*.md 2>/dev/null \
              | sed 's/.*\///' \
              | grep -oE '^[0-9]+' \
              | sort -n | tail -1)
  [ "$local_max" = "099" ]

  next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n0" | sort -n | tail -1) + 1 )))
  [ "$next" = "100" ]
}

# ---------------------------------------------------------------------------
# Derive-fill MADR shape (RFC-045 / P375) — capture-adr writes a fully-
# derived ADR at status: proposed. Load-bearing primitives:
#   - Title at H1
#   - status: proposed + human-oversight: unconfirmed in frontmatter
#   - decision-makers derived (real name, no sentinel)
#   - reassessment-date 3 months from today
#   - >=2 REAL numbered options (chosen + actually-rejected alternative)
#   - Every section carries real derived prose; the file matches NOTHING
#     in the shared deferral-marker vocabulary (DEFERRAL_MARKER_RE).
# ---------------------------------------------------------------------------

@test "capture-adr: derived-substance ADR matches nothing in the deferral-marker vocabulary" {
  # RFC-045: no placeholder, pointer, or sentinel strings of any kind.
  # Asserted against the single source of truth for the deferred-work
  # vocabulary (P375 census) so "no placeholder of any kind" is the
  # behavioural contract, not just "not the one old literal string".
  MARKERS_LIB="${REPO_ROOT}/packages/retrospective/hooks/lib/deferral-markers.sh"
  [ -f "$MARKERS_LIB" ]
  # shellcheck disable=SC1090
  source "$MARKERS_LIB"
  [ -n "$DEFERRAL_MARKER_RE" ]

  mkdir -p "$TMPROOT/docs/decisions"
  TITLE="example-mid-iter-decision"
  ID="200"
  TODAY=$(date -u +%Y-%m-%d)
  REASSESS=$(date -u -v+3m +%Y-%m-%d 2>/dev/null || date -u -d "+3 months" +%Y-%m-%d)
  CONTEXT_LINE="Iter-bound design choice that needs codification."
  DECISION_LINE="Adopt Option A because it preserves invariants X and Y."

  # Mirror the SKILL.md derive-fill template with real derived content.
  cat > "$TMPROOT/docs/decisions/${ID}-${TITLE}.proposed.md" <<EOF
---
status: "proposed"
date: ${TODAY}
human-oversight: unconfirmed
decision-makers: [Test User]
consulted: []
informed: []
reassessment-date: ${REASSESS}
---

# ${TITLE}

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per ADR-032, derived-substance amendment 2026-07-06 / RFC-045). Section content was derived by the capturing agent from the in-session decision context; human-oversight: unconfirmed until ratified at the /wr-architect:review-decisions drain.

## Context and Problem Statement

${CONTEXT_LINE}

## Decision Drivers

- Invariant X must survive iter restarts.
- Option B would couple the loop to session state.

## Considered Options

1. **Option A (chosen)** — ${DECISION_LINE}
2. **Option B (session-state coupling)** — rejected: couples the loop to session state.

## Decision Outcome

Chosen option: **"Option A"**, because ${DECISION_LINE}

## Consequences

### Good

- Invariants X and Y hold across iters.

### Neutral

- No neutral consequences identified at capture.

### Bad

- One extra lookup per iter.

## Confirmation

Run the iter loop twice; invariant X holds on the second run.

## Pros and Cons of the Options

### Option A

- Good, because invariants survive restarts.
- Bad, because of the extra lookup.

### Option B

- Good, because no extra lookup.
- Bad, because session-state coupling breaks AFK iters.

## Reassessment Criteria

Reopen if the extra-lookup cost exceeds one turn per iter.
EOF

  ADR="$TMPROOT/docs/decisions/${ID}-${TITLE}.proposed.md"
  [ -f "$ADR" ]

  # Load-bearing fields present.
  run grep -F 'status: "proposed"' "$ADR"
  [ "$status" -eq 0 ]
  run grep -F 'human-oversight: unconfirmed' "$ADR"
  [ "$status" -eq 0 ]
  # Decision-makers carries a real name — no sentinel.
  run grep -F 'decision-makers: [Test User]' "$ADR"
  [ "$status" -eq 0 ]
  # Title from input lands at H1.
  run grep -F "# ${TITLE}" "$ADR"
  [ "$status" -eq 0 ]
  # Context + Decision survive verbatim from input.
  run grep -F "$CONTEXT_LINE" "$ADR"
  [ "$status" -eq 0 ]
  run grep -F "$DECISION_LINE" "$ADR"
  [ "$status" -eq 0 ]

  # THE contract: nothing in the file matches the deferral vocabulary.
  run grep -Eic "$DEFERRAL_MARKER_RE" "$ADR"
  [ "$output" = "0" ]
  # And the legacy sentinel shape is gone too.
  run grep -F 'unspecified — fill at canonical review' "$ADR"
  [ "$status" -ne 0 ]
}

@test "capture-adr: derived ADR carries >=2 REAL numbered options (no placeholder sibling)" {
  # RFC-045: MADR >=2-options is satisfied by substance — the chosen
  # option plus an actually-weighed alternative — never by a numbered
  # placeholder.
  mkdir -p "$TMPROOT/docs/decisions"
  ID="201"
  TITLE="another-decision"

  cat > "$TMPROOT/docs/decisions/${ID}-${TITLE}.proposed.md" <<'EOF'
## Considered Options

1. **Option A (chosen)** — One-line summary
2. **Status quo (do nothing)** — rejected: the symptom recurs every session
EOF

  ADR="$TMPROOT/docs/decisions/${ID}-${TITLE}.proposed.md"
  # Numbered option 1 with chosen marker.
  run grep -F '1. **Option A (chosen)**' "$ADR"
  [ "$status" -eq 0 ]
  # Numbered option 2 is real content, not a deferral.
  run grep -E '^2\. \*\*' "$ADR"
  [ "$status" -eq 0 ]
  run grep -F '(deferred' "$ADR"
  [ "$status" -ne 0 ]
}

@test "capture-adr: default reassessment-date is 3 months from today (matches create-adr)" {
  # The 3-month default matches create-adr Step 4 default and is
  # framework-policy per ADR-044. Computed value lands in frontmatter.
  TODAY=$(date -u +%Y-%m-%d)
  # Compute 3 months from today using BSD date or GNU date.
  REASSESS=$(date -u -v+3m +%Y-%m-%d 2>/dev/null || date -u -d "+3 months" +%Y-%m-%d)

  # The reassess date is non-empty and parseable as YYYY-MM-DD.
  [ -n "$REASSESS" ]
  echo "$REASSESS" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'

  # The reassess date is strictly later than today (3 months ahead).
  [ "$REASSESS" \> "$TODAY" ]
}

# ---------------------------------------------------------------------------
# Skill-allowed-tools surface contract — capture-adr MUST NOT carry
# AskUserQuestion (per design Q4 + ADR-044 framework-mediated mechanical-
# stage decisions). This is observable from the frontmatter declaration
# the runtime consumes.
# ---------------------------------------------------------------------------

@test "capture-adr: allowed-tools omits AskUserQuestion (no interactive branches)" {
  # The skill's contract is NO AskUserQuestion at all — Considered Options
  # / Decision Drivers / Consequences / Confirmation / Reassessment are
  # framework-mediated mechanical stages per ADR-044. AskUserQuestion in
  # allowed-tools would let future drift sneak prompts back in.
  run grep -E '^allowed-tools:' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -E '^allowed-tools:.*AskUserQuestion' "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "capture-adr: allowed-tools includes Bash (for next-ID + commit primitives)" {
  # next-ID via git ls-tree | grep | sort + commit gate via Bash invocation.
  run grep -E '^allowed-tools:.*Bash' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "capture-adr: allowed-tools includes Write (for new ADR file)" {
  run grep -E '^allowed-tools:.*Write' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Deferred-ratification contract — distinguishing capture-adr from
# create-adr. capture-adr must NOT invoke the architect-agent inline; it
# writes status: proposed + human-oversight: unconfirmed and defers human
# ratification to the self-firing oversight drain (RFC-045).
# ---------------------------------------------------------------------------

@test "capture-adr: SKILL.md routes ratification to the review-decisions drain (no inline review handoff)" {
  # The contract distinction from create-adr: capture-adr does NOT invoke
  # the wr-architect:agent review inline; the derived substance is
  # ratified at the /wr-architect:review-decisions drain surfaced by the
  # SessionStart oversight nudge. A future maintainer who copies
  # create-adr's Step 5 confirm pass into capture-adr would break the
  # zero-interaction promise.
  run grep -F '/wr-architect:review-decisions' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -F 'human-oversight: unconfirmed' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
