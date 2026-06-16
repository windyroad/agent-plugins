#!/usr/bin/env bats

# @problem P314 — Phase 2 (RFC-005 B3/B4): the fix-time propose-fix
# RFC-trace gate. Before fix work commences on a Known Error, the
# framework requires an RFC tracing the problem; if none exists, a
# problem-traced skeleton RFC is auto-created (per ADR-073) rather than
# blocked. This script is the load-bearing PREDICATE half of that gate
# (ADR-060 I1 load-bearing-from-the-start carried forward): it detects
# whether any RFC traces the problem and emits an auto-create directive
# on stdout when none does. The CREATE half is skill-orchestrated
# (delegates to /wr-itil:capture-rfc — the canonical ADR-070-compliant
# problem-traced-skeleton vehicle, no duplication).
#
# Behavioural per ADR-052: assert on the script's exit code + stdout
# directive given fixture RFC corpora — not on script source content
# (no structural greps per P081).
#
# Contract:
#   - <problem-file> whose basename is `<NNN>-<slug>.md` → PID = P<NNN>.
#   - An RFC traces the problem when its frontmatter `problems:` array
#     contains the exact PID (boundary-safe: P31 / P3140 must NOT match
#     a P314 query).
#   - Trace present  → exit 0, EMPTY stdout (fix proceeds; no auto-create).
#   - Trace absent   → exit 0, stdout carries `no-rfc-trace: P<NNN>` directive
#     (NEVER a non-zero/block exit — ADR-073 auto-create-not-block).
#   - Missing problem file / no args → exit 2 (caller misuse), stderr usage.
#
# @adr ADR-072 (RFC required at the propose-fix step on a Known Error)
# @adr ADR-073 (fix-time gate auto-creates a missing RFC, everywhere —
#   never blocks; hence exit 0 on the absent branch)
# @adr ADR-071 (every fix goes through an RFC — unconditional, no carve-out)
# @adr ADR-060 (I1 load-bearing-from-the-start; I13 fix-proposal invariant)
# @adr ADR-052 (behavioural bats default)
# @jtbd JTBD-008 (Decompose a Fix Into Coordinated Changes — trace invariant)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — never stall/skip)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-fix-rfc-trace.sh"
  RFCS_DIR="$(mktemp -d)"
  PROBLEMS_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$RFCS_DIR" "$PROBLEMS_DIR"
}

# Write an RFC fixture whose frontmatter `problems:` array is set verbatim.
write_rfc() {
  local id="$1" slug="$2" status="$3" problems="$4"
  cat > "$RFCS_DIR/RFC-${id}-${slug}.${status}.md" <<EOF
---
status: ${status}
rfc-id: ${slug}
problems: ${problems}
---

# RFC-${id}: ${slug}
EOF
}

# Write a problem fixture; returns the path on stdout.
write_problem() {
  local num="$1" slug="${2:-some-problem}"
  local f="$PROBLEMS_DIR/${num}-${slug}.md"
  cat > "$f" <<EOF
# Problem ${num}: ${slug}

**Status**: Known Error
EOF
  printf '%s' "$f"
}

@test "trace present (single-PID array) → exit 0, empty stdout" {
  write_rfc 005 some-fix accepted "[P314]"
  pf="$(write_problem 314)"
  run "$SCRIPT" "$pf" "$RFCS_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "trace present (multi-PID array) → exit 0, empty stdout" {
  write_rfc 005 some-fix accepted "[P100, P314, P200]"
  pf="$(write_problem 314)"
  run "$SCRIPT" "$pf" "$RFCS_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "trace absent (empty rfcs dir) → exit 0, auto-create directive on stdout" {
  pf="$(write_problem 314)"
  run "$SCRIPT" "$pf" "$RFCS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-rfc-trace: P314"* ]]
}

@test "trace absent (RFCs exist but none claim this PID) → exit 0, directive" {
  write_rfc 005 other-fix accepted "[P251]"
  write_rfc 013 another accepted "[P346]"
  pf="$(write_problem 314)"
  run "$SCRIPT" "$pf" "$RFCS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-rfc-trace: P314"* ]]
}

@test "PID boundary: P31 in an RFC does NOT satisfy a P314 query" {
  write_rfc 005 short-pid accepted "[P31]"
  pf="$(write_problem 314)"
  run "$SCRIPT" "$pf" "$RFCS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-rfc-trace: P314"* ]]
}

@test "PID boundary: P3140 in an RFC does NOT satisfy a P314 query" {
  write_rfc 005 long-pid accepted "[P3140]"
  pf="$(write_problem 314)"
  run "$SCRIPT" "$pf" "$RFCS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-rfc-trace: P314"* ]]
}

@test "exact match works for a zero-padded low PID (P080 ← [P080])" {
  # PIDs are canonically 3-digit zero-padded (filenames 080-..., citations P080).
  write_rfc 005 padded-pid accepted "[P080]"
  pf="$(write_problem 080)"
  run "$SCRIPT" "$pf" "$RFCS_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "default rfcs-dir is docs/rfcs when second arg omitted" {
  # Run from a temp cwd containing docs/rfcs with a tracing RFC.
  workdir="$(mktemp -d)"
  mkdir -p "$workdir/docs/rfcs"
  cat > "$workdir/docs/rfcs/RFC-005-x.accepted.md" <<'EOF'
---
problems: [P314]
---
# RFC-005: x
EOF
  pf="$(write_problem 314)"
  run bash -c "cd '$workdir' && '$SCRIPT' '$pf'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  rm -rf "$workdir"
}

@test "missing problem file → exit 2, stderr usage" {
  run "$SCRIPT" "$PROBLEMS_DIR/999-nonexistent.md" "$RFCS_DIR"
  [ "$status" -eq 2 ]
}

@test "no args → exit 2" {
  run "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "directive names the canonical auto-create vehicle (capture-rfc) and ADRs" {
  pf="$(write_problem 314)"
  run "$SCRIPT" "$pf" "$RFCS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"capture-rfc"* ]]
  [[ "$output" == *"ADR-073"* ]]
}
