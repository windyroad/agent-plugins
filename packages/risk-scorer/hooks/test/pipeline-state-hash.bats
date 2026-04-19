#!/usr/bin/env bats
# Tests for pipeline-state.sh --hash-inputs stability
# Covers P054: the hash must be stable across both commit AND push so the
# release gate does not fire spurious "state drift" denials after a
# policy-authorised push advances origin/main.

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$HOOKS_DIR/lib/pipeline-state.sh"

  # Set up a temp git repo with an origin remote so origin/main is meaningful.
  TEST_DIR="$(mktemp -d)"
  REMOTE_DIR="$(mktemp -d)"

  # Bare remote
  (cd "$REMOTE_DIR" && git init --bare --initial-branch=main >/dev/null 2>&1)

  # Working repo
  cd "$TEST_DIR"
  git init --initial-branch=main >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test"
  git remote add origin "$REMOTE_DIR"

  # Seed initial commit
  echo "initial" > README.md
  git add README.md
  git commit -m "initial" >/dev/null 2>&1
  git push -u origin main >/dev/null 2>&1
}

teardown() {
  rm -rf "$TEST_DIR" "$REMOTE_DIR"
}

# Helper: compute the hash of --hash-inputs output in the current directory.
compute_hash() {
  bash "$SCRIPT" --hash-inputs 2>/dev/null | shasum -a 256 | cut -d' ' -f1
}

@test "hash is stable across git commit of staged changes" {
  cd "$TEST_DIR"

  echo "line 1" > feature.ts
  git add feature.ts

  HASH_BEFORE=$(compute_hash)

  git commit -m "add feature" >/dev/null 2>&1

  HASH_AFTER=$(compute_hash)

  [ "$HASH_BEFORE" = "$HASH_AFTER" ] || {
    echo "Hash changed on commit."
    echo "before: $HASH_BEFORE"
    echo "after:  $HASH_AFTER"
    return 1
  }
}

@test "hash is stable across git push (P054 regression guard)" {
  cd "$TEST_DIR"

  echo "line 1" > feature.ts
  git add feature.ts
  git commit -m "add feature" >/dev/null 2>&1

  HASH_BEFORE=$(compute_hash)

  git push origin main >/dev/null 2>&1

  HASH_AFTER=$(compute_hash)

  [ "$HASH_BEFORE" = "$HASH_AFTER" ] || {
    echo "Hash changed on push — this is the P054 regression."
    echo "before: $HASH_BEFORE"
    echo "after:  $HASH_AFTER"
    return 1
  }
}

@test "hash is stable across full commit-then-push sequence" {
  cd "$TEST_DIR"

  echo "line 1" > feature.ts
  git add feature.ts

  HASH_STAGED=$(compute_hash)

  git commit -m "add feature" >/dev/null 2>&1
  HASH_COMMITTED=$(compute_hash)

  git push origin main >/dev/null 2>&1
  HASH_PUSHED=$(compute_hash)

  [ "$HASH_STAGED" = "$HASH_COMMITTED" ] || {
    echo "Hash changed on commit step."
    return 1
  }
  [ "$HASH_COMMITTED" = "$HASH_PUSHED" ] || {
    echo "Hash changed on push step."
    return 1
  }
}

@test "hash changes when a new tracked file is edited" {
  cd "$TEST_DIR"

  echo "v1" > feature.ts
  git add feature.ts
  git commit -m "v1" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1

  HASH_BEFORE=$(compute_hash)

  echo "v2" > feature.ts

  HASH_AFTER=$(compute_hash)

  [ "$HASH_BEFORE" != "$HASH_AFTER" ] || {
    echo "Hash did not change on content edit."
    return 1
  }
}

@test "hash changes when a new changeset is added" {
  cd "$TEST_DIR"

  mkdir -p .changeset
  HASH_BEFORE=$(compute_hash)

  cat > .changeset/abc.md <<'CS'
---
"@windyroad/itil": patch
---

Fix something.
CS

  HASH_AFTER=$(compute_hash)

  [ "$HASH_BEFORE" != "$HASH_AFTER" ] || {
    echo "Hash did not change on new changeset."
    return 1
  }
}

@test "hash is stable with no upstream remote (works on a fresh repo)" {
  # Fresh repo with no remote tracking branch.
  NO_REMOTE_DIR="$(mktemp -d)"
  cd "$NO_REMOTE_DIR"
  git init --initial-branch=main >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test"
  echo "init" > README.md
  git add README.md
  git commit -m "init" >/dev/null 2>&1

  # Should not error out, should emit a hash input
  run bash "$SCRIPT" --hash-inputs
  [ "$status" -eq 0 ]
  [ -n "$output" ]

  # Two consecutive calls should produce the same hash (deterministic)
  HASH_A=$(compute_hash)
  HASH_B=$(compute_hash)
  [ "$HASH_A" = "$HASH_B" ]

  rm -rf "$NO_REMOTE_DIR"
}

@test "hash is stable with clean working tree (no stash-create content)" {
  cd "$TEST_DIR"
  # Working tree is clean after setup's push. Two consecutive calls are stable.
  HASH_A=$(compute_hash)
  HASH_B=$(compute_hash)
  [ "$HASH_A" = "$HASH_B" ] || {
    echo "Hash is non-deterministic on clean tree."
    return 1
  }
}

@test "hash is stable with dirty working tree (uncommitted edits)" {
  cd "$TEST_DIR"
  echo "dirty" > work.txt
  git add work.txt
  echo "more dirty" > unstaged.txt

  HASH_A=$(compute_hash)
  HASH_B=$(compute_hash)
  [ "$HASH_A" = "$HASH_B" ] || {
    echo "Hash is non-deterministic on dirty tree."
    return 1
  }
}
