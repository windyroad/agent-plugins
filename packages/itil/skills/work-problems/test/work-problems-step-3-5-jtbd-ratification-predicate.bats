#!/usr/bin/env bats

# Step 3.5 behavioural fixture per RFC-016 + P344:
# work-problems orchestrator predicate-checks the cited JTBDs of the
# selected ticket BEFORE dispatching the iter-worker. The predicate
# decision lives in `packages/itil/scripts/check-ticket-jtbd-ratification.sh`
# so the SKILL.md Step 3.5 prose is a thin source-and-call wrapper around
# a behaviorally-testable shell script (P081 / user feedback: prefer
# behavioural over structural-grep tests).
#
# Polarity (RFC-016 § Scope):
#   exit 0 = all cited JTBDs ratified (or none cited) → orchestrator proceeds
#            with the dispatch
#   exit 1 = ≥1 cited JTBD unratified; one ID per stdout line, `(unresolved)`
#            tag for the per-JTBD predicate's exit-2 cases → orchestrator
#            routes to user-answerable skip + queues outstanding_question
#   exit 2 = ticket file missing / unreadable → halt
#
# Cases covered (per RFC-016 § Verification + § Tasks bats coverage):
#   1. Helper exists at the contracted PATH-shim location.
#   2. Ticket cites no JTBDs at all → exit 0 (vacuous-pass).
#   3. Ticket cites a ratified JTBD (frontmatter `human-oversight: confirmed`)
#      → exit 0.
#   4. Ticket cites an unratified JTBD → exit 1 + ID on stdout.
#   5. Ticket cites an unresolved JTBD ID (no matching JTBD file) → exit 1
#      + `(unresolved)` tag.
#   6. Ticket file missing → exit 2.
#   7. Missing per-JTBD predicate shim → silent-pass exit 0 (ADR-031
#      degenerate adopter case).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SHIM="$REPO_ROOT/packages/itil/bin/wr-itil-check-ticket-jtbd-ratification"

  FIXTURE="$(mktemp -d)"
  mkdir -p "$FIXTURE/docs/jtbd/developer"
  mkdir -p "$FIXTURE/docs/problems/open"

  # Shim search PATH: put the real per-JTBD predicate shim on PATH so the
  # helper can dispatch it. The helper resolves shims through PATH per
  # ADR-049 — no source-relative paths.
  export PATH="$REPO_ROOT/packages/jtbd/bin:$PATH"
}

teardown() {
  rm -rf "$FIXTURE"
}

@test "shim exists at the contracted PATH location" {
  [ -f "$SHIM" ]
  [ -x "$SHIM" ]
}

@test "case 1: ticket cites no JTBDs → exit 0 (vacuous-pass)" {
  cat > "$FIXTURE/docs/problems/open/999-no-jtbds.md" <<'EOF'
# Problem 999: ticket with no JTBD citations

**Status**: Open

## Description

This ticket has no Decision Drivers section and no JTBD citations.
EOF
  cd "$FIXTURE"
  run "$SHIM" "docs/problems/open/999-no-jtbds.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "case 2: ticket cites a ratified JTBD → exit 0" {
  cat > "$FIXTURE/docs/jtbd/developer/JTBD-501-ratified.md" <<'EOF'
---
human-oversight: confirmed
---

# JTBD-501: A ratified job
EOF
  cat > "$FIXTURE/docs/problems/open/998-cites-ratified.md" <<'EOF'
# Problem 998: cites a ratified JTBD

## Decision Drivers

- JTBD-501 — A ratified job
EOF
  cd "$FIXTURE"
  run "$SHIM" "docs/problems/open/998-cites-ratified.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "case 3: ticket cites an unratified JTBD → exit 1 + ID stdout" {
  # Unratified = no `human-oversight: confirmed` frontmatter.
  cat > "$FIXTURE/docs/jtbd/developer/JTBD-502-unratified.md" <<'EOF'
---
status: proposed
---

# JTBD-502: An unratified job (no human-oversight: confirmed)
EOF
  cat > "$FIXTURE/docs/problems/open/997-cites-unratified.md" <<'EOF'
# Problem 997: cites an unratified JTBD

## Decision Drivers

- JTBD-502 — An unratified job
EOF
  cd "$FIXTURE"
  run "$SHIM" "docs/problems/open/997-cites-unratified.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"JTBD-502"* ]]
}

@test "case 4: ticket cites an unresolved JTBD ID → exit 1 + (unresolved) tag" {
  cat > "$FIXTURE/docs/problems/open/996-cites-unresolved.md" <<'EOF'
# Problem 996: cites an unresolved JTBD ID

## Decision Drivers

- JTBD-999 — Does not exist
EOF
  cd "$FIXTURE"
  run "$SHIM" "docs/problems/open/996-cites-unresolved.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"JTBD-999"* ]]
  [[ "$output" == *"(unresolved)"* ]]
}

@test "case 5: ticket file missing → exit 2" {
  cd "$FIXTURE"
  run "$SHIM" "docs/problems/open/nonexistent.md"
  [ "$status" -eq 2 ]
}

@test "case 6: missing per-JTBD predicate shim → silent-pass exit 0" {
  # Strip ALL per-JTBD predicate shim locations from PATH (source-repo
  # packages/jtbd/bin AND the global plugin install cache); degenerate
  # adopter case (ADR-031). The helper should silent-pass (exit 0) rather
  # than fail.
  cat > "$FIXTURE/docs/problems/open/995-cites-unratified.md" <<'EOF'
# Problem 995: cites an unratified JTBD but shim is missing

## Decision Drivers

- JTBD-502 — An unratified job
EOF
  cd "$FIXTURE"
  # Strip every PATH entry that exposes wr-jtbd-is-job-or-persona-unconfirmed.
  # Both packages/jtbd/bin (source-repo) and ~/.claude/plugins/cache/.../bin
  # (plugin install) must go.
  STRIPPED_PATH=""
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    if [ -x "$entry/wr-jtbd-is-job-or-persona-unconfirmed" ]; then
      continue
    fi
    STRIPPED_PATH="${STRIPPED_PATH}${entry}:"
  done < <(printf '%s' "$PATH" | tr ':' '\n')
  PATH="${STRIPPED_PATH%:}" run "$SHIM" "docs/problems/open/995-cites-unratified.md"
  [ "$status" -eq 0 ]
}

@test "case 7: ticket cites multiple JTBDs, one unratified → exit 1 + unratified ID only" {
  cat > "$FIXTURE/docs/jtbd/developer/JTBD-503-ratified.md" <<'EOF'
---
human-oversight: confirmed
---

# JTBD-503: A ratified job
EOF
  cat > "$FIXTURE/docs/jtbd/developer/JTBD-504-unratified.md" <<'EOF'
---
status: proposed
---

# JTBD-504: An unratified job
EOF
  cat > "$FIXTURE/docs/problems/open/994-cites-mixed.md" <<'EOF'
# Problem 994: cites both ratified and unratified JTBDs

## Decision Drivers

- JTBD-503 — A ratified job
- JTBD-504 — An unratified job
EOF
  cd "$FIXTURE"
  run "$SHIM" "docs/problems/open/994-cites-mixed.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"JTBD-504"* ]]
  # Ratified IDs are NOT echoed — only the unratified set.
  [[ "$output" != *"JTBD-503"* ]]
}
