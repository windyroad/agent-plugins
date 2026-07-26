#!/usr/bin/env bats
# Behavioural tests for itil-no-implement-draft-gate.sh (ADR-096 / P404).
# PreToolUse:Bash — reads a JSON envelope on stdin, emits permissionDecision:deny
# (exit 0, deny in the JSON) when a commit references a DRAFT story.
# @adr ADR-096  @adr ADR-052  @problem P404

setup() {
  HOOK="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/itil-no-implement-draft-gate.sh"
  MARK="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../scripts" && pwd)/mark-story-oversight-confirmed.sh"
  TMP="$(mktemp -d)"; cd "$TMP"; git init -q .
  mkdir -p docs/stories/draft docs/stories/accepted docs/stories/in-progress
}

# Seed a minimally well-formed story. Since ADR-101 the gate is ratification-
# aware, so a bare `touch` no longer produces a story it will pass.
seed_story() { printf -- '---\nstatus: accepted\n---\n\n# %s\n' "$1" > "$2"; }
# Ratify via the real write path, never a hand-written marker — the hash has one
# definition and a hand-rolled fixture would drift from it.
ratify() { bash "$MARK" "$@" >/dev/null 2>&1; }
teardown() { cd /; rm -rf "$TMP"; }

# write env.json carrying the given command string
env_cmd() { python3 -c 'import json,sys; open("env.json","w").write(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1"; }

@test "blocks a commit referencing a DRAFT story" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q 'STORY-042'
}

# This case previously seeded an EMPTY, unratified accepted story and asserted
# allow — the P465 hole encoded as a test rather than behaviour anyone chose.
# ADR-096 always claimed no unratified story could be implemented; nothing
# enforced it. Split into both directions, flipped in the slice that ships the
# behaviour (the ADR-089 precedent).

@test "allows a commit referencing an ACCEPTED and RATIFIED story" {
  seed_story STORY-042 docs/stories/accepted/STORY-042-foo.md
  ratify docs/stories/accepted/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "blocks a commit referencing an ACCEPTED but UNRATIFIED story (P465)" {
  seed_story STORY-042 docs/stories/accepted/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q 'not ratified'
}

@test "blocks a commit referencing an IN-PROGRESS story whose content has drifted since ratification" {
  seed_story STORY-042 docs/stories/in-progress/STORY-042-foo.md
  ratify docs/stories/in-progress/STORY-042-foo.md
  printf -- '\nA substance edit made after ratification.\n' >> docs/stories/in-progress/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "ticking an acceptance criterion is progress, not drift — commit still allowed" {
  cat > docs/stories/in-progress/STORY-042-foo.md <<'EOF'
---
status: in-progress
---

# STORY-042

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] The step happens.
EOF
  ratify docs/stories/in-progress/STORY-042-foo.md
  sed -i.bak 's/- \[ \] The step happens./- [x] The step happens./' docs/stories/in-progress/STORY-042-foo.md
  rm -f docs/stories/in-progress/*.bak
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "ADR-101: a pure-decomposition story whose basis no longer matches its criteria is blocked" {
  cat > docs/stories/accepted/STORY-042-foo.md <<'EOF'
---
status: accepted
afk-accept: pure-decomposition
---

# STORY-042

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] One.
- [ ] Two.

## Decomposition basis

- One decomposes ADR-900.
EOF
  bash "$MARK" --pure-decomposition docs/stories/accepted/STORY-042-foo.md >/dev/null 2>&1
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q 'Decomposition basis'
}

@test "ADR-101: a well-formed pure-decomposition story is allowed" {
  cat > docs/stories/accepted/STORY-042-foo.md <<'EOF'
---
status: accepted
afk-accept: pure-decomposition
---

# STORY-042

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] One.
- [ ] Two.

## Decomposition basis

- One decomposes ADR-900.
- Two decomposes ADR-900.
EOF
  bash "$MARK" --pure-decomposition docs/stories/accepted/STORY-042-foo.md >/dev/null 2>&1
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "a DONE story is past implementation and is not ratification-gated" {
  mkdir -p docs/stories/done
  touch docs/stories/done/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "exempts a capture commit even for a draft story" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'git commit -m "feat(itil): capture STORY-042 foo

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "bootstrap-exempt commit bypasses" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'git commit -m "migrate

Refs: STORY-042
bootstrap-exempt: STORY-MAP-001"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "non-commit command is a no-op" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'echo Refs: STORY-042'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "commit with no story trailer is a no-op" {
  env_cmd 'git commit -m "fix: no story ref"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "BYPASS env allows the commit" {
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'git commit -m "fix

Refs: STORY-042"'
  BYPASS_NO_IMPLEMENT_DRAFT=1 run bash -c "BYPASS_NO_IMPLEMENT_DRAFT=1 bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}
