#!/usr/bin/env bats
# Behavioural coverage for pipeline-state.sh --unreleased changeset partition
# per P202: a changeset whose introducing commit is already on origin/<base>
# is awaiting only the release-PR merge to npm and must NOT count as a
# "pending consumer-facing change" at this commit's surface.
#
# Per ADR-052 (behavioural tests default) — fixture seeds two changesets
# with distinct commit provenance and asserts pipeline-state.sh emits
# distinct counts so the pipeline.md Layer-1 scoring contract can rely
# on the partition without re-deriving it.

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$HOOKS_DIR/lib/pipeline-state.sh"

  TEST_DIR="$(mktemp -d)"
  REMOTE_DIR="$(mktemp -d)"

  (cd "$REMOTE_DIR" && git init --bare --initial-branch=main >/dev/null 2>&1)

  cd "$TEST_DIR"
  git init --initial-branch=main >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test"
  git remote add origin "$REMOTE_DIR"

  echo "initial" > README.md
  git add README.md
  git commit -m "initial" >/dev/null 2>&1
  git push -u origin main >/dev/null 2>&1

  mkdir -p .changeset
}

teardown() {
  cd /
  rm -rf "$TEST_DIR" "$REMOTE_DIR"
}

# Helper: seed a changeset, commit it, and push to origin (queued state).
seed_queued_changeset() {
  local name="$1"
  cat > ".changeset/${name}.md" <<EOF
---
"@windyroad/itil": patch
---

${name} changeset body.
EOF
  git add ".changeset/${name}.md"
  git commit -m "add changeset ${name}" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
}

# Helper: seed a changeset and commit it locally without pushing (pending state).
seed_pending_changeset() {
  local name="$1"
  cat > ".changeset/${name}.md" <<EOF
---
"@windyroad/itil": patch
---

${name} changeset body.
EOF
  git add ".changeset/${name}.md"
  git commit -m "add changeset ${name}" >/dev/null 2>&1
}

# Helper: seed a changeset file but leave it untracked (uncommitted-pending state).
seed_untracked_changeset() {
  local name="$1"
  cat > ".changeset/${name}.md" <<EOF
---
"@windyroad/itil": patch
---

${name} changeset body.
EOF
}

@test "emits queued+pending breakdown when changesets straddle origin" {
  cd "$TEST_DIR"
  seed_queued_changeset queued-one
  seed_pending_changeset pending-one

  run bash "$SCRIPT" --unreleased
  [ "$status" -eq 0 ]

  echo "$output" | grep -q "Queued changesets (commits already on origin): 1" || {
    echo "Missing 'Queued changesets (commits already on origin): 1' line."
    echo "Output was:"
    echo "$output"
    return 1
  }
  echo "$output" | grep -q "Pending changesets (commits unpushed): 1" || {
    echo "Missing 'Pending changesets (commits unpushed): 1' line."
    echo "Output was:"
    echo "$output"
    return 1
  }
}

@test "all-on-origin scenario: Queued > 0, Pending = 0" {
  cd "$TEST_DIR"
  seed_queued_changeset on-origin-a
  seed_queued_changeset on-origin-b

  run bash "$SCRIPT" --unreleased
  [ "$status" -eq 0 ]

  echo "$output" | grep -q "Queued changesets (commits already on origin): 2" || {
    echo "Missing 'Queued changesets (commits already on origin): 2' line."
    echo "Output was:"
    echo "$output"
    return 1
  }
  echo "$output" | grep -q "Pending changesets (commits unpushed): 0" || {
    echo "Missing 'Pending changesets (commits unpushed): 0' line."
    echo "Output was:"
    echo "$output"
    return 1
  }
}

@test "all-local scenario: Pending > 0, Queued = 0" {
  cd "$TEST_DIR"
  seed_pending_changeset local-a
  seed_pending_changeset local-b

  run bash "$SCRIPT" --unreleased
  [ "$status" -eq 0 ]

  echo "$output" | grep -q "Pending changesets (commits unpushed): 2" || {
    echo "Missing 'Pending changesets (commits unpushed): 2' line."
    echo "Output was:"
    echo "$output"
    return 1
  }
  echo "$output" | grep -q "Queued changesets (commits already on origin): 0" || {
    echo "Missing 'Queued changesets (commits already on origin): 0' line."
    echo "Output was:"
    echo "$output"
    return 1
  }
}

@test "untracked changeset counts as pending" {
  cd "$TEST_DIR"
  seed_untracked_changeset draft-one

  run bash "$SCRIPT" --unreleased
  [ "$status" -eq 0 ]

  echo "$output" | grep -q "Pending changesets (commits unpushed): 1" || {
    echo "Untracked changeset should count as pending."
    echo "Output was:"
    echo "$output"
    return 1
  }
}

@test "no changesets emits no breakdown lines" {
  cd "$TEST_DIR"
  # .changeset dir exists but is empty (setup creates it).

  run bash "$SCRIPT" --unreleased
  [ "$status" -eq 0 ]

  ! echo "$output" | grep -q "Queued changesets" || {
    echo "Should not emit Queued line when no changesets present."
    echo "Output was:"
    echo "$output"
    return 1
  }
  ! echo "$output" | grep -q "Pending changesets" || {
    echo "Should not emit Pending line when no changesets present."
    echo "Output was:"
    echo "$output"
    return 1
  }
}
