#!/usr/bin/env bats

# P138: docs/problems/README.md WSJF Rankings table row order must match
# /wr-itil:work-problems SKILL.md Step 3's tie-break selection 1:1, and
# the table must include a Reported date column so the third tie-break
# input is visible to README readers.
#
# ADR-076: selection partitions into three tiers ABOVE the WSJF ladder —
#   Tier 0 Critical-bypass (Severity >=17 OR security OR incident-linked)
#   Tier 1 Inbound-reported (**Origin**: inbound-reported)
#   Tier 2 Internal
# The tier dominates WSJF; within each tier the existing P138 ladder
# applies unchanged. Each render site carries a REPORTED-FIRST-TIER-SOURCE
# marker and an Origin column. Drift re-opens P138 / ADR-076.
#
# Hybrid coverage per ADR-005 + ADR-037:
#   - Structural contract-assertions (Permitted Exception per ADR-005 /
#     contract-assertion pattern per ADR-037): each of the five render-
#     block sites carries the canonical TIE-BREAK-LADDER-SOURCE marker
#     and the Reported column.
#   - One behavioural fixture sort: 4 tickets with equal WSJF differing
#     by Status / Effort / Reported. Apply the documented multi-key
#     sort. Assert the output row order matches the tie-break ladder
#     result derived from /wr-itil:work-problems Step 3 selection rules.
#
# @problem P138
# @jtbd JTBD-001 (enforce governance without slowing down — predictable
#   orchestrator behaviour visible from rendered README)
# @jtbd JTBD-006 (progress backlog AFK — README and orchestrator agree
#   on next ticket)
#
# Cross-reference:
#   P138: docs/problems/138-readme-wsjf-row-order-doesnt-match-work-problems-tie-break.*.md
#   ADR-005 — plugin testing strategy / Permitted Exception
#   ADR-037 — contract-assertion bats pattern
#   ADR-044 — decision delegation contract; tie-break ladder is framework-resolved

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  MANAGE_SKILL="$REPO_ROOT/packages/itil/skills/manage-problem/SKILL.md"
  REVIEW_SKILL="$REPO_ROOT/packages/itil/skills/review-problems/SKILL.md"
  WORK_SKILL="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"

  TEST_TMP="$(mktemp -d)"
}

teardown() {
  if [ -n "${TEST_TMP:-}" ] && [ -d "$TEST_TMP" ]; then
    rm -rf "$TEST_TMP"
  fi
}

# ---------------------------------------------------------------------------
# Structural contract-assertions — TIE-BREAK-LADDER-SOURCE marker
# ---------------------------------------------------------------------------

@test "manage-problem Step 5 P094 (refresh on new ticket) carries the TIE-BREAK-LADDER-SOURCE marker" {
  # P138 Phase 2: each render block must carry the canonical greppable
  # marker pointing back to /wr-itil:work-problems Step 3 (the
  # framework-resolved source of the tie-break ladder per ADR-044).
  # Drift across the render sites re-opens P138.
  run grep -F '<!-- TIE-BREAK-LADDER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 -->' "$MANAGE_SKILL"
  [ "$status" -eq 0 ]
  # Marker must appear at multiple sites (Step 5 P094, Step 7 P062, Step 9e).
  count=$(grep -c -F '<!-- TIE-BREAK-LADDER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 -->' "$MANAGE_SKILL")
  [ "$count" -ge 3 ]
}

@test "review-problems Step 3 (Present the refreshed ranking) carries the TIE-BREAK-LADDER-SOURCE marker" {
  run grep -F '<!-- TIE-BREAK-LADDER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 -->' "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
}

@test "work-problems Step 1 (Scan the backlog) carries the TIE-BREAK-LADDER-SOURCE marker" {
  run grep -F '<!-- TIE-BREAK-LADDER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 -->' "$WORK_SKILL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Structural contract-assertions — multi-key sort spec wording
# ---------------------------------------------------------------------------

@test "manage-problem render blocks document the multi-key sort spec verbatim" {
  # The exact spec must appear so the agent applying the render produces
  # the same row order as /wr-itil:work-problems Step 3.
  run grep -F '(WSJF desc, Known-Error-first, Effort-divisor asc, Reported-date asc, ID asc)' "$MANAGE_SKILL"
  [ "$status" -eq 0 ]
  count=$(grep -c -F '(WSJF desc, Known-Error-first, Effort-divisor asc, Reported-date asc, ID asc)' "$MANAGE_SKILL")
  [ "$count" -ge 3 ]
}

@test "review-problems documents the multi-key sort spec verbatim" {
  run grep -F '(WSJF desc, Known-Error-first, Effort-divisor asc, Reported-date asc, ID asc)' "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
}

@test "work-problems Step 1 documents the multi-key sort spec verbatim" {
  run grep -F '(WSJF desc, Known-Error-first, Effort-divisor asc, Reported-date asc, ID asc)' "$WORK_SKILL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Structural contract-assertions — Reported column present in templates
# ---------------------------------------------------------------------------

@test "manage-problem Step 9e README template includes the Reported column" {
  # The Step 9e block writes the README template that downstream renderings
  # copy. Without the Reported column in the template, the third tie-break
  # input remains invisible to README readers and P138 recurs.
  run grep -F '| WSJF | ID | Title | Severity | Status | Effort | Reported |' "$MANAGE_SKILL"
  [ "$status" -eq 0 ]
}

@test "review-problems Step 5 README template includes the Reported column" {
  run grep -F '| WSJF | ID | Title | Severity | Status | Effort | Reported |' "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Structural contract-assertions — cross-coupling drift warning
# ---------------------------------------------------------------------------

@test "manage-problem render blocks warn that drift re-opens P138" {
  # The cross-coupling note must explicitly name P138 so future agents
  # who consider relaxing the multi-key sort see the regression risk.
  count=$(grep -c -F 'drift here re-opens P138' "$MANAGE_SKILL")
  [ "$count" -ge 3 ]
}

@test "review-problems renders the drift-re-opens-P138 warning" {
  run grep -F 'drift re-opens P138' "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Behavioural fixture: multi-key sort produces tie-break-ladder order
# ---------------------------------------------------------------------------

@test "behavioural: multi-key sort on 4 same-WSJF tickets matches tie-break ladder order" {
  # Fixture: 4 tickets all at WSJF 6.0, differing by Status / Effort /
  # Reported date. Encode each as a tab-separated row whose columns are
  # the multi-key sort axes (WSJF, KE_flag where 0=KE+1=Open, Effort
  # divisor, Reported date, ID, Title). Apply the documented sort and
  # assert the output row order matches the tie-break ladder result.
  #
  # Tickets:
  #   T1: Open, S, Reported 2026-04-27, severity 6, WSJF 6.0
  #   T2: Open, M, Reported 2026-04-26, severity 12, WSJF 6.0
  #   T3: KE,   S, Reported 2026-04-25, severity 3,  WSJF 6.0  (3*2/1=6.0)
  #   T4: KE,   M, Reported 2026-04-24, severity 6,  WSJF 6.0  (6*2/2=6.0)
  #
  # Tie-break ladder per /wr-itil:work-problems Step 3:
  #   1. Known-Error first → T3, T4 before T1, T2
  #   2. Smaller effort first → T3 (S) before T4 (M); T1 (S) before T2 (M)
  #   3. Older reported date first → not exercised here because effort
  #      already distinguishes within Status (intentional: this is the
  #      same shape as a real backlog).
  #
  # Expected order: T3, T4, T1, T2
  #
  # NB: Reported-date field is included in the sort key but not exercised
  # by this fixture (effort distinguishes pairs). The Reported-only test
  # below adds explicit coverage of the third tie-break level.

  fixture_in="$TEST_TMP/fixture.tsv"
  cat >"$fixture_in" <<'EOF'
6.0	1	1	2026-04-27	201	T1: Open S
6.0	1	2	2026-04-26	202	T2: Open M
6.0	0	1	2026-04-25	203	T3: KE S
6.0	0	2	2026-04-24	204	T4: KE M
EOF

  # Multi-key sort spec from SKILL.md:
  #   k1: WSJF desc           -> -k1,1nr
  #   k2: KE_flag asc (0 KE)  -> -k2,2n
  #   k3: Effort divisor asc  -> -k3,3n
  #   k4: Reported asc        -> -k4,4
  #   k5: ID asc              -> -k5,5n
  sorted=$(sort -t$'\t' -k1,1nr -k2,2n -k3,3n -k4,4 -k5,5n "$fixture_in" | cut -f6)
  expected="T3: KE S
T4: KE M
T1: Open S
T2: Open M"
  [ "$sorted" = "$expected" ]
}

@test "behavioural: multi-key sort exercises the third tie-break level (Reported date) when Status + Effort tie" {
  # Fixture: 3 tickets all at WSJF 6.0, all KE, all Effort S, differing
  # only by Reported date and ID. The first two tie-break levels do not
  # distinguish them; only the Reported-date axis decides the order.
  # This is the explicit regression guard for the third tie-break level
  # being silently dropped — exactly the failure mode P138 documents.
  #
  # Expected order (older Reported first, then ID asc as final tiebreak):
  #   T_a (Reported 2026-04-22) → T_b (Reported 2026-04-25) → T_c (Reported 2026-04-27)
  fixture_in="$TEST_TMP/fixture-reported.tsv"
  cat >"$fixture_in" <<'EOF'
6.0	0	1	2026-04-25	302	T_b: KE S older
6.0	0	1	2026-04-27	303	T_c: KE S newest
6.0	0	1	2026-04-22	301	T_a: KE S oldest
EOF

  sorted=$(sort -t$'\t' -k1,1nr -k2,2n -k3,3n -k4,4 -k5,5n "$fixture_in" | cut -f6)
  expected="T_a: KE S oldest
T_b: KE S older
T_c: KE S newest"
  [ "$sorted" = "$expected" ]
}

@test "behavioural: tie-break flips when WSJF differs (sort respects k1 first)" {
  # Regression guard: ensure the multi-key sort doesn't reorder across
  # WSJF tiers. A higher-WSJF Open ticket must outrank a lower-WSJF KE
  # ticket — the WSJF axis dominates the Status axis.
  fixture_in="$TEST_TMP/fixture-tiers.tsv"
  cat >"$fixture_in" <<'EOF'
6.0	0	2	2026-04-20	401	T_low: KE M low-WSJF
12.0	1	1	2026-04-30	402	T_high: Open S high-WSJF
EOF

  sorted=$(sort -t$'\t' -k1,1nr -k2,2n -k3,3n -k4,4 -k5,5n "$fixture_in" | cut -f6)
  expected="T_high: Open S high-WSJF
T_low: KE M low-WSJF"
  [ "$sorted" = "$expected" ]
}

# ---------------------------------------------------------------------------
# ADR-076 structural contract-assertions — reported-first tier
# ---------------------------------------------------------------------------

@test "manage-problem render blocks carry the REPORTED-FIRST-TIER-SOURCE marker (ADR-076)" {
  # Each WSJF Rankings render block must carry the greppable tier marker
  # pointing back to /wr-itil:work-problems Step 3 (the canonical tier
  # source). Drift across render sites re-opens ADR-076.
  run grep -F '<!-- REPORTED-FIRST-TIER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 (ADR-076) -->' "$MANAGE_SKILL"
  [ "$status" -eq 0 ]
  # Step 5 P094, Step 7 P062, Step 9c presentation, Step 9e template.
  count=$(grep -c -F '<!-- REPORTED-FIRST-TIER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 (ADR-076) -->' "$MANAGE_SKILL")
  [ "$count" -ge 3 ]
}

@test "review-problems carries the REPORTED-FIRST-TIER-SOURCE marker (ADR-076)" {
  run grep -F '<!-- REPORTED-FIRST-TIER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 (ADR-076) -->' "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
}

@test "work-problems carries the REPORTED-FIRST-TIER-SOURCE marker (ADR-076)" {
  run grep -F '<!-- REPORTED-FIRST-TIER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 (ADR-076) -->' "$WORK_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem + review-problems README templates include the Origin column (ADR-076)" {
  # Tier 1 (inbound-reported) membership must be visible to README readers,
  # mirroring the Reported-column rationale for the third tie-break level.
  run grep -F '| WSJF | ID | Title | Severity | Status | Effort | Reported | Origin |' "$MANAGE_SKILL"
  [ "$status" -eq 0 ]
  run grep -F '| WSJF | ID | Title | Severity | Status | Effort | Reported | Origin |' "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem ticket template defines the Origin field (ADR-076)" {
  run grep -F '**Origin**: internal' "$MANAGE_SKILL"
  [ "$status" -eq 0 ]
}

@test "render blocks warn that drift re-opens ADR-076" {
  count=$(grep -c -F 're-opens P138 / ADR-076' "$MANAGE_SKILL")
  [ "$count" -ge 3 ]
}

# ---------------------------------------------------------------------------
# ADR-076 behavioural fixture: tier partition dominates the WSJF ladder
# ---------------------------------------------------------------------------

@test "behavioural: tier partition outranks WSJF — critical-bypass + reported beat higher-WSJF internal" {
  # Fixture columns: tier  WSJF  KE_flag  Effort  Reported  ID  Title
  #   tier: 0=critical-bypass, 1=inbound-reported, 2=internal
  #
  # The full selection key is tier ASC (k1) dominating, then the existing
  # P138 ladder within tier: WSJF desc (k2), KE-first (k3), Effort asc (k4),
  # Reported asc (k5), ID asc (k6).
  #
  # Tickets:
  #   C: critical-bypass, WSJF 2.0  (Severity 20 Open XL) — lowest WSJF
  #   R: inbound-reported, WSJF 3.0 (Severity 6 Open M)
  #   I: internal, WSJF 16.0        (Severity 8 KE S)     — highest WSJF
  #
  # Without the tier, I (WSJF 16.0) would top the queue. With ADR-076 the
  # tier dominates: C → R → I. This is the regression guard that the most
  # critical issues come first and reported beats internal regardless of WSJF.
  fixture_in="$TEST_TMP/fixture-tier.tsv"
  cat >"$fixture_in" <<'EOF'
2	16.0	0	1	2026-05-20	502	I: internal high-WSJF
0	2.0	1	8	2026-05-10	501	C: critical low-WSJF
1	3.0	1	2	2026-05-15	503	R: reported mid-WSJF
EOF

  # k1 tier asc; k2 WSJF desc; k3 KE_flag asc; k4 Effort asc; k5 Reported asc; k6 ID asc
  sorted=$(sort -t$'\t' -k1,1n -k2,2nr -k3,3n -k4,4n -k5,5 -k6,6n "$fixture_in" | cut -f7)
  expected="C: critical low-WSJF
R: reported mid-WSJF
I: internal high-WSJF"
  [ "$sorted" = "$expected" ]
}

@test "behavioural: within a tier, the existing WSJF + tie-break ladder still applies (ADR-076)" {
  # Two inbound-reported tickets in the same tier must order by the
  # unchanged within-tier ladder: higher WSJF first, then KE-first.
  fixture_in="$TEST_TMP/fixture-within-tier.tsv"
  cat >"$fixture_in" <<'EOF'
1	6.0	1	1	2026-05-12	601	R_low: reported WSJF 6
1	12.0	0	2	2026-05-11	602	R_high: reported WSJF 12
EOF

  sorted=$(sort -t$'\t' -k1,1n -k2,2nr -k3,3n -k4,4n -k5,5 -k6,6n "$fixture_in" | cut -f7)
  expected="R_high: reported WSJF 12
R_low: reported WSJF 6"
  [ "$sorted" = "$expected" ]
}
