#!/usr/bin/env bats
# The island documented in SKILL.md must still render a correct map.
#
# The fixture is EXTRACTED FROM THE SKILL, not copied beside it. That is the
# whole point: a copy drifts, and this is a test about drift. When the documented
# template and the renderer disagree, an agent following the skill authors a map
# the tooling then renders wrongly — silently, because both halves work.
#
# Not hypothetical. On 2026-08-07 the map format changed repeatedly across one
# session: card `value` and row `badge` were removed, the `lead` and `traceProse`
# prose blocks deleted, a row's label became its RFC identity. The renderer, the
# maps and the tests were all updated. SKILL.md was not, for the whole session —
# it kept documenting fields that no longer existed, and `story-map-edit` kept
# writing two of them back. Nothing noticed, because nothing bound the document
# to the tool.
#
# The extraction is anchored on a NAMED MARKER rather than "the first ```json
# fence". Fence ordinality is positional: the second json fence anyone adds
# silently changes this test's subject with no failure.
#
# @adr ADR-102 (maps render from JSON through a canonical template)
# @adr ADR-104 (a card stores no value a story file already carries)
# @adr ADR-105 (the grid ships in the file)
# @adr ADR-052 (behavioural-only — no structural assertions on SKILL.md prose)

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../../../.." && pwd)"
  SKILL="$BATS_TEST_DIRNAME/../SKILL.md"
  RENDER="$REPO_ROOT/packages/itil/scripts/render-story-map.mjs"
  IN_DOM="$REPO_ROOT/packages/itil/scripts/test/lib/render-in-dom.mjs"
  TMP="$BATS_TEST_TMPDIR/w"
  mkdir -p "$TMP/docs/story-maps/draft" "$TMP/docs/stories/done"
  printf -- '---\nstatus: done\n---\n\n# STORY-901\n\n## User value (INVEST Valuable)\n\nIn order to keep the documented template honest, as a developer, I want the skill own island rendered.\n' \
    > "$TMP/docs/stories/done/STORY-901-x.md"
  MAP="$TMP/docs/story-maps/draft/STORY-MAP-909-fixture.html"
  ISLAND="$TMP/island.json"
  _extract > "$ISLAND"
}

# The island the skill documents, between its declared markers, with only the
# <…> placeholders resolved. Which KEYS exist is whatever the skill says —
# untouched, because that is the thing under test.
_extract() {
  awk '/documented-island:begin/{f=1;next} f&&/documented-island:end/{exit} f' "$SKILL" \
    | sed -e '/^```/d' \
          -e 's/STORY-MAP-<NNN>/STORY-MAP-909/' \
          -e 's/"<Title>"/"Documented"/' \
          -e 's/"<persona>"/"developer"/' \
          -e 's/<YYYY-MM-DD>/2026-08-08/' \
          -e 's/"<git config user.name>"/"Test"/' \
          -e 's/JTBD-<NNN>/JTBD-008/g' \
          -e 's/RFC-<NNN>/RFC-060/g'   -e 's/STORY-<NNN>/STORY-901/g' \
          -e 's/P<NNN>/P170/g' \
          -e 's/"<slug>"/"a"/' -e 's/"A. <Activity>"/"A. First step"/' \
          -e 's/"<optional JTBD or gloss>"/"JTBD-008"/' \
          -e 's/"rfc-<nnn>"/"rfc-060"/' \
          -e 's/"<what this release delivers>"/"What ships together"/' \
          -e 's/"<optional>"/"a note"/' \
          -e 's/"<backbone id>"/"a"/' -e 's/"<release id>"/"rfc-060"/' \
          -e 's/"<what the persona can do>"/"Do the thing"/'
}

# Author a map from an island and render it. Echoes the rendered path.
_render_island() {
  local src="$1" out="$2"
  { printf '<script id="story-map-data" type="application/json">\n'
    cat "$src"
    printf '\n</script>\n'; } > "$out"
  node "$RENDER" "$out" >/dev/null 2>&1
}

# The rendered document minus its data island: the <meta> block, the grid, and
# the derived-status island. That is everything a key is supposed to affect.
_presentation() {
  node "$IN_DOM" "$1" | awk '
    /<script id="story-map-data"/ { skip=1 }
    !skip { print }
    skip && /<\/script>/ { skip=0 }
  '
}

@test "the documented island extracts, and the renderer accepts it" {
  # Guards the extraction. Without this the whole file passes vacuously the day
  # the markers move — the vacuous-green class this repo has been bitten by.
  [ -s "$ISLAND" ]
  run bash -c "node -e \"JSON.parse(require('fs').readFileSync('$ISLAND','utf8'))\""
  [ "$status" -eq 0 ]
  # No unresolved placeholder survived the substitution.
  run bash -c "grep -c '<[A-Za-z]' '$ISLAND' || true"
  [ "$output" -eq 0 ]
  # Acceptance is asserted behaviourally: the renderer throws on a missing
  # backbone or releases, so exit 0 carries "has the keys it needs".
  run _render_island "$ISLAND" "$MAP"
  [ "$status" -eq 0 ]
}

@test "a map authored from the documented island renders in the ratified shape" {
  _render_island "$ISLAND" "$MAP"
  local d="$TMP/dom.html"; node "$IN_DOM" "$MAP" > "$d"

  # The grid is in the file — nothing draws it at view time (ADR-105).
  run bash -c "grep -o '<table class=\"map\"' '$MAP' | wc -l | tr -d ' '"
  [ "$output" -eq 1 ]

  # A row is labelled by its RFC identity, not an authored ordinal (ADR-103).
  run bash -c "grep -o 'RFC-060' '$d' | wc -l | tr -d ' '"
  [ "$output" -ge 1 ]

  # The card's value comes from the STORY file, not the island (ADR-104).
  run bash -c "grep -c 'keep the documented template honest' '$d'"
  [ "$output" -ge 1 ]

  # The removed blocks stay removed. Anchored on STRUCTURES, not words: the
  # renderer legitimately emits class="badge" and class="v-lead", so grepping
  # for `lead` or `badge` would pass or fail for the wrong reason.
  for gone in 'id="story-map-lead"' 'class="legend"' 'story-map-trace-section' '<footer'; do
    run bash -c "grep -c '$gone' '$d' || true"
    [ "$output" -eq 0 ] || { echo "documented island re-introduced: $gone"; return 1; }
  done
}

@test "every field the skill documents is load-bearing" {
  # The property: a key whose removal changes nothing in the output is a key the
  # renderer ignores, and documenting it tells an author to write something inert.
  #
  # Stated as a differential rather than as a denylist of known-dead fields. A
  # denylist only ever catches the fields already known — and SKILL.md itself
  # says "the seventh will be whatever gets added back". This catches the
  # seventh. It is also ADR-052-clean: it asserts what the RENDERER does with
  # each key, never what the prose says.
  _render_island "$ISLAND" "$MAP"
  local base="$TMP/base.html"; cp "$MAP" "$base"

  local keys; keys="$(node -e "
    const d=JSON.parse(require('fs').readFileSync('$ISLAND','utf8'));
    const out=new Set(Object.keys(d));
    // 'traces' is an OBJECT among three arrays. Descending into it matters:
    // without this, traces.rfcs and traces.adrs sat outside the one test built
    // to catch inert documented keys, and could have been re-added freely.
    // Discriminate on shape, not on the name — a name check would be a fifth
    // enumeration in the file whose whole subject is enumerations drifting.
    for (const c of ['backbone','releases','tasks','traces']) {
      const v = d[c];
      if (Array.isArray(v)) { for (const el of v) Object.keys(el).forEach(k=>out.add(c+'.'+k)); }
      else if (v && typeof v === 'object') { Object.keys(v).forEach(k=>out.add(c+'.'+k)); }
    }
    // storyMapId only reaches the output via the caption fallback when title is
    // absent, so it is observable here but interacts. Assert it separately.
    out.delete('storyMapId');
    process.stdout.write([...out].join(' '));")"
  [ -n "$keys" ]

  local inert=""
  for k in $keys; do
    rm -f "$TMP/probe.json" "$TMP/docs/story-maps/draft/probe.html"
    node -e "
      const fs=require('fs');
      const d=JSON.parse(fs.readFileSync('$ISLAND','utf8'));
      const k='$k';
      if (k.includes('.')) {
        const [c,f]=k.split('.');
        // d.traces is an object, not iterable — `for (const el of d.traces)` throws.
        if (Array.isArray(d[c])) { for (const el of d[c]) delete el[f]; }
        else if (d[c]) { delete d[c][f]; }
      }
      else delete d[k];
      fs.writeFileSync('$TMP/probe.json', JSON.stringify(d,null,2));" \
      || { echo "probe build failed for key: $k"; return 1; }
    # The probe MUST live beside the base. The renderer resolves the story
    # corpus relative to the map's own path, so a probe rendered elsewhere finds
    # no stories, derives nothing, and differs from the base for that reason
    # alone — which made every key look load-bearing. Caught by proving RED
    # twice: the test stayed green with a known-dead field documented.
    # A render REFUSAL is proof the key is load-bearing, not a harness error:
    # backbone, releases and tasks.storyId all make the renderer throw when
    # deleted. Classify it rather than cmp-ing, and never let a stale probe from
    # the previous iteration stand in for one that was never written.
    if ! _render_island "$TMP/probe.json" "$TMP/docs/story-maps/draft/probe.html"; then
      continue
    fi
    # Compare everything EXCEPT the data island. The island is the input; it
    # always differs when a key is deleted from it, so including it made every
    # field look load-bearing and the test could never fail. Caught by proving
    # RED — it passed with a known-dead `value` field documented.
    _presentation "$base"                                 > "$TMP/a.html"
    _presentation "$TMP/docs/story-maps/draft/probe.html" > "$TMP/b.html"
    if cmp -s "$TMP/a.html" "$TMP/b.html"; then inert="$inert $k"; fi
  done
  [ -z "$inert" ] || { echo "SKILL.md documents fields the renderer ignores:$inert"; return 1; }
}
