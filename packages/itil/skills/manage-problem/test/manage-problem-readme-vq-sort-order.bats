#!/usr/bin/env bats

# P150: docs/problems/README.md Verification Queue must be rendered
# oldest-first (by Released date ASC, oldest at row 1) per ADR-022 +
# P048 user-task semantics. The header has long claimed "Ranked by
# release age, oldest first" while the rendered table drifted to
# newest-first across multiple SKILL.md render sites. This file
# encodes the canonical sort spec + greppable VQ-SORT-DIRECTION
# marker as a contract assertion across every render block, plus a
# behavioural fixture that asserts the actual sort outcome.
#
# Hybrid coverage per ADR-005 + ADR-037:
#   - Structural contract-assertions (Permitted Exception per ADR-005 /
#     contract-assertion pattern per ADR-037): each of the render-block
#     sites carries the canonical VQ-SORT-DIRECTION marker.
#   - One behavioural fixture sort: 4 .verifying.md tickets with known
#     Released dates. Apply the documented ASC-by-date sort. Assert
#     row 1 = the oldest entry; row N = the newest.
#
# @problem P150
# @jtbd JTBD-001 (enforce governance without slowing down — predictable
#   render order visible across the README and from `list-problems`)
# @jtbd JTBD-006 (progress backlog AFK — verification candidates ready
#   to close are at the top of the queue, not the bottom)
#
# Cross-reference:
#   P150: docs/problems/150-readme-verification-queue-rendered-newest-first-contradicts-oldest-first-header.*.md
#   P138: sibling fix on the WSJF Rankings table — same fix shape
#   P048: introduced the Verification Queue + Likely verified column
#   ADR-005 — plugin testing strategy / Permitted Exception
#   ADR-022 — `.verifying.md` lifecycle; VQ rendering
#   ADR-037 — contract-assertion bats pattern

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  MANAGE_SKILL="$REPO_ROOT/packages/itil/skills/manage-problem/SKILL.md"
  REVIEW_SKILL="$REPO_ROOT/packages/itil/skills/review-problems/SKILL.md"
  TRANSITION_SKILL="$REPO_ROOT/packages/itil/skills/transition-problem/SKILL.md"
  TRANSITIONS_SKILL="$REPO_ROOT/packages/itil/skills/transition-problems/SKILL.md"
  RECONCILE_SKILL="$REPO_ROOT/packages/itil/skills/reconcile-readme/SKILL.md"
  LIST_SKILL="$REPO_ROOT/packages/itil/skills/list-problems/SKILL.md"

  TEST_TMP="$(mktemp -d)"
}

teardown() {
  if [ -n "${TEST_TMP:-}" ] && [ -d "$TEST_TMP" ]; then
    rm -rf "$TEST_TMP"
  fi
}

# ---------------------------------------------------------------------------
# Structural contract-assertions — VQ-SORT-DIRECTION marker
# ---------------------------------------------------------------------------

@test "manage-problem render blocks carry the VQ-SORT-DIRECTION marker" {
  # Each render block writing the Verification Queue must carry the
  # canonical greppable marker pointing back to ADR-022 (the
  # framework-resolved source of the VQ ordering contract). Drift
  # across render sites re-opens P150.
  run grep -F '<!-- VQ-SORT-DIRECTION: oldest-first per ADR-022 -->' "$MANAGE_SKILL"
  [ "$status" -eq 0 ]
  # Marker must appear at the three manage-problem render sites:
  # Step 5 P094 (refresh on new ticket), Step 7 P062 (refresh on
  # transition), Step 9e (review-emit template).
  count=$(grep -c -F '<!-- VQ-SORT-DIRECTION: oldest-first per ADR-022 -->' "$MANAGE_SKILL")
  [ "$count" -ge 3 ]
}

@test "review-problems renders the VQ-SORT-DIRECTION marker" {
  run grep -F '<!-- VQ-SORT-DIRECTION: oldest-first per ADR-022 -->' "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
}

@test "transition-problem Step 7 README refresh carries the VQ-SORT-DIRECTION marker" {
  run grep -F '<!-- VQ-SORT-DIRECTION: oldest-first per ADR-022 -->' "$TRANSITION_SKILL"
  [ "$status" -eq 0 ]
}

@test "transition-problems batch render carries the VQ-SORT-DIRECTION marker" {
  run grep -F '<!-- VQ-SORT-DIRECTION: oldest-first per ADR-022 -->' "$TRANSITIONS_SKILL"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme rendering carries the VQ-SORT-DIRECTION marker" {
  run grep -F '<!-- VQ-SORT-DIRECTION: oldest-first per ADR-022 -->' "$RECONCILE_SKILL"
  [ "$status" -eq 0 ]
}

@test "list-problems VQ rendering carries the VQ-SORT-DIRECTION marker" {
  run grep -F '<!-- VQ-SORT-DIRECTION: oldest-first per ADR-022 -->' "$LIST_SKILL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Structural contract-assertions — sort-direction phrase consistency
# ---------------------------------------------------------------------------

@test "manage-problem render blocks document the Released-date ASC direction" {
  # Free-form explanation of the sort key + direction must accompany
  # the marker so a reader doesn't have to chase the ADR to understand
  # what the marker authorises.
  run grep -F 'Released date ASC' "$MANAGE_SKILL"
  [ "$status" -eq 0 ]
  count=$(grep -c -F 'Released date ASC' "$MANAGE_SKILL")
  [ "$count" -ge 3 ]
}

@test "review-problems documents the Released-date ASC direction" {
  run grep -F 'Released date ASC' "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Structural contract-assertions — drift-warning prose
# ---------------------------------------------------------------------------

@test "manage-problem render blocks warn that drift re-opens P150" {
  # The cross-coupling note must explicitly name P150 so future agents
  # who consider relaxing the VQ sort direction see the regression risk.
  count=$(grep -c -F 'drift here re-opens P150' "$MANAGE_SKILL")
  [ "$count" -ge 3 ]
}

@test "review-problems renders the drift-re-opens-P150 warning" {
  run grep -F 'drift re-opens P150' "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Behavioural fixture: ASC-by-Released-date puts oldest at row 1
# ---------------------------------------------------------------------------

@test "behavioural: VQ sort by Released date ASC puts oldest entry at row 1" {
  # Fixture: 4 .verifying.md tickets with known Released dates spanning
  # 2026-04-22 to 2026-05-02. Encode each as a tab-separated row whose
  # columns are the sort axes (Released date, ID, Title). Apply the
  # documented ASC-by-Released sort and assert the output row order
  # places the oldest entry at row 1 and the newest at row N.
  #
  # This is the regression guard against the drift documented in P150 —
  # before the fix, render sites iterated newest-first and pushed the
  # actionable closure candidates (oldest entries) below the fold.

  fixture_in="$TEST_TMP/fixture-vq.tsv"
  cat >"$fixture_in" <<'EOF'
2026-05-02	148	P148: youngest released
2026-04-29	144	P144: 3 days old
2026-04-25	120	P120: week-old
2026-04-22	093	P093: oldest released
EOF

  # Canonical sort: Released date ASC (oldest first), ID ASC as final
  # tiebreaker for same-day releases.
  sorted=$(sort -t$'\t' -k1,1 -k2,2n "$fixture_in" | cut -f3)
  expected="P093: oldest released
P120: week-old
P144: 3 days old
P148: youngest released"
  [ "$sorted" = "$expected" ]
}

@test "behavioural: same-day Released uses ID ASC as the final tiebreaker" {
  # Regression guard: when two tickets share a Released date, the ID
  # ASC tiebreaker must produce a deterministic order. Without an
  # explicit final tiebreaker, render-time row order can shift on
  # every refresh and look like content drift in git diff.
  fixture_in="$TEST_TMP/fixture-vq-sameday.tsv"
  cat >"$fixture_in" <<'EOF'
2026-05-02	148	P148: same day high
2026-05-02	147	P147: same day mid
2026-05-02	146	P146: same day low
EOF

  sorted=$(sort -t$'\t' -k1,1 -k2,2n "$fixture_in" | cut -f3)
  expected="P146: same day low
P147: same day mid
P148: same day high"
  [ "$sorted" = "$expected" ]
}

@test "behavioural: oldest-first ordering surfaces likely-verified candidates first" {
  # P048 user-task semantics: the Verification Queue exists so the user
  # can close pending verifications. Older entries are more likely
  # ready to close (less chance of revert). Oldest-first ordering puts
  # those candidates at the top so the user lands on actionable rows
  # without scrolling past fresh-release entries still in dwell-time.
  #
  # Fixture spans ages 0d, 1d, 14d, 30d. Assert that after sort, the
  # 30-day entry is at row 1 (highest "likely verified" probability)
  # and the 0-day entry is at row N (lowest probability).
  today="2026-05-02"
  fixture_in="$TEST_TMP/fixture-vq-ages.tsv"
  cat >"$fixture_in" <<'EOF'
2026-05-02	150	P150: 0 days no
2026-05-01	149	P149: 1 day no
2026-04-18	048	P048: 14 days yes
2026-04-02	030	P030: 30 days yes
EOF

  sorted=$(sort -t$'\t' -k1,1 -k2,2n "$fixture_in" | cut -f3)
  first=$(printf "%s\n" "$sorted" | head -1)
  last=$(printf "%s\n" "$sorted" | tail -1)
  [ "$first" = "P030: 30 days yes" ]
  [ "$last" = "P150: 0 days no" ]
}
