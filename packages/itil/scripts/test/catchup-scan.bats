#!/usr/bin/env bats

# Behavioural test for packages/itil/scripts/catchup-scan.sh — the P080
# Phase 2 `--catchup` worklist scanner. Exercises the script against a
# synthetic `.verifying.md` / `.closed.md` fixture corpus and asserts on
# its emitted worklist (stdout) + summary (stderr) — NOT on SKILL.md prose.
# This is a genuinely behavioural test per ADR-052: it runs the target and
# asserts on its outputs, covering acceptance criterion 6 (fixture +
# idempotency assertion).
#
# Coverage:
# - CATCHUP emitted for a post-fix ticket with `## Reported Upstream` and
#   no lifecycle log entry for the target state.
# - SKIP/already-logged (idempotency) for a ticket whose
#   `## Upstream Lifecycle Updates` log already records the target state.
# - Silent skip for tickets without a `## Reported Upstream` section.
# - SKIP/out-of-band for out-of-band / mailbox disclosure paths.
# - Open / Known-Error / Parked tickets are out of the catchup corpus.
# - Dual-tolerant flat-layout AND per-state subdir layout (RFC-002).
# - --ticket restricts the scan; bad args / missing dir error cleanly.
#
# @problem P080 (Phase 2 --catchup)
# @adr ADR-052 (behavioural-tests default)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/packages/itil/scripts/catchup-scan.sh"
  FIX="$BATS_TEST_TMPDIR/problems"
  mkdir -p "$FIX"
}

# Write a ticket with a `## Reported Upstream` section. Args:
#   $1 = filename (relative to $FIX)
#   $2 = upstream URL (or "" for none)
#   $3 = disclosure path text
make_reported_ticket() {
  local path="$FIX/$1" url="$2" disclosure="$3"
  mkdir -p "$(dirname "$path")"
  {
    echo "# Problem: fixture"
    echo ""
    echo "**Status**: fixture"
    echo ""
    echo "## Reported Upstream"
    echo ""
    [ -n "$url" ] && echo "- **URL**: $url"
    echo "- **Reported**: 2026-01-01"
    echo "- **Disclosure path**: $disclosure"
  } > "$path"
}

# Append an `## Upstream Lifecycle Updates` log entry recording a target.
append_lifecycle_log() {
  local path="$FIX/$1" transition="$2"
  {
    echo ""
    echo "## Upstream Lifecycle Updates"
    echo ""
    echo "- **2026-02-02** — $transition"
    echo "  - **Disclosure path**: posted-comment"
  } >> "$path"
}

@test "catchup-scan: emits CATCHUP for a closed ticket with Reported Upstream and no lifecycle log" {
  make_reported_ticket "113-foo.closed.md" "https://github.com/o/r/issues/5" "public issue"
  run bash "$SCRIPT" --problems-dir "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CATCHUP P113 https://github.com/o/r/issues/5 state=closed transition=Verifying->Closed"* ]]
}

@test "catchup-scan: emits CATCHUP for a verifying ticket with the KE->Verifying transition" {
  make_reported_ticket "090-bar.verifying.md" "https://github.com/o/r/issues/9" "public issue"
  run bash "$SCRIPT" --problems-dir "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CATCHUP P090 https://github.com/o/r/issues/9 state=verifying transition=KE->Verifying"* ]]
}

@test "catchup-scan: idempotency — SKIP/already-logged when log records the target state (closed)" {
  make_reported_ticket "113-foo.closed.md" "https://github.com/o/r/issues/5" "public issue"
  append_lifecycle_log "113-foo.closed.md" "Verification Pending → Closed"
  run bash "$SCRIPT" --problems-dir "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKIP    P113 https://github.com/o/r/issues/5 reason=already-logged"* ]]
  [[ "$output" != *"CATCHUP P113"* ]]
}

@test "catchup-scan: idempotency — SKIP/already-logged when log records the target state (verifying)" {
  make_reported_ticket "090-bar.verifying.md" "https://github.com/o/r/issues/9" "public issue"
  append_lifecycle_log "090-bar.verifying.md" "Known Error → Verification Pending"
  run bash "$SCRIPT" --problems-dir "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKIP    P090 https://github.com/o/r/issues/9 reason=already-logged"* ]]
  [[ "$output" != *"CATCHUP P090"* ]]
}

@test "catchup-scan: idempotency is re-run-safe — a logged closed ticket alongside a fresh one" {
  make_reported_ticket "113-done.closed.md" "https://github.com/o/r/issues/5" "public issue"
  append_lifecycle_log "113-done.closed.md" "Verification Pending → Closed"
  make_reported_ticket "114-fresh.closed.md" "https://github.com/o/r/issues/6" "public issue"
  run bash "$SCRIPT" --problems-dir "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKIP    P113 https://github.com/o/r/issues/5 reason=already-logged"* ]]
  [[ "$output" == *"CATCHUP P114 https://github.com/o/r/issues/6"* ]]
}

@test "catchup-scan: silently skips tickets with no Reported Upstream section" {
  mkdir -p "$FIX"
  printf '# Problem\n\n**Status**: Closed\n\nNo upstream link here.\n' > "$FIX/200-nolink.closed.md"
  run bash "$SCRIPT" --problems-dir "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" != *"P200"* ]]
}

@test "catchup-scan: SKIP/out-of-band for a mailbox / out-of-band disclosure path" {
  make_reported_ticket "150-sec.closed.md" "" "drafted-and-saved (mailbox / out-of-band)"
  run bash "$SCRIPT" --problems-dir "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKIP    P150"* ]]
  [[ "$output" == *"reason=out-of-band"* ]]
}

@test "catchup-scan: Open / Known-Error / Parked tickets are out of the catchup corpus" {
  make_reported_ticket "300-open.open.md" "https://github.com/o/r/issues/3" "public issue"
  make_reported_ticket "301-ke.known-error.md" "https://github.com/o/r/issues/4" "public issue"
  make_reported_ticket "302-park.parked.md" "https://github.com/o/r/issues/7" "public issue"
  run bash "$SCRIPT" --problems-dir "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" != *"P300"* ]]
  [[ "$output" != *"P301"* ]]
  [[ "$output" != *"P302"* ]]
}

@test "catchup-scan: dual-tolerant — per-state subdir layout (RFC-002) is scanned" {
  make_reported_ticket "closed/113-sub.md" "https://github.com/o/r/issues/8" "public issue"
  run bash "$SCRIPT" --problems-dir "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CATCHUP P113 https://github.com/o/r/issues/8 state=closed transition=Verifying->Closed"* ]]
}

@test "catchup-scan: --ticket restricts the scan to one ticket" {
  make_reported_ticket "113-foo.closed.md" "https://github.com/o/r/issues/5" "public issue"
  make_reported_ticket "114-bar.closed.md" "https://github.com/o/r/issues/6" "public issue"
  run bash "$SCRIPT" --problems-dir "$FIX" --ticket P114
  [ "$status" -eq 0 ]
  [[ "$output" == *"CATCHUP P114"* ]]
  [[ "$output" != *"P113"* ]]
}

@test "catchup-scan: SUMMARY line reports counts on stderr" {
  make_reported_ticket "113-foo.closed.md" "https://github.com/o/r/issues/5" "public issue"
  make_reported_ticket "114-bar.closed.md" "https://github.com/o/r/issues/6" "public issue"
  append_lifecycle_log "114-bar.closed.md" "Verification Pending → Closed"
  run bash -c "bash '$SCRIPT' --problems-dir '$FIX' 2>&1 1>/dev/null"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SUMMARY scanned=2 catchup=1 skip-logged=1 skip-out-of-band=0"* ]]
}

@test "catchup-scan: missing problems-dir exits 1 with error" {
  run bash "$SCRIPT" --problems-dir "$BATS_TEST_TMPDIR/does-not-exist"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ERROR"* ]]
}

@test "catchup-scan: unknown argument exits 1" {
  run bash "$SCRIPT" --bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"ERROR"* ]]
}

@test "catchup-scan: --help prints usage and exits 0" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"--catchup"* ]] || [[ "$output" == *"catchup-scan"* ]]
}
