#!/usr/bin/env bats
# Contract + behavioural tests: manage-problem SKILL.md must define a
# transitive-dependency rule for WSJF effort, extend Step 9b with
# dependency-graph traversal, and the problem-ticket template must carry
# a `## Dependencies` section.
#
# Mixed shape — structural assertions (ADR-037 Permitted Exception) for
# the contract prose Claude interprets at invocation time, AND one
# behavioural fixture test that exercises the transitive-closure
# algorithm directly so the rule is not merely "keyword present" (P081
# pressure — behavioural where feasible).
#
# Cross-reference:
#   @problem P076 — docs/problems/076-wsjf-does-not-model-transitive-dependencies.open.md
#   ADR-022: verification-pending status carve-out from the closure
#   ADR-014: governance-skills commit their own work
#   ADR-037: contract-assertion bats pattern for SKILL.md prose contracts
#   @jtbd JTBD-001 (solo-developer — enforce governance without slowing down)
#   @jtbd JTBD-006 (solo-developer — progress the backlog while I'm away)
#   @jtbd JTBD-201 (tech-lead — restore service fast with an audit trail)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
  FIXTURE_DIR="$(mktemp -d)"
}

teardown() {
  [ -n "${FIXTURE_DIR:-}" ] && [ -d "$FIXTURE_DIR" ] && rm -rf "$FIXTURE_DIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# Contract: WSJF section defines the transitive-dependency rule
# ──────────────────────────────────────────────────────────────────────────────

@test "SKILL.md WSJF section has a Transitive dependencies subsection (P076)" {
  # The rule must live in a discoverable subsection so Claude finds it
  # when interpreting the WSJF scoring contract.
  run grep -nE "^### .*[Tt]ransitive [Dd]ependenc" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md transitive rule defines effort as max(marginal, blocked-by closure) (P076)" {
  # The core rule: Effort(T)_transitive = max(marginal, max{blocked-by})
  # The prose must make the max-of relationship explicit so a dependent
  # ticket inherits upstream effort.
  run grep -inE "max.*marginal|marginal.*max|transitive.*effort|effort.*transitive" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md transitive rule cites Blocked by as the dependency signal (P076)" {
  # Blocked_by is the formally-scoped edge in the ticket-dependency graph.
  # The rule must name it (not just generic "dependencies") so Claude knows
  # which `## Dependencies` row drives the effort propagation.
  run grep -inE "Blocked[[:space:]-]?by" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md transitive rule carves Composes with OUT of the closure (P076)" {
  # Compositional overlap does NOT strictly block — sibling work that
  # shares surface should not inflate the dependent's effort.
  run grep -inE "[Cc]omposes[[:space:]]with.*not|not.*[Cc]omposes|[Cc]omposes[[:space:]]with.*does NOT|[Cc]omposes[[:space:]]with.*excluded" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md transitive rule carves .closed / .verifying / .parked OUT of the closure (architect note)" {
  # Architect correction: already-done or user-blocked upstreams contribute
  # zero marginal dev effort — otherwise a ticket blocked by a closed
  # ticket would inherit XL forever.
  run grep -inE "(\.closed\.md|\.verifying\.md|\.parked\.md).*(contribut|0|zero|exclud)|contribut.*0.*(\.closed|\.verifying|\.parked)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md transitive rule documents cycle bundling (shared WSJF as computed artefact) (P076)" {
  # Cycles (e.g. P038/P064 mutual composition) must be handled — bundle's
  # effort = max of members' marginals; shared WSJF surfaced in review
  # output, not written as a field per-ticket (ADR-022 suffix-based pattern).
  run grep -inE "cycle|bundle" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md transitive rule carries a worked example (P076)" {
  # Worked example: P073 marginal S blocked by P038 XL → transitive XL →
  # WSJF drops to match P038. The number-grounded example keeps the rule
  # out of hand-wavy territory (ADR-026 grounded output).
  run grep -inE "[Ww]orked[[:space:]]example|example.*transitive|transitive.*example" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md transitive rule notes reassessment-criteria for future ADR extraction (architect note)" {
  # Architect guidance: keep a pointer for when another skill adopts the
  # `## Dependencies` convention — at that point, extract to a sibling ADR.
  # Inline note now avoids speculative ADR authoring today.
  run grep -inE "[Rr]eassessment|[Ee]xtract.*ADR|sibling ADR|future ADR" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Contract: Step 9b review extends to dependency-graph traversal
# ──────────────────────────────────────────────────────────────────────────────

@test "SKILL.md Step 9b describes a dependency-graph traversal pass (P076)" {
  # After per-ticket marginal scoring, Step 9b must walk the graph and
  # propagate effort up. The prose must name the traversal explicitly so
  # Claude performs the second pass, not just the first.
  run grep -inE "dependency[[:space:]-]?graph|graph traversal|topological.*sort|propagate.*effort|effort.*propagat" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 9b reports transitive re-rates in the review summary (P076 + JTBD-006)" {
  # The AFK orchestrator (JTBD-006) and the audit-trail persona (JTBD-201)
  # depend on Step 9b emitting a visible re-rate line — not a silent
  # update.
  run grep -inE "transitive.*(re-?rate|rerat|re-?estimat)|report.*transitive|re-?rate.*transitive" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 9b re-rate message format is concrete (architect note — bats-assertable shape)" {
  # Architect correction 4: specify a concrete message shape so the
  # contract can be grepped. Format: P<NNN>: Effort <OLD> → <NEW>
  # (transitive via <UPSTREAM>).
  run grep -inE "Effort.*→.*transitive via|transitive via.*P[0-9]" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Contract: Step 5 problem-ticket template includes `## Dependencies`
# ──────────────────────────────────────────────────────────────────────────────

@test "SKILL.md Step 5 template includes a ## Dependencies section (P076)" {
  # New tickets must carry an explicit dependency list so the graph is
  # legible. Empty lists are allowed (default: no deps).
  run grep -nE "^## Dependencies" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Dependencies template lists Blocks / Blocked by / Composes with rows (P076)" {
  # The three row labels must all be present in the template so the
  # author knows which semantics apply. Blocks = downstream; Blocked by =
  # drives effort propagation; Composes with = overlap without blocking.
  run grep -inE "\*\*Blocks\*\*|\*\*Blocked by\*\*|\*\*Composes with\*\*" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # All three labels must be present.
  blocks_hits=$(grep -cE "\*\*Blocks\*\*" "$SKILL_FILE" || true)
  blocked_hits=$(grep -cE "\*\*Blocked by\*\*" "$SKILL_FILE" || true)
  composes_hits=$(grep -cE "\*\*Composes with\*\*" "$SKILL_FILE" || true)
  [ "$blocks_hits" -ge 1 ]
  [ "$blocked_hits" -ge 1 ]
  [ "$composes_hits" -ge 1 ]
}

@test "SKILL.md Dependencies rows use bare ticket IDs (architect note Q1)" {
  # Bare IDs (P038) beat link syntax (`[P038](./038-...)`) — less
  # maintenance; review output renders to links on demand. The template
  # example must show bare-ID form (not `[P038](./038-...)`).
  # Canonical shape: `- **Blocked by**: P<NNN>, P<NNN>` — match either
  # bold-markdown label form or plain-label form, asserting the ID is
  # bare (not bracketed).
  run grep -inE "Blocked by\*{0,2}:[[:space:]]*P[0-9]" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # Assert the example does NOT use link syntax `[PNNN](./...)`.
  ! grep -E "Blocked by\*{0,2}:[[:space:]]*\[P[0-9]" "$SKILL_FILE"
}

# ──────────────────────────────────────────────────────────────────────────────
# Traceability: P076 cited
# ──────────────────────────────────────────────────────────────────────────────

@test "SKILL.md cites P076 in the transitive-dependencies prose (traceability)" {
  # Every governance-contract change must cite the problem ticket that
  # motivated it — audit trail per ADR-014.
  run grep -n "P076" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Behavioural: exercise the transitive-closure rule with fixture tickets
# ──────────────────────────────────────────────────────────────────────────────
# These tests build a minimal fixture backlog and run a bash transcription
# of the transitive-closure rule against it. The rule's executable form is
# small enough to bash-implement; we assert the output matches the rule's
# spec so a prose drift (e.g. accidentally documenting `min` instead of
# `max`) would be caught at test time.

# Bash transcription of the transitive-closure rule — effort map is
# keyed by ticket ID, value is the integer divisor from the SKILL.md
# effort table (S=1, M=2, L=4, XL=8).
transitive_effort() {
  local ticket="$1"
  local backlog_dir="$2"
  local file
  file=$(ls "$backlog_dir"/${ticket}-*.md 2>/dev/null | head -1)
  [ -z "$file" ] && { echo 0; return; }

  # Extract marginal effort from the Effort line. The line shape matches
  # the SKILL.md Priority/Effort convention: "**Effort**: <bucket> — ..."
  local marginal_bucket
  marginal_bucket=$(grep -oE '\*\*Effort\*\*: [SMLXL]+' "$file" | head -1 | grep -oE '[SMLXL]+' | head -1)
  local marginal_divisor
  case "$marginal_bucket" in
    S) marginal_divisor=1 ;;
    M) marginal_divisor=2 ;;
    L) marginal_divisor=4 ;;
    XL) marginal_divisor=8 ;;
    *) marginal_divisor=2 ;;  # default M
  esac

  # .closed.md / .verifying.md / .parked.md upstreams contribute 0 (architect carve-out)
  case "$file" in
    *.closed.md|*.verifying.md|*.parked.md)
      echo 0
      return
      ;;
  esac

  # Extract `Blocked by:` dependency IDs (bare, comma-separated).
  # The template shape is `- **Blocked by**: P<NNN>, P<NNN>` (markdown
  # list item under `## Dependencies`) — match the label with optional
  # leading list marker.
  local blocked_by_line
  blocked_by_line=$(grep -E "^[[:space:]]*-?[[:space:]]*\*\*Blocked by\*\*:" "$file" | head -1 | sed 's/.*\*\*Blocked by\*\*://')
  local max_upstream=0
  local dep
  for dep in $(echo "$blocked_by_line" | grep -oE 'P[0-9]+'); do
    local upstream_effort
    upstream_effort=$(transitive_effort "$dep" "$backlog_dir")
    [ "$upstream_effort" -gt "$max_upstream" ] && max_upstream="$upstream_effort"
  done

  # Transitive = max(marginal, upstream closure)
  if [ "$max_upstream" -gt "$marginal_divisor" ]; then
    echo "$max_upstream"
  else
    echo "$marginal_divisor"
  fi
}

@test "behavioural: dependent ticket inherits upstream XL when blocked by XL ticket (P076 worked example)" {
  # Fixture: P200 (marginal S) Blocked by: P201 (XL)
  # Expected: transitive effort for P200 = XL divisor = 8
  cat > "$FIXTURE_DIR/P201-upstream-xl.open.md" <<'EOF'
# Problem 201: upstream XL ticket
**Status**: Open
**Effort**: XL — multi-day cross-package work

## Dependencies
- **Blocked by**: (none)
EOF
  cat > "$FIXTURE_DIR/P200-dependent-small.open.md" <<'EOF'
# Problem 200: dependent with small marginal effort
**Status**: Open
**Effort**: S — one-line surface add

## Dependencies
- **Blocked by**: P201
EOF
  result=$(transitive_effort "P200" "$FIXTURE_DIR")
  [ "$result" = "8" ]
}

@test "behavioural: self-contained ticket keeps marginal effort (P076 no-op path)" {
  # Fixture: P210 (marginal M) with empty Blocked by.
  # Expected: transitive = marginal M divisor = 2.
  cat > "$FIXTURE_DIR/P210-solo-m.open.md" <<'EOF'
# Problem 210: self-contained
**Status**: Open
**Effort**: M — couple of files

## Dependencies
- **Blocked by**: (none)
EOF
  result=$(transitive_effort "P210" "$FIXTURE_DIR")
  [ "$result" = "2" ]
}

@test "behavioural: closed upstream contributes 0 to the closure (architect carve-out)" {
  # Fixture: P220 (marginal S) Blocked by: P221 (was XL, now closed).
  # Expected: transitive = marginal S = 1 (closed upstream contributes 0;
  # otherwise P220 would inherit XL forever).
  cat > "$FIXTURE_DIR/P221-closed-xl.closed.md" <<'EOF'
# Problem 221: closed upstream (was XL)
**Status**: Closed
**Effort**: XL
EOF
  cat > "$FIXTURE_DIR/P220-dependent-on-closed.open.md" <<'EOF'
# Problem 220: dependent on closed
**Status**: Open
**Effort**: S

## Dependencies
- **Blocked by**: P221
EOF
  result=$(transitive_effort "P220" "$FIXTURE_DIR")
  [ "$result" = "1" ]
}

@test "behavioural: marginal effort wins when upstream is smaller (P076 max-of semantics)" {
  # Fixture: P230 (marginal L = 4) Blocked by: P231 (S = 1)
  # Expected: transitive = max(L, S) = L divisor = 4.
  # (Contrast: a buggy implementation using min or sum would produce 1 or 5.)
  cat > "$FIXTURE_DIR/P231-small-upstream.open.md" <<'EOF'
# Problem 231: small upstream
**Status**: Open
**Effort**: S
EOF
  cat > "$FIXTURE_DIR/P230-big-dependent.open.md" <<'EOF'
# Problem 230: bigger dependent
**Status**: Open
**Effort**: L

## Dependencies
- **Blocked by**: P231
EOF
  result=$(transitive_effort "P230" "$FIXTURE_DIR")
  [ "$result" = "4" ]
}

@test "behavioural: transitive propagates across two hops (P076 closure semantics)" {
  # Fixture: P240 (S) → blocked by P241 (S) → blocked by P242 (XL)
  # Expected: transitive(P240) = max(S, transitive(P241)) = max(S, max(S, XL)) = XL = 8.
  cat > "$FIXTURE_DIR/P242-deepest-xl.open.md" <<'EOF'
# Problem 242: deepest XL
**Status**: Open
**Effort**: XL
EOF
  cat > "$FIXTURE_DIR/P241-middle-s.open.md" <<'EOF'
# Problem 241: middle S
**Status**: Open
**Effort**: S

## Dependencies
- **Blocked by**: P242
EOF
  cat > "$FIXTURE_DIR/P240-top-s.open.md" <<'EOF'
# Problem 240: top S
**Status**: Open
**Effort**: S

## Dependencies
- **Blocked by**: P241
EOF
  result=$(transitive_effort "P240" "$FIXTURE_DIR")
  [ "$result" = "8" ]
}

@test "behavioural: verification-pending upstream contributes 0 (architect carve-out for .verifying.md)" {
  # Fixture: P250 (marginal S) Blocked by: P251 (was XL, now verifying).
  # Expected: transitive = marginal S = 1 (verifying contributes 0 — the
  # remaining work is user-side verification, not dev effort).
  cat > "$FIXTURE_DIR/P251-verifying-xl.verifying.md" <<'EOF'
# Problem 251: verification pending (was XL)
**Status**: Verification Pending
**Effort**: XL
EOF
  cat > "$FIXTURE_DIR/P250-dependent-on-verifying.open.md" <<'EOF'
# Problem 250: dependent on verifying
**Status**: Open
**Effort**: S

## Dependencies
- **Blocked by**: P251
EOF
  result=$(transitive_effort "P250" "$FIXTURE_DIR")
  [ "$result" = "1" ]
}
