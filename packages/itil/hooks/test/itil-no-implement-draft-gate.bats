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

# Seed a minimally well-formed story. The gate is approval-aware, so a bare
# `touch` no longer produces a story it will pass.
seed_story() { printf -- '---\nstatus: accepted\n---\n\n# %s\n' "$1" > "$2"; }
# Ratify via the real write path, never a hand-written marker — the hash has one
# definition and a hand-rolled fixture would drift from it.
ratify() { bash "$MARK" "$@" >/dev/null 2>&1; }

# ADR-103: a story whose approval is its map's. No oversight field of its own —
# that is the point: approval is derived from `story-maps:` alone.
_story_on_map() {
  printf -- '---\nstatus: accepted\nstory-maps: [%s]\n---\n\n# STORY-042\n' \
    "$1" > docs/stories/accepted/STORY-042-foo.md
}

# A map in the given approval state. `ratified` goes through the real marker
# writer, so the stored fingerprint comes from the one definition of the hash.
_map() {
  mkdir -p docs/story-maps/draft
  local f="docs/story-maps/draft/$1-fixture.html"
  printf '<!DOCTYPE html>\n<body>\n<script id="story-map-data" type="application/json">\n{ "storyMapId": "%s", "backbone": [], "releases": [] }\n</script>\n</body>\n</html>\n' "$1" > "$f"
  [ "$2" = ratified ] && ratify "$f"
  return 0
}
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
# enforced it. Split into both directions, flipped in the slice that shipped the
# behaviour (the ADR-089 precedent). Re-based onto the MAP tier under ADR-103.

@test "blocks a commit referencing an ACCEPTED but unapproved story (P465)" {
  seed_story STORY-042 docs/stories/accepted/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q 'not approved'
}

@test "blocks a commit when the MAP has drifted since it was ratified" {
  printf -- '---\nstatus: in-progress\nstory-maps: [STORY-MAP-940]\n---\n\n# STORY-042\n' \
    > docs/stories/in-progress/STORY-042-foo.md
  _map STORY-MAP-940 ratified
  # A new activity column is substance — it re-opens the map's approval, and
  # every story on that map goes unapproved with it.
  python3 -c 'import sys,pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
p.write_text(t.replace("\"backbone\": []", "\"backbone\": [{\"id\": \"z\", \"title\": \"Z. New step\"}]"))' \
    docs/story-maps/draft/STORY-MAP-940-fixture.html
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "editing the STORY never affects the gate — only its map does (ADR-103)" {
  # Stories are outside the fingerprint entirely, so no story edit — ticking a
  # criterion, rewriting the body — can revoke an approval the map holds.
  _map STORY-MAP-940 ratified
  cat > docs/stories/in-progress/STORY-042-foo.md <<'EOF'
---
status: in-progress
story-maps: [STORY-MAP-940]
---

# STORY-042

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] The step happens.
EOF
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  ! echo "$output" | grep -q 'deny'

  printf -- '\n- [x] A wholly new criterion nobody ratified.\n' >> docs/stories/in-progress/STORY-042-foo.md
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "ADR-103: a story on an UNRATIFIED map is blocked" {
  _story_on_map STORY-MAP-940
  _map STORY-MAP-940 unratified
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  # The remedy named must be the MAP — pointing at the story sends the caller
  # to ratify a surface ADR-103 removed, which cannot unblock them.
  echo "$output" | grep -q 'story map'
}

@test "ADR-103: a stale story-level confirmed marker does NOT approve a story" {
  # The second approval surface ADR-103 removed. If a leftover marker could
  # still satisfy the gate, the cutover would never finish.
  printf -- '---\nstatus: accepted\nstory-maps: [STORY-MAP-940]\nhuman-oversight: confirmed\n---\n\n# STORY-042\n' \
    > docs/stories/accepted/STORY-042-foo.md
  _map STORY-MAP-940 unratified
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "ADR-103: a story on a RATIFIED map is allowed" {
  _story_on_map STORY-MAP-940
  _map STORY-MAP-940 ratified
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "ADR-103: a story naming TWO maps is blocked unless BOTH are ratified" {
  # Pins the return-1-inside-the-loop ordering. A later refactor that hoisted
  # `found=1` above the ratification check would approve on the first map alone.
  printf -- '---\nstatus: accepted\nstory-maps: [STORY-MAP-940, STORY-MAP-941]\n---\n\n# STORY-042\n' \
    > docs/stories/accepted/STORY-042-foo.md
  _map STORY-MAP-940 ratified
  _map STORY-MAP-941 unratified
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "ADR-103: the block-form story-maps: list gates identically to the inline form" {
  # Two accepted YAML spellings of the same fact. If only the inline form were
  # parsed, a block-form story would resolve zero maps and — before the found=0
  # guard — could have read as vacuously approved.
  printf -- '---\nstatus: accepted\nstory-maps:\n  - STORY-MAP-940\n---\n\n# STORY-042\n' \
    > docs/stories/accepted/STORY-042-foo.md
  _map STORY-MAP-940 unratified
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  echo "$output" | grep -q '"permissionDecision": "deny"'

  _map STORY-MAP-940 ratified
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'deny'
}

@test "ADR-103: an AMBIGUOUS map id is blocked, not arbitrarily resolved" {
  # The same id under two lifecycle dirs. Glob expansion sorts archived/ ahead
  # of draft/, so an arbitrary pick would approve against a stale ratified
  # archived copy while the live draft map is unratified — silently, and in the
  # permissive direction. Ambiguity must deny.
  _story_on_map STORY-MAP-940
  mkdir -p docs/story-maps/archived
  _map STORY-MAP-940 ratified
  cp docs/story-maps/draft/STORY-MAP-940-fixture.html docs/story-maps/archived/STORY-MAP-940-fixture.html
  # Now make the DRAFT copy unratified, leaving the archived one ratified.
  printf '<!DOCTYPE html>\n<body>\n<script id="story-map-data" type="application/json">\n{ "storyMapId": "STORY-MAP-940", "backbone": [] }\n</script>\n</body>\n</html>\n' \
    > docs/story-maps/draft/STORY-MAP-940-fixture.html
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "ADR-103: a story naming NO map is blocked" {
  # Otherwise deleting the story-maps: line would be a way to self-approve.
  printf -- '---\nstatus: accepted\n---\n\n# STORY-042\n' > docs/stories/accepted/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'
  run bash -c "bash '$HOOK' < env.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "the gate degrades to a no-op when its predicate lib is missing" {
  # CHARACTERIZATION, not an endorsement. This pins observed behaviour so that a
  # future reader who notices the silent vanish and "fixes" it trips a test and
  # has the conversation, rather than changing a governance gate's failure
  # posture in passing.
  #
  # No in-force decision covers whether a BLOCKING governance gate may degrade
  # to a no-op when its lib is absent. ADR-013 Rule 6 is about a skill that
  # cannot reach AskUserQuestion, and its Continue clause reads "Do NOT silently
  # fail-soft-skip" — it does not authorise this.
  #
  # ADR-048 (gate-misfire recovery, superseded by ADR-050) weighed a fail-open at
  # a different gate — loosening the manage-problem create-gate's SID-binding so
  # any marker satisfies it — and rejected it "at this scope", reasoning that
  # fail-open "weakens P119's enforcement during the very stop-gap window where
  # the audit-trail-preservation test is load-bearing". It deferred the general
  # question rather than settling it. The reasoning was carried forward as a
  # rejected option in ADR-050 (Runtime SID instrumentation via PreToolUse),
  # which IS in force — but scoped there to loosening a marker predicate at the
  # manage-problem create-gate, not to missing-lib degradation. So it has
  # in-force standing as reasoning, and none as a general rule about this.
  #
  # The mitigation this suite actually relies on is the tarball-manifest test in
  # scripts/test/gate-lib-ships.bats, which fails if a sourced lib stops
  # shipping — not this behaviour. Open question queued at P369.
  local pkg="$TMP/pkg"
  mkdir -p "$pkg"
  cp -R "$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"/hooks "$pkg/hooks"
  cp -R "$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"/lib "$pkg/lib"

  # A DRAFT story: the least ambiguous case, denied by the gate's oldest rule.
  touch docs/stories/draft/STORY-042-foo.md
  env_cmd 'git commit -m "fix: thing

Refs: STORY-042"'

  # Baseline — the copied tree denies, so the fixture itself is sound.
  run bash -c "bash '$pkg/hooks/itil-no-implement-draft-gate.sh' < env.json"
  echo "$output" | grep -q '"permissionDecision": "deny"'

  # Remove the predicate lib: the whole gate vanishes, including the draft check
  # that does not depend on it. Both source guards are terminal and sit above
  # every check, so this is no-gate-at-all, not a partial gate.
  rm -f "$pkg/lib/story-oversight.sh"
  run bash -c "bash '$pkg/hooks/itil-no-implement-draft-gate.sh' < env.json"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
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
