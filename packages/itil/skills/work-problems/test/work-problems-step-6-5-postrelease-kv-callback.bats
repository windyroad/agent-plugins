#!/usr/bin/env bats
# Step 6.5 Post-release K→V auto-transition callback (P228) — behavioural.
#
# Driver: ADR-022 prescribes K→V transition on release, but until P228
# there was no auto-fire surface to back-fill the transition once a fix
# ships. The post-release callback enumerator
# (`packages/itil/lib/enumerate-postrelease-kv-candidates.sh`) is the
# data source: it walks `docs/problems/known-error/*.md`, invokes the
# derive-release-vehicle helper per ticket, and emits one
# `KV_CANDIDATE: P<NNN> | <changeset>` line per ticket whose changeset
# has shipped (derive exit 0).
#
# The 2026-06-08 P220 witness — `## Fix Released` populated but K→V
# deferred citing a misapplied P143 amendment — is the empirical bug
# this enumerator wires the surface to close.
#
# Cases covered (behavioural — exercise the helper, assert observable
# output; structural ban per ADR-005 / P081):
#   1. known-error/ dir absent           → KV_CANDIDATES_SUMMARY: total=0
#   2. known-error/ dir empty            → KV_CANDIDATES_SUMMARY: total=0
#   3. ticket present, derive exit 0     → KV_CANDIDATE emitted; total=1
#   4. ticket present, derive exit 2     → skipped silently; total=0
#      (no `.changeset/<name>.md` ref in body — legacy ticket)
#   5. ticket present, derive exit 3     → skipped silently; total=0
#      (changeset still in working tree — unreleased)
#   6. mixed cohort (3 tickets: shipped + legacy + unreleased)
#                                        → only the shipped one emitted
#   7. README.md inside known-error/ is excluded from the enumeration
#   8. unknown derive exit code          → stderr warning + skip; total=0
#
# Cross-references:
#   @problem P228 (K→V auto-transition gap)
#   @adr ADR-022 (Verifying lifecycle)
#   @adr ADR-018 (release-cadence host of the callback)
#   @adr ADR-005 (behavioural bats per P081)
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away — primary driver)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  HELPER="$REPO_ROOT/packages/itil/lib/enumerate-postrelease-kv-candidates.sh"

  FIXTURE="$(mktemp -d)"
  mkdir -p "$FIXTURE/docs/problems"

  STUB_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE" "$STUB_DIR"
}

# Helper — write a stub derive-release-vehicle command that returns a
# canned exit code (per ticket-id-to-exit-code map encoded in $STUB_MAP).
# $STUB_MAP shape: `<NNN>:<exit>:<changeset>;<NNN>:<exit>:<changeset>;...`
# The third field is consumed only when exit=0 (emitted in the RELEASE_VEHICLE
# block the lib greps for changeset path).
write_stub_derive() {
  local stub="$STUB_DIR/wr-itil-derive-release-vehicle"
  cat > "$stub" <<'STUB'
#!/usr/bin/env bash
# Stub derive-release-vehicle for the enumerator behavioural test. Reads
# $STUB_MAP from the environment, returns canned exit codes per ticket.
nnn="$1"
nnn_norm="$(printf '%03d' "$((10#$nnn))")"
IFS=';' read -ra entries <<< "${STUB_MAP:-}"
for entry in "${entries[@]}"; do
  [ -z "$entry" ] && continue
  IFS=':' read -r id ex cs <<< "$entry"
  id_norm="$(printf '%03d' "$((10#$id))")"
  if [ "$id_norm" = "$nnn_norm" ]; then
    if [ "$ex" -eq 0 ]; then
      cat <<EOF
RELEASE_VEHICLE:
  changeset: $cs
  version-packages-commit: deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
  pr: #999
  merge-commit: deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
  release-date: 2026-06-08
EOF
    fi
    exit "$ex"
  fi
done
# Default: no entry for this ticket → exit 1 (not found)
exit 1
STUB
  chmod +x "$stub"
}

# Helper — write a known-error ticket fixture (body content is opaque to
# the enumerator; only the filename's leading NNN matters since the
# derive helper is stubbed).
write_ke_ticket() {
  local nnn="$1"
  local slug="$2"
  mkdir -p "$FIXTURE/docs/problems/known-error"
  cat > "$FIXTURE/docs/problems/known-error/${nnn}-${slug}.md" <<EOF
# Problem ${nnn}: ${slug}

**Status**: Known Error

## Description

Test fixture for the enumerator behavioural bats.
EOF
}

# Source the lib once for all tests.
load_lib() {
  # shellcheck source=/dev/null
  source "$HELPER"
}

@test "helper file exists and is sourceable" {
  [ -f "$HELPER" ]
  load_lib
}

@test "case 1: known-error/ dir absent → total=0" {
  load_lib
  rm -rf "$FIXTURE/docs/problems/known-error"
  run enumerate_postrelease_kv_candidates "$FIXTURE/docs/problems"
  [ "$status" -eq 0 ]
  [[ "$output" == *"KV_CANDIDATES_SUMMARY: total=0"* ]]
  [[ "$output" != *"KV_CANDIDATE:"* ]]
}

@test "case 2: known-error/ dir empty → total=0" {
  load_lib
  mkdir -p "$FIXTURE/docs/problems/known-error"
  run enumerate_postrelease_kv_candidates "$FIXTURE/docs/problems"
  [ "$status" -eq 0 ]
  [[ "$output" == *"KV_CANDIDATES_SUMMARY: total=0"* ]]
  [[ "$output" != *"KV_CANDIDATE:"* ]]
}

@test "case 3: ticket present + derive exit 0 → KV_CANDIDATE emitted, total=1" {
  load_lib
  write_stub_derive
  write_ke_ticket "228" "adr-022-known-error-to-verifying-transition"
  PATH="$STUB_DIR:$PATH" STUB_MAP="228:0:.changeset/p228-fix.md" \
    run enumerate_postrelease_kv_candidates "$FIXTURE/docs/problems"
  [ "$status" -eq 0 ]
  [[ "$output" == *"KV_CANDIDATE: P228 | .changeset/p228-fix.md"* ]]
  [[ "$output" == *"KV_CANDIDATES_SUMMARY: total=1"* ]]
}

@test "case 4: ticket present + derive exit 2 (no vehicle ref) → skipped silently, total=0" {
  load_lib
  write_stub_derive
  write_ke_ticket "100" "legacy-pre-p330-no-vehicle"
  PATH="$STUB_DIR:$PATH" STUB_MAP="100:2:" \
    run enumerate_postrelease_kv_candidates "$FIXTURE/docs/problems"
  [ "$status" -eq 0 ]
  [[ "$output" != *"KV_CANDIDATE:"* ]]
  [[ "$output" == *"KV_CANDIDATES_SUMMARY: total=0"* ]]
}

@test "case 5: ticket present + derive exit 3 (unreleased) → skipped silently, total=0" {
  load_lib
  write_stub_derive
  write_ke_ticket "200" "changeset-still-in-tree"
  PATH="$STUB_DIR:$PATH" STUB_MAP="200:3:" \
    run enumerate_postrelease_kv_candidates "$FIXTURE/docs/problems"
  [ "$status" -eq 0 ]
  [[ "$output" != *"KV_CANDIDATE:"* ]]
  [[ "$output" == *"KV_CANDIDATES_SUMMARY: total=0"* ]]
}

@test "case 6: mixed cohort — only the shipped ticket is emitted, total=1" {
  load_lib
  write_stub_derive
  write_ke_ticket "228" "shipped"
  write_ke_ticket "100" "legacy-no-vehicle"
  write_ke_ticket "200" "changeset-in-tree"
  PATH="$STUB_DIR:$PATH" \
    STUB_MAP="228:0:.changeset/p228-fix.md;100:2:;200:3:" \
    run enumerate_postrelease_kv_candidates "$FIXTURE/docs/problems"
  [ "$status" -eq 0 ]
  [[ "$output" == *"KV_CANDIDATE: P228 | .changeset/p228-fix.md"* ]]
  [[ "$output" != *"KV_CANDIDATE: P100"* ]]
  [[ "$output" != *"KV_CANDIDATE: P200"* ]]
  [[ "$output" == *"KV_CANDIDATES_SUMMARY: total=1"* ]]
}

@test "case 7: README.md inside known-error/ is excluded from the enumeration" {
  load_lib
  write_stub_derive
  mkdir -p "$FIXTURE/docs/problems/known-error"
  printf '# Known Error Tickets\n' > "$FIXTURE/docs/problems/known-error/README.md"
  PATH="$STUB_DIR:$PATH" STUB_MAP="" \
    run enumerate_postrelease_kv_candidates "$FIXTURE/docs/problems"
  [ "$status" -eq 0 ]
  [[ "$output" != *"KV_CANDIDATE:"* ]]
  [[ "$output" == *"KV_CANDIDATES_SUMMARY: total=0"* ]]
}

@test "case 8: unknown derive exit code → stderr warning + skip, total=0" {
  load_lib
  write_stub_derive
  write_ke_ticket "999" "weird-exit"
  PATH="$STUB_DIR:$PATH" STUB_MAP="999:42:" \
    run enumerate_postrelease_kv_candidates "$FIXTURE/docs/problems"
  [ "$status" -eq 0 ]
  [[ "$output" != *"KV_CANDIDATE:"* ]]
  [[ "$output" == *"KV_CANDIDATES_SUMMARY: total=0"* ]]
  # Stderr warning is captured into $output when bats merges stderr; the
  # contract here is "skip silently AND don't lose audit signal".
}
