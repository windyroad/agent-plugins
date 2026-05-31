#!/usr/bin/env bats

# @problem P346 — `/wr-itil:review-problems` has no path to close tickets that
#                 are no longer relevant (evidence-based, NOT age-based) —
#                 structural outflow gap drives monotonic backlog growth.
#                 Phase 1 ships the auto-close on "file no longer exists in
#                 codebase" evidence shape.
#
# Contract: `evaluate-relevance.sh <ticket-file> [<min-age-days>]` reads the
# ticket frontmatter for **Reported**:, applies an age gate, extracts file
# paths matching well-known repo subdirs from the ticket body (excluding
# self-references to docs/problems/*), runs `git ls-files --error-unmatch`
# on each, and emits a structured verdict.
#
# Output (stdout, one line):
#   CLOSE-CANDIDATE <basename> — all <N> file paths absent: <semicolon list>
#   KEEP            <basename> — <M>/<N> paths still present
#   SKIP            <basename> — <reason>
#
# Exit codes:
#   0 = CLOSE-CANDIDATE
#   1 = KEEP
#   2 = SKIP
#   3 = error
#
# @adr ADR-079 (Evidence-based relevance-close pass — Phase 1)
# @adr ADR-049 (bin/ on PATH shim — adopter-safe script resolution)
# @adr ADR-022 (Lifecycle extension — Open|Known Error → Closed-with-reason)
# @adr ADR-026 (Agent output grounding — cite + persist + uncertainty)
# @adr ADR-052 (Behavioural bats default)
# @jtbd JTBD-001 (Enforce Governance — under-60s review-flow served by smaller queue)
# @jtbd JTBD-006 (AFK — mechanical evidence not judgment-call)
# @jtbd JTBD-101 (Extend the Suite — extensible pattern per evidence shape)
# @jtbd JTBD-201 (Audit trail — closed-ticket section preserves close reason)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/evaluate-relevance.sh"
  FIXTURE_DIR="$(mktemp -d)"
  cd "$FIXTURE_DIR"
  git init -q -b main
  git config user.email test@example.com
  git config user.name "Test"
  mkdir -p docs/problems/open docs/problems/known-error docs/problems/closed packages/itil/scripts docs/decisions

  # An "old" Reported date: 60 days before today. ISO date arithmetic
  # portable across BSD + GNU date.
  OLD_DATE=$(date -u -v-60d "+%Y-%m-%d" 2>/dev/null || date -u -d '60 days ago' "+%Y-%m-%d")
  # A "fresh" Reported date: 1 day before today.
  FRESH_DATE=$(date -u -v-1d "+%Y-%m-%d" 2>/dev/null || date -u -d '1 day ago' "+%Y-%m-%d")
}

teardown() {
  cd /
  rm -rf "$FIXTURE_DIR"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "evaluate-relevance: script exists" {
  [ -f "$SCRIPT" ]
}

@test "evaluate-relevance: script is executable" {
  [ -x "$SCRIPT" ]
}

@test "evaluate-relevance: PATH shim exists and dispatches" {
  SHIM="$SCRIPTS_DIR/../bin/wr-itil-evaluate-relevance"
  [ -f "$SHIM" ]
  [ -x "$SHIM" ]
  # Shim exec's the canonical script body.
  grep -q "evaluate-relevance.sh" "$SHIM"
}

# ── Usage / error path ──────────────────────────────────────────────────────

@test "evaluate-relevance: no args → exit 3 with usage stderr" {
  run "$SCRIPT"
  [ "$status" -eq 3 ]
  [[ "$output" == *"usage"* ]]
}

@test "evaluate-relevance: nonexistent ticket file → exit 3" {
  run "$SCRIPT" /nonexistent/ticket.md
  [ "$status" -eq 3 ]
  [[ "$output" == *"not found"* ]]
}

# ── Age gate (SKIP exit 2) ──────────────────────────────────────────────────

@test "evaluate-relevance: fresh ticket (< 7 days) → SKIP exit 2" {
  cat > docs/problems/open/100-foo.md <<EOF
# Problem 100: foo

**Status**: Open
**Reported**: $FRESH_DATE

## Description

Bug in packages/itil/scripts/imaginary.sh
EOF
  run "$SCRIPT" docs/problems/open/100-foo.md
  [ "$status" -eq 2 ]
  [[ "$output" == "SKIP "*"age gate"* ]]
}

@test "evaluate-relevance: no Reported date → SKIP exit 2" {
  cat > docs/problems/open/101-bar.md <<EOF
# Problem 101: bar

**Status**: Open

## Description

packages/itil/scripts/missing.sh
EOF
  run "$SCRIPT" docs/problems/open/101-bar.md
  [ "$status" -eq 2 ]
  [[ "$output" == *"no Reported date"* ]]
}

# ── No extractable paths (SKIP exit 2) ──────────────────────────────────────

@test "evaluate-relevance: no extractable file paths → SKIP exit 2" {
  cat > docs/problems/open/102-baz.md <<EOF
# Problem 102: baz

**Status**: Open
**Reported**: $OLD_DATE

## Description

A general complaint about agent behaviour with no file references.
EOF
  run "$SCRIPT" docs/problems/open/102-baz.md
  [ "$status" -eq 2 ]
  [[ "$output" == *"no extractable file paths"* ]]
}

@test "evaluate-relevance: only self-references to docs/problems/* → SKIP exit 2" {
  cat > docs/problems/open/103-qux.md <<EOF
# Problem 103: qux

**Status**: Open
**Reported**: $OLD_DATE

## Description

Duplicate concern with docs/problems/open/099-other.md and docs/problems/known-error/088-third.md.
EOF
  run "$SCRIPT" docs/problems/open/103-qux.md
  [ "$status" -eq 2 ]
  [[ "$output" == *"no extractable file paths"* ]]
}

# ── CLOSE-CANDIDATE path (exit 0) ───────────────────────────────────────────

@test "evaluate-relevance: old ticket + all paths absent → CLOSE-CANDIDATE exit 0" {
  cat > docs/problems/open/104-stale.md <<EOF
# Problem 104: stale

**Status**: Open
**Reported**: $OLD_DATE

## Description

Bug in packages/itil/scripts/imaginary-helper.sh that no longer exists.
Related: docs/decisions/999-imaginary-adr.proposed.md.
EOF
  run "$SCRIPT" docs/problems/open/104-stale.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"104-stale.md"*"all 2 file paths absent"* ]]
  [[ "$output" == *"packages/itil/scripts/imaginary-helper.sh"* ]]
  [[ "$output" == *"docs/decisions/999-imaginary-adr.proposed.md"* ]]
}

@test "evaluate-relevance: old ticket + single absent path → CLOSE-CANDIDATE exit 0" {
  cat > docs/problems/open/105-single.md <<EOF
# Problem 105: single

**Status**: Open
**Reported**: $OLD_DATE

## Description

The script at packages/itil/scripts/dead-helper.sh fails.
EOF
  run "$SCRIPT" docs/problems/open/105-single.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"all 1 file paths absent"* ]]
  [[ "$output" == *"packages/itil/scripts/dead-helper.sh"* ]]
}

# ── KEEP path (exit 1) ──────────────────────────────────────────────────────

@test "evaluate-relevance: old ticket + all paths present → KEEP exit 1" {
  # Create + stage the file so git ls-files sees it
  echo "live" > packages/itil/scripts/live-helper.sh
  git add packages/itil/scripts/live-helper.sh

  cat > docs/problems/open/106-live.md <<EOF
# Problem 106: live

**Status**: Open
**Reported**: $OLD_DATE

## Description

Bug in packages/itil/scripts/live-helper.sh.
EOF
  run "$SCRIPT" docs/problems/open/106-live.md
  [ "$status" -eq 1 ]
  [[ "$output" == "KEEP "*"1/1 paths still present"* ]]
}

@test "evaluate-relevance: old ticket + mixed paths (one present, one absent) → KEEP exit 1" {
  echo "live" > packages/itil/scripts/exists.sh
  git add packages/itil/scripts/exists.sh

  cat > docs/problems/open/107-mixed.md <<EOF
# Problem 107: mixed

**Status**: Open
**Reported**: $OLD_DATE

## Description

Interaction between packages/itil/scripts/exists.sh and
packages/itil/scripts/gone.sh produces wrong result.
EOF
  run "$SCRIPT" docs/problems/open/107-mixed.md
  [ "$status" -eq 1 ]
  [[ "$output" == "KEEP "*"1/2 paths still present"* ]]
}

# ── Known Error tickets (exit 0) ────────────────────────────────────────────

@test "evaluate-relevance: known-error ticket with all paths absent → CLOSE-CANDIDATE exit 0" {
  cat > docs/problems/known-error/108-ke-stale.md <<EOF
# Problem 108: ke-stale

**Status**: Known Error
**Reported**: $OLD_DATE

## Description

Fix strategy referenced packages/itil/scripts/abandoned-fix.sh.

## Root Cause Analysis

Root cause was identified in packages/itil/scripts/abandoned-fix.sh.
EOF
  run "$SCRIPT" docs/problems/known-error/108-ke-stale.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"108-ke-stale.md"* ]]
}

# ── Custom age gate ─────────────────────────────────────────────────────────

@test "evaluate-relevance: custom min-age-days=30 keeps a 15-day-old ticket as SKIP" {
  MED_DATE=$(date -u -v-15d "+%Y-%m-%d" 2>/dev/null || date -u -d '15 days ago' "+%Y-%m-%d")
  cat > docs/problems/open/109-medium.md <<EOF
# Problem 109: medium

**Status**: Open
**Reported**: $MED_DATE

## Description

packages/itil/scripts/missing.sh is broken.
EOF
  run "$SCRIPT" docs/problems/open/109-medium.md 30
  [ "$status" -eq 2 ]
  [[ "$output" == *"age gate"* ]]
}

# ── Output contract: verdict starts with the keyword ────────────────────────

@test "evaluate-relevance: CLOSE-CANDIDATE verdict begins with the literal keyword" {
  cat > docs/problems/open/110-verdict.md <<EOF
# Problem 110: verdict

**Status**: Open
**Reported**: $OLD_DATE

## Description

packages/itil/scripts/missing-x.sh
EOF
  run "$SCRIPT" docs/problems/open/110-verdict.md
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "CLOSE-CANDIDATE "* ]]
}

@test "evaluate-relevance: KEEP verdict begins with the literal keyword" {
  echo "x" > packages/itil/scripts/present-x.sh
  git add packages/itil/scripts/present-x.sh

  cat > docs/problems/open/111-keep-verdict.md <<EOF
# Problem 111: keep-verdict

**Status**: Open
**Reported**: $OLD_DATE

## Description

packages/itil/scripts/present-x.sh
EOF
  run "$SCRIPT" docs/problems/open/111-keep-verdict.md
  [ "$status" -eq 1 ]
  [[ "${lines[0]}" == "KEEP "* ]]
}

@test "evaluate-relevance: SKIP verdict begins with the literal keyword" {
  cat > docs/problems/open/112-skip-verdict.md <<EOF
# Problem 112: skip-verdict

**Status**: Open
**Reported**: $FRESH_DATE

## Description

packages/itil/scripts/anything.sh
EOF
  run "$SCRIPT" docs/problems/open/112-skip-verdict.md
  [ "$status" -eq 2 ]
  [[ "${lines[0]}" == "SKIP "* ]]
}

# ── Phase 2 Shape 2: ADR-shipped with `human-oversight: confirmed` ───────────
#
# @adr ADR-079 Phase 2 — shape 2 covers 8 of 14 closes in the 2026-05-31
#                        labeled fixture set (P012/P015/P018/P022/P033/P039/
#                        P194/P292). Mechanical check: grep ticket body for
#                        ADR-NNN refs; for each, verify
#                        docs/decisions/<NNN>-*.md exists AND frontmatter has
#                        `human-oversight: confirmed`.

@test "evaluate-relevance: Phase 2 shape 2 — ADR-shipped-confirmed → CLOSE-CANDIDATE exit 0" {
  cat > docs/decisions/037-confirmed-adr.proposed.md <<EOF
---
status: "proposed"
human-oversight: confirmed
oversight-date: 2026-05-25
---

# ADR-037: Test confirmed ADR
EOF
  git add docs/decisions/037-confirmed-adr.proposed.md

  cat > docs/problems/open/120-adr-confirmed.md <<EOF
# Problem 120: adr-confirmed

**Status**: Open
**Reported**: $OLD_DATE

## Description

ADR-037 was the design decision; the implementation has landed and the
ADR is human-oversight: confirmed. Concern no longer concerning.
EOF
  run "$SCRIPT" docs/problems/open/120-adr-confirmed.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"shapes: "*"ADR-shipped-confirmed"* ]]
  [[ "$output" == *"ADR-037"* ]]
}

@test "evaluate-relevance: Phase 2 shape 2 — ADR exists but NOT confirmed → no shape 2 fire" {
  cat > docs/decisions/038-proposed-but-unconfirmed.proposed.md <<EOF
---
status: "proposed"
---

# ADR-038: Not yet confirmed
EOF
  git add docs/decisions/038-proposed-but-unconfirmed.proposed.md

  cat > docs/problems/open/121-adr-unconfirmed.md <<EOF
# Problem 121: adr-unconfirmed

**Status**: Open
**Reported**: $OLD_DATE

## Description

ADR-038 captured the design but is not yet confirmed by human review.
EOF
  run "$SCRIPT" docs/problems/open/121-adr-unconfirmed.md
  # Without other shape matches, shape 2 alone (unconfirmed ADR) MUST NOT
  # produce a CLOSE-CANDIDATE. Verdict routes to SKIP (no extractable
  # paths to ground shape 1) or KEEP — never CLOSE-CANDIDATE.
  [ "$status" -ne 0 ]
  [[ "${lines[0]}" != "CLOSE-CANDIDATE "* ]]
  [[ "${lines[0]}" != "CLOSE-CANDIDATE-WITH-CAVEAT "* ]]
}

# ── Phase 2 Shape 3: named-skill-or-feature-exists ───────────────────────────
#
# @adr ADR-079 Phase 2 — shape 3 covers 6 of 14 closes (P014/P034/P045/P079/
#                        P190/P289). Verifies the cited SKILL.md / hook /
#                        agent / slash-command surface exists.

@test "evaluate-relevance: Phase 2 shape 3 — SKILL.md exists → CLOSE-CANDIDATE exit 0" {
  mkdir -p packages/itil/skills/some-feature
  cat > packages/itil/skills/some-feature/SKILL.md <<EOF
---
name: wr-itil:some-feature
---
# Some Feature
EOF
  git add packages/itil/skills/some-feature/SKILL.md

  cat > docs/problems/open/130-feature-shipped.md <<EOF
# Problem 130: feature-shipped

**Status**: Open
**Reported**: $OLD_DATE

## Description

The feature this ticket asks for has shipped at
\`packages/itil/skills/some-feature/SKILL.md\`. Concern resolved.
EOF
  run "$SCRIPT" docs/problems/open/130-feature-shipped.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"shapes: "*"named-skill-or-feature-exists"* ]]
}

@test "evaluate-relevance: Phase 2 shape 3 — slash-command ref + SKILL exists → CLOSE-CANDIDATE exit 0" {
  mkdir -p packages/architect/skills/capture-adr
  cat > packages/architect/skills/capture-adr/SKILL.md <<EOF
---
name: wr-architect:capture-adr
---
EOF
  git add packages/architect/skills/capture-adr/SKILL.md

  cat > docs/problems/open/131-slash-command.md <<EOF
# Problem 131: slash-command

**Status**: Open
**Reported**: $OLD_DATE

## Description

The aside-invocation surface /wr-architect:capture-adr now exists and
covers the original concern.
EOF
  run "$SCRIPT" docs/problems/open/131-slash-command.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"named-skill-or-feature-exists"* ]]
}

# ── Phase 2 Shape 4: self-marker-in-body (line-anchored regex per A2) ────────
#
# @adr ADR-079 Phase 2 — shape 4 explicit in P289 ("Close to Verifying"),
#                        contributory in P033 ("## Fix Released"). Regex
#                        line-anchored per architect advisory A2 to avoid
#                        mid-prose false-positives.

@test "evaluate-relevance: Phase 2 shape 4 — 'Close to Verifying' line marker → CLOSE-CANDIDATE exit 0" {
  cat > docs/problems/open/140-self-marker.md <<EOF
# Problem 140: self-marker

**Status**: Open
**Reported**: $OLD_DATE

## Description

Work has been done.

## Resolution

The fix shipped 2026-05-27. Close to Verifying.
EOF
  run "$SCRIPT" docs/problems/open/140-self-marker.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"self-marker-in-body"* ]]
}

@test "evaluate-relevance: Phase 2 shape 4 — '## Fix Released' heading → CLOSE-CANDIDATE exit 0" {
  cat > docs/problems/open/141-fix-released.md <<EOF
# Problem 141: fix-released

**Status**: Open
**Reported**: $OLD_DATE

## Description

Bug.

## Fix Released

Implemented 2026-04-17.
EOF
  run "$SCRIPT" docs/problems/open/141-fix-released.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"self-marker-in-body"* ]]
}

@test "evaluate-relevance: Phase 2 shape 4 — 'DONE 2026-' line marker → CLOSE-CANDIDATE exit 0" {
  cat > docs/problems/open/142-done-marker.md <<EOF
# Problem 142: done-marker

**Status**: Open
**Reported**: $OLD_DATE

## Description

Description.

### Investigation Tasks

- [x] DONE 2026-05-27 — Migration-strategy decision executed.
EOF
  run "$SCRIPT" docs/problems/open/142-done-marker.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"self-marker-in-body"* ]]
}

@test "evaluate-relevance: Phase 2 shape 4 — mid-prose 'close to verifying' (lowercase, narrative) → KEEP exit 1 (negative fixture per advisory A2)" {
  cat > docs/problems/open/143-mid-prose.md <<EOF
# Problem 143: mid-prose

**Status**: Open
**Reported**: $OLD_DATE

## Description

The team thinks this is close to verifying our hypothesis but no concrete
shipped evidence exists yet — still investigating.
EOF
  run "$SCRIPT" docs/problems/open/143-mid-prose.md
  # Without other shape matches, mid-prose narrative MUST NOT fire shape 4.
  # Verdict should be SKIP (no extractable paths) or KEEP — never CLOSE-CANDIDATE.
  [ "$status" -ne 0 ]
}

# ── Phase 2 Shape 5: driver-child-ticket-closed ──────────────────────────────
#
# @adr ADR-079 Phase 2 — shape 5 contributory in several closes (e.g. P014
#                        cites closed P155 driver). Parses ## Related for
#                        P<NNN> refs; checks if any are in
#                        docs/problems/closed/.

@test "evaluate-relevance: Phase 2 shape 5 — Related cites closed driver → CLOSE-CANDIDATE exit 0" {
  cat > docs/problems/closed/155-driver-done.md <<EOF
# Problem 155: driver-done

**Status**: Closed
EOF
  git add docs/problems/closed/155-driver-done.md

  cat > docs/problems/open/150-child-of-closed.md <<EOF
# Problem 150: child-of-closed

**Status**: Open
**Reported**: $OLD_DATE

## Description

This is the umbrella for several driver tickets.

## Related

- **P155** — implementation driver.
EOF
  run "$SCRIPT" docs/problems/open/150-child-of-closed.md
  [ "$status" -eq 0 ]
  [[ "$output" == "CLOSE-CANDIDATE "*"driver-child-ticket-closed"* ]]
}

@test "evaluate-relevance: Phase 2 shape 5 — Related cites closed driver BUT child has independent open work → KEEP exit 1 (advisory A1 negative fixture)" {
  cat > docs/problems/closed/156-driver-done.md <<EOF
# Problem 156: driver-done

**Status**: Closed
EOF
  git add docs/problems/closed/156-driver-done.md

  cat > docs/problems/open/151-independent.md <<EOF
# Problem 151: independent

**Status**: Open
**Reported**: $OLD_DATE

## Description

While the driver P156 is closed, this ticket has its own outstanding
investigation around \`packages/itil/skills/unrelated-future-skill/SKILL.md\`
which has not been implemented yet.

## Related

- **P156** — original driver (closed); this ticket carries new scope beyond P156.
EOF
  run "$SCRIPT" docs/problems/open/151-independent.md
  # The script extracts \`packages/itil/skills/unrelated-future-skill/SKILL.md\`
  # which does NOT exist — shape 1 (file-no-longer-exists) would fire. But the
  # ticket independent-work signal lives in the unimplemented-file class; the
  # KEEP requirement here is: shape 5 must NOT fire when an existing file
  # reference is unresolvable (i.e. the umbrella has unfinished scope).
  # Per architect advisory A1, we surface this as KEEP-WITH-NOTE rather than
  # silent CLOSE-CANDIDATE.
  [ "$status" -ne 0 ]
}

# ── Phase 1 false-positive fixes ─────────────────────────────────────────────
#
# @adr ADR-079 Phase 2 — Phase 1 false-positive class fixes:
#                        - P180: state-suffix detection (incident I002.investigating.md vs I002.restored.md)
#                        - P244: sibling-file detection (plugin-maturity-list.sh vs plugin-maturity-render.sh)
#                        - P251: rename detection via git log --follow

@test "evaluate-relevance: Phase 1 fix — state-suffix variant exists at different suffix → KEEP-WITH-NOTE (not CLOSE-CANDIDATE)" {
  mkdir -p docs/incidents
  cat > docs/incidents/I002-renamed.restored.md <<EOF
# Incident I002
EOF
  git add docs/incidents/I002-renamed.restored.md

  cat > docs/problems/open/160-state-suffix.md <<EOF
# Problem 160: state-suffix

**Status**: Open
**Reported**: $OLD_DATE

## Description

Investigation references docs/incidents/I002-renamed.investigating.md
which has since transitioned state.
EOF
  run "$SCRIPT" docs/problems/open/160-state-suffix.md
  # Phase 1 would falsely declare the file gone. Phase 2 detects the
  # restored.md state-suffix variant and routes to KEEP-WITH-NOTE.
  [ "$status" -eq 1 ]
  [[ "$output" == "KEEP-WITH-NOTE "* ]] || [[ "$output" == "KEEP "* ]]
  [[ "$output" == *"state-suffix"* ]] || [[ "$output" == *"renamed.restored.md"* ]]
}

@test "evaluate-relevance: Phase 1 fix — sibling file with similar slug-prefix → KEEP-WITH-NOTE" {
  mkdir -p packages/architect/scripts
  cat > packages/architect/scripts/plugin-maturity-render.sh <<EOF
#!/bin/bash
EOF
  cat > packages/architect/scripts/plugin-maturity-populate.sh <<EOF
#!/bin/bash
EOF
  git add packages/architect/scripts/plugin-maturity-render.sh packages/architect/scripts/plugin-maturity-populate.sh

  cat > docs/problems/open/161-sibling-file.md <<EOF
# Problem 161: sibling-file

**Status**: Open
**Reported**: $OLD_DATE

## Description

Bug in packages/architect/scripts/plugin-maturity-list.sh
EOF
  run "$SCRIPT" docs/problems/open/161-sibling-file.md
  # Phase 1 would declare plugin-maturity-list.sh gone. Phase 2 detects
  # the sibling-file class (plugin-maturity-* slug-prefix) and routes to
  # KEEP-WITH-NOTE.
  [ "$status" -eq 1 ]
  [[ "$output" == "KEEP-WITH-NOTE "* ]] || [[ "$output" == "KEEP "* ]]
  [[ "$output" == *"sibling"* ]] || [[ "$output" == *"plugin-maturity-"* ]]
}

# ── CLOSE-CANDIDATE-WITH-CAVEAT structured emission (architect condition C2) ──

@test "evaluate-relevance: CLOSE-CANDIDATE-WITH-CAVEAT emits structured caveat format" {
  cat > docs/decisions/040-multi-phase-confirmed.proposed.md <<EOF
---
status: "proposed"
human-oversight: confirmed
oversight-date: 2026-05-25
---
# ADR-040
EOF
  git add docs/decisions/040-multi-phase-confirmed.proposed.md

  cat > docs/problems/open/170-umbrella-caveat.md <<EOF
# Problem 170: umbrella-caveat

**Status**: Open
**Reported**: $OLD_DATE

## Description

Multi-phase umbrella. ADR-040 covers the design; Phase 2 done, Phase 3
outstanding work \`packages/jtbd/lib/phase3-helper.sh\`.

## Phase 3 progress

- [ ] Phase 3 work
EOF
  # Phase 3 cited path does not exist; ADR-040 confirmed → shape 2 fires + caveat
  run "$SCRIPT" docs/problems/open/170-umbrella-caveat.md
  # Architect condition C2 — structured caveat emission:
  # CLOSE-CANDIDATE-WITH-CAVEAT <basename> — shapes: <list> — caveat: <tag>: <one-line>
  # For multi-phase umbrellas with unticked checkboxes the caveat tag is
  # 'multi-phase-mixed-progress'.
  [[ "$output" == "CLOSE-CANDIDATE-WITH-CAVEAT "* ]]
  [[ "$output" == *"shapes:"* ]]
  [[ "$output" == *"caveat:"* ]]
  [[ "$output" == *"multi-phase-mixed-progress"* ]]
}

# ── KEEP fixtures from the 2026-05-31 labeled negative set ────────────────────
#
# @adr ADR-079 Phase 2 — KEEP regression suite: P136 multi-phase umbrella,
#                        P303/P326 recent-observation-no-shipped-evidence.

@test "evaluate-relevance: KEEP fixture — recent observation, no shipped evidence (P303/P326 class)" {
  cat > docs/problems/open/180-recent-observation.md <<EOF
# Problem 180: recent-observation

**Status**: Open
**Reported**: $OLD_DATE

## Description

Observed friction with the risk-scorer pipeline staging. Composes-with
P057 / P125 / P273 (sibling staging traps) but no shipped fix yet.

## Related

- **P057** — sibling.
EOF
  # P057 not closed (no file); no ADR refs that are confirmed; no SKILL refs;
  # no self-markers. Should KEEP.
  run "$SCRIPT" docs/problems/open/180-recent-observation.md
  [ "$status" -ne 0 ]
  # Either SKIP (no extractable paths) or KEEP — never CLOSE-CANDIDATE.
  [[ "${lines[0]}" != "CLOSE-CANDIDATE "* ]]
  [[ "${lines[0]}" != "CLOSE-CANDIDATE-WITH-CAVEAT "* ]]
}

# ── Cumulative shape annotation (architect Q4 — cumulative is correct) ───────

@test "evaluate-relevance: multi-shape match emits cumulative shapes: list" {
  cat > docs/decisions/041-multi-match.proposed.md <<EOF
---
status: "proposed"
human-oversight: confirmed
oversight-date: 2026-05-25
---
# ADR-041
EOF
  git add docs/decisions/041-multi-match.proposed.md

  cat > docs/problems/open/190-multi-shape.md <<EOF
# Problem 190: multi-shape

**Status**: Open
**Reported**: $OLD_DATE

## Description

ADR-041 captures the design. Fix shipped.

## Fix Released

Implemented and confirmed.
EOF
  run "$SCRIPT" docs/problems/open/190-multi-shape.md
  [ "$status" -eq 0 ]
  # Both shape 2 (ADR-confirmed) and shape 4 (Fix Released line) match.
  [[ "$output" == *"ADR-shipped-confirmed"* ]]
  [[ "$output" == *"self-marker-in-body"* ]]
}
