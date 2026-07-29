#!/usr/bin/env bats
# Behavioural tests for check-afk-accept-eligible.sh (ADR-101 / P456 / P465).
# Each case maps onto an ADR-101 Confirmation item. Behavioural, not structural:
# every test runs the real script against a real fixture tree and asserts on its
# exit status and stderr, never on its source text (ADR-052 / P081).
#
# The POSITIVE case is the load-bearing one. An earlier revision shipped an
# `awk -v` escape bug that made the checker permanently inert — it fails closed,
# so no negative test could ever have caught it. Only asserting that a
# well-formed story IS eligible surfaces that class of bug.
#
# @adr ADR-101 ADR-090 ADR-095 ADR-096 ADR-098 ADR-052  @problem P456 P465

setup() {
  SCRIPTS="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CHECK="$SCRIPTS/check-afk-accept-eligible.sh"
  MARK="$SCRIPTS/mark-story-oversight-confirmed.sh"
  TMP="$(mktemp -d)"; cd "$TMP"
  mkdir -p docs/stories/draft docs/story-maps/draft docs/rfcs docs/jtbd/dev docs/problems/open docs/decisions
  export HOME="$TMP/home"; mkdir -p "$HOME/.claude"

  # --- confirmed parents -----------------------------------------------------
  printf -- '---\nhuman-oversight: confirmed\n---\n\n# ADR-900\n' > docs/decisions/900-a-confirmed-decision.proposed.md
  printf -- '---\nhuman-oversight: confirmed\n---\n\n# JTBD-900\n' > docs/jtbd/dev/JTBD-900-a-job.proposed.md
  printf -- '---\nhuman-oversight: confirmed\n---\n\n# persona\n' > docs/jtbd/dev/persona.md
  printf -- '---\nadrs: [ADR-900]\n---\n\n# RFC-900\n' > docs/rfcs/RFC-900-a-vehicle.proposed.md
  printf -- '# P900\n' > docs/problems/open/900-a-problem.md

  # A map that was ratified BEFORE the story's card was added — the common case,
  # since ADR-095 compels the card at capture.
  MAP=docs/story-maps/draft/STORY-MAP-900-a-map.html
  printf '<html><head>\n<a class="slice" data-story-id="STORY-800">old</a>\n</head></html>\n' > "$MAP"
  bash "$MARK" "$MAP" 2>/dev/null
  # Now add STORY-901's card, drifting the map exactly as capture would.
  python3 - "$MAP" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
open(p,"w").write(s.replace('</head>','  <a class="slice" data-story-id="STORY-901">new</a>\n</head>'))
PY

  export WR_ITIL_AFK_ACCEPT=1
}
teardown() { cd /; rm -rf "$TMP"; }

# A well-formed pure-decomposition story: 2 criteria, 2 basis entries, all
# citations traced and confirmed.
seed_story() {
  cat > docs/stories/draft/STORY-901-a-story.md <<'EOF'
---
status: draft
problems: [P900]
jtbd: [JTBD-900]
rfcs: [RFC-900]
story-maps: [STORY-MAP-900]
adrs: [ADR-900]
afk-accept: pure-decomposition
---

# STORY-901: A story

## User value

In order to land confirmed work, as a developer, I want the loop to proceed.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] The first step happens.
- [ ] The second step happens.

## Decomposition basis

- Criterion 1 decomposes ADR-900's rule about the first step.
- Criterion 2 decomposes ADR-900's rule about the second step.
EOF
}
run_check() { run bash "$CHECK" docs/stories/draft/STORY-901-a-story.md \
  docs/story-maps docs/rfcs docs/jtbd docs/problems docs/decisions; }

# --- ADR-101 Confirmation: eligibility ---------------------------------------

@test "ELIGIBLE: pure-decomposition story whose parents are all confirmed" {
  seed_story; run_check
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'ELIGIBLE'
}

@test "NOT eligible: a traced ADR parent is unconfirmed" {
  seed_story
  printf -- '---\nhuman-oversight: unconfirmed\n---\n\n# ADR-900\n' > docs/decisions/900-a-confirmed-decision.proposed.md
  run_check
  [ "$status" -eq 1 ]
  echo "$output" | grep -q 'ADR-900'
}

@test "NOT eligible: a traced JTBD's persona is unconfirmed" {
  seed_story
  printf -- '---\nhuman-oversight: unconfirmed\n---\n\n# persona\n' > docs/jtbd/dev/persona.md
  run_check
  [ "$status" -eq 1 ]
  echo "$output" | grep -qi 'persona'
}

@test "NOT eligible: a traced artefact does not resolve (new substance)" {
  seed_story
  rm docs/decisions/900-a-confirmed-decision.proposed.md
  run_check
  [ "$status" -eq 1 ]
}

@test "NOT eligible: basis entries do not match the criteria count" {
  seed_story
  printf -- '- [ ] A third step nobody accounted for.\n' >> docs/stories/draft/STORY-901-a-story.md
  run_check
  [ "$status" -eq 1 ]
  echo "$output" | grep -q 'Decomposition basis'
}

@test "NOT eligible: basis cites an artefact condition (a) never verified" {
  seed_story
  sed -i.bak 's/ADR-900.s rule about the first step/ADR-999 rule about the first step/' docs/stories/draft/STORY-901-a-story.md
  run_check
  [ "$status" -eq 1 ]
  echo "$output" | grep -q 'ADR-999'
}

@test "NOT eligible: the story does not declare the carve-out" {
  seed_story
  sed -i.bak '/^afk-accept:/d' docs/stories/draft/STORY-901-a-story.md
  run_check
  [ "$status" -eq 1 ]
  echo "$output" | grep -q 'afk-accept'
}

@test "NOT eligible: no acceptance criteria at all (fail-closed on zero)" {
  seed_story
  sed -i.bak 's/^- \[ \] The first step happens.//; s/^- \[ \] The second step happens.//' docs/stories/draft/STORY-901-a-story.md
  run_check
  [ "$status" -eq 1 ]
}

# --- ADR-101 Confirmation: the secondary blacklist ---------------------------

@test "NOT eligible: an open-decision marker in ordinary prose" {
  seed_story
  printf -- '\nThe storage locus is still to be decided.\n' >> docs/stories/draft/STORY-901-a-story.md
  run_check
  [ "$status" -eq 1 ]
}

@test "ELIGIBLE: the same vocabulary inside a fenced or backticked span" {
  seed_story
  printf -- '\nThe checker rejects the phrase `to be decided` when it appears in prose:\n\n```\nopen question / TBD / decision needed\n```\n' \
    >> docs/stories/draft/STORY-901-a-story.md
  run_check
  [ "$status" -eq 0 ]
}

# --- ADR-101 Confirmation: the map leg disjunction ---------------------------

@test "ELIGIBLE: map re-ratified WITH the story's card already present" {
  seed_story
  bash "$MARK" "$MAP" 2>/dev/null   # re-ratify now that STORY-901's card exists
  run_check
  [ "$status" -eq 0 ]
}

@test "NOT eligible: map drifted for a reason OTHER than the story's own card" {
  seed_story
  printf '<p>an unrelated edit</p>\n' >> "$MAP"
  run_check
  [ "$status" -eq 1 ]
  echo "$output" | grep -q 'STORY-MAP-900'
}

@test "NOT eligible: map carries no human-oversight marker at all" {
  seed_story
  grep -v 'oversight' "$MAP" > "$MAP.tmp" && mv "$MAP.tmp" "$MAP"
  run_check
  [ "$status" -eq 1 ]
}

# --- ADR-101 Confirmation: the opt-in split ----------------------------------

@test "NOT eligible without opt-in, even when (a) and (b) both hold" {
  seed_story
  unset WR_ITIL_AFK_ACCEPT
  run_check
  [ "$status" -eq 1 ]
  echo "$output" | grep -q 'opted in'
}

@test "project config opts in" {
  seed_story
  unset WR_ITIL_AFK_ACCEPT
  mkdir -p .claude
  printf '{ "afk_accept_pure_decomposition": true }\n' > .claude/itil.config.json
  run_check
  [ "$status" -eq 0 ]
}

@test "a non-boolean config value does NOT opt in" {
  seed_story
  unset WR_ITIL_AFK_ACCEPT
  mkdir -p .claude
  printf '{ "afk_accept_pure_decomposition": "true" }\n' > .claude/itil.config.json
  run_check
  [ "$status" -eq 1 ]
}

@test "an unparseable config does NOT opt in" {
  seed_story
  unset WR_ITIL_AFK_ACCEPT
  mkdir -p .claude
  printf 'not json at all\n' > .claude/itil.config.json
  run_check
  [ "$status" -eq 1 ]
}

@test "ADR-098 per-key fallback: a project file omitting the key falls through to machine" {
  seed_story
  unset WR_ITIL_AFK_ACCEPT
  mkdir -p .claude
  printf '{ "some_other_key": 1 }\n' > .claude/itil.config.json
  printf '{ "afk_accept_pure_decomposition": true }\n' > "$HOME/.claude/itil.config.json"
  run_check
  [ "$status" -eq 0 ]
}

@test "a project file setting the key FALSE wins over a machine TRUE" {
  seed_story
  unset WR_ITIL_AFK_ACCEPT
  mkdir -p .claude
  printf '{ "afk_accept_pure_decomposition": false }\n' > .claude/itil.config.json
  printf '{ "afk_accept_pure_decomposition": true }\n' > "$HOME/.claude/itil.config.json"
  run_check
  [ "$status" -eq 1 ]
}

@test "jq absent resolves to the built-in default: NOT eligible" {
  seed_story
  unset WR_ITIL_AFK_ACCEPT
  mkdir -p .claude bin
  printf '{ "afk_accept_pure_decomposition": true }\n' > .claude/itil.config.json
  run env PATH="/usr/bin:/bin" bash "$CHECK" docs/stories/draft/STORY-901-a-story.md \
    docs/story-maps docs/rfcs docs/jtbd docs/problems docs/decisions
  # Only meaningful where jq is genuinely off PATH; skip otherwise.
  if PATH="/usr/bin:/bin" command -v jq >/dev/null 2>&1; then skip "jq is on the minimal PATH here"; fi
  [ "$status" -eq 1 ]
}

# --- ADR-101 Confirmation: no automated path writes a `true` opt-in ----------

@test "no shipped installer or scaffold writes an opt-in value" {
  # The guard that keeps opt-in from becoming opt-out-by-stealth. Any shipped
  # code that WRITES this key would defeat the split; reading it is fine.
  cd "$(dirname "$CHECK")/.."
  # Guard the search roots. Pointed at a directory that does not exist, grep
  # matches nothing and the assertion below passes for the wrong reason — and
  # whether it passes at all then depends on which grep merges its warning into
  # bats' $output.
  [ -d bin ] && [ -d hooks ]
  run grep -rIlE 'afk_accept_pure_decomposition' --include='*.mjs' --include='*.js' bin/ hooks/
  [ -z "$output" ]
}

# --- ADR-101 Confirmation: detector stdout contract --------------------------

@test "detect-unratified-stories-maps stdout is byte-identical with and without the flag" {
  seed_story
  a="$(bash "$SCRIPTS/detect-unratified-stories-maps.sh" docs/stories docs/story-maps 2>/dev/null)"
  b="$(bash "$SCRIPTS/detect-unratified-stories-maps.sh" --with-afk-accepted docs/stories docs/story-maps 2>/dev/null)"
  [ "$a" = "$b" ]
}

@test "--with-afk-accepted surfaces the machine-accepted story on stderr" {
  seed_story
  run bash -c "bash '$SCRIPTS/detect-unratified-stories-maps.sh' --with-afk-accepted docs/stories docs/story-maps 2>&1 >/dev/null"
  echo "$output" | grep -q 'STORY-901'
  echo "$output" | grep -q 'AFK-ACCEPTED'
}

@test "the post-hoc drain still finds the story when oversight-basis is stripped" {
  # The union key. `oversight-basis` is excluded from the content hash, so
  # stripping it would otherwise hide a machine-accepted story from the drain;
  # the authored `afk-accept:` declaration is inside the hash and closes that.
  seed_story
  bash "$MARK" --pure-decomposition docs/stories/draft/STORY-901-a-story.md 2>/dev/null
  sed -i.bak '/^oversight-basis:/d' docs/stories/draft/STORY-901-a-story.md
  run bash -c "bash '$SCRIPTS/detect-unratified-stories-maps.sh' --with-afk-accepted docs/stories docs/story-maps 2>&1 >/dev/null"
  echo "$output" | grep -q 'STORY-901'
}

# --- the marker write path ---------------------------------------------------

@test "--pure-decomposition records the basis AND leaves the story ratified" {
  seed_story
  bash "$MARK" --pure-decomposition docs/stories/draft/STORY-901-a-story.md 2>/dev/null
  grep -q '^oversight-basis: pure-decomposition' docs/stories/draft/STORY-901-a-story.md
  # The basis line is excluded from the hash, so the story must NOT read as
  # drifted the instant it is marked.
  run bash -c "source '$SCRIPTS/../lib/story-oversight.sh'; is_story_map_ratified docs/stories/draft/STORY-901-a-story.md"
  [ "$status" -eq 0 ]
}

@test "a plain re-ratify CLEARS a stale pure-decomposition basis" {
  seed_story
  bash "$MARK" --pure-decomposition docs/stories/draft/STORY-901-a-story.md 2>/dev/null
  bash "$MARK" docs/stories/draft/STORY-901-a-story.md 2>/dev/null
  ! grep -q '^oversight-basis:' docs/stories/draft/STORY-901-a-story.md
}
