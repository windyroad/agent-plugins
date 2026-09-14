#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  MIGRATE="$REPO_ROOT/packages/itil/scripts/migrate-story-map.mjs"
  HISTORY="$REPO_ROOT/packages/itil/scripts/story-map-history.mjs"
}

fixture() {
  local root="$1"
  mkdir -p "$root/docs/story-maps/accepted" "$root/docs/decisions"
  MAP="$root/docs/story-maps/accepted/STORY-MAP-990-history.html"
  MAPPING="$root/mapping.json"
  printf '<html><body>Legacy signal Research only</body></html>\n' > "$MAP"
  git -C "$root" init -q
  git -C "$root" config user.email test@example.com
  git -C "$root" config user.name Test
  git -C "$root" add "$MAP"
  git -C "$root" commit -qm 'retain legacy map'
  local source_hash source_commit
  source_hash="$(shasum -a 256 "$MAP" | awk '{print $1}')"
  source_commit="$(git -C "$root" rev-parse HEAD)"
  cat > "$MAPPING" <<EOF
{
  "mapId": "STORY-MAP-990",
  "path": "docs/story-maps/accepted/STORY-MAP-990-history.html",
  "authorityAdr": "ADR-300",
  "sourceCommit": "$source_commit",
  "sourceSha256": "$source_hash",
  "map": {
    "storyMapId": "STORY-MAP-990",
    "title": "Historical journey",
    "backbone": [{ "id": "notice", "title": "Notice it" }],
    "releases": [{
      "id": "legacy-r1",
      "name": "R1",
      "preRfc": true,
      "historicalProjection": {
        "reported": "2026-01-02",
        "sourceBandId": "r1",
        "sourceLabel": "R1",
        "sourceNote": "Recorded before migration",
        "cards": [{ "activity": "notice", "title": "Legacy signal", "text": "Recorded in the retained map.", "statusLabel": "Research only" }]
      }
    }],
    "tasks": []
  }
}
EOF
  local historical_hash
  historical_hash="$(HISTORY_PATH="$HISTORY" MAPPING_PATH="$MAPPING" node --input-type=module -e '
    const fs = await import("node:fs");
    const history = await import(`file://${process.env.HISTORY_PATH}`);
    const mapping = JSON.parse(fs.readFileSync(process.env.MAPPING_PATH, "utf8"));
    process.stdout.write(history.historicalProjectionHash(mapping.map));
  ')"
  cat > "$root/docs/decisions/300-history.proposed.md" <<EOF
---
human-oversight: confirmed
legacy-projections:
  STORY-MAP-990: $historical_hash
---
# History migration
EOF
}

@test "migrates one ratified legacy map and is idempotent" {
  local root="$BATS_TEST_TMPDIR/repo"
  fixture "$root"

  run bash -c 'cd "$1" && node "$2" "$3" "$4"' _ "$root" "$MIGRATE" "$MAP" "$MAPPING"
  [ "$status" -eq 0 ] || { echo "$output"; return 1; }
  grep -q '<script id="story-map-data"' "$MAP"
  grep -q 'Historical context' "$MAP"
  grep -q '"canonicalSha256": "[a-f0-9]\{64\}"' "$root/docs/story-maps/legacy-projection-manifest.json"
  local first
  first="$(shasum -a 256 "$MAP" "$root/docs/story-maps/legacy-projection-manifest.json")"

  run bash -c 'cd "$1" && node "$2" "$3" "$4"' _ "$root" "$MIGRATE" "$MAP" "$MAPPING"
  [ "$status" -eq 0 ]
  [ "$first" = "$(shasum -a 256 "$MAP" "$root/docs/story-maps/legacy-projection-manifest.json")" ]
}

@test "the packed package executes the migration command" {
  local root="$BATS_TEST_TMPDIR/repo"
  local packed="$BATS_TEST_TMPDIR/packed"
  fixture "$root"
  mkdir -p "$packed"
  run npm pack "$REPO_ROOT/packages/itil" --pack-destination "$packed"
  [ "$status" -eq 0 ] || { echo "$output"; return 1; }
  tar -xzf "$packed"/*.tgz -C "$packed"

  run bash -c 'cd "$1" && "$2" "$3" "$4"' _ "$root" "$packed/package/bin/wr-itil-migrate-story-map" "$MAP" "$MAPPING"
  [ "$status" -eq 0 ] || { echo "$output"; return 1; }
  grep -q '<script id="story-map-data"' "$MAP"
  grep -q 'Historical context' "$MAP"
}

@test "rejects a mismatched source fingerprint before writing" {
  local root="$BATS_TEST_TMPDIR/repo"
  fixture "$root"
  printf '\nchanged\n' >> "$MAP"
  local before
  before="$(shasum -a 256 "$MAP")"

  run bash -c 'cd "$1" && node "$2" "$3" "$4"' _ "$root" "$MIGRATE" "$MAP" "$MAPPING"
  [ "$status" -ne 0 ]
  [ "$before" = "$(shasum -a 256 "$MAP")" ]
  [ ! -e "$root/docs/story-maps/legacy-projection-manifest.json" ]
}

@test "rejects incomplete, ambiguous, or invalid mappings before writing" {
  local root="$BATS_TEST_TMPDIR/repo"
  fixture "$root"
  cp "$MAPPING" "$root/original-mapping.json"
  local mode before
  before="$(shasum -a 256 "$MAP")"

  for mode in missing extra map-id path subtype card; do
    cp "$root/original-mapping.json" "$MAPPING"
    MODE="$mode" MAPPING_PATH="$MAPPING" node - <<'NODE'
const fs = require('node:fs');
const path = process.env.MAPPING_PATH;
const mapping = JSON.parse(fs.readFileSync(path, 'utf8'));
switch (process.env.MODE) {
  case 'missing': delete mapping.sourceCommit; break;
  case 'extra': mapping.ambiguous = true; break;
  case 'map-id': mapping.mapId = 'STORY-MAP-991'; break;
  case 'path': mapping.path = 'docs/story-maps/accepted/wrong.html'; break;
  case 'subtype': mapping.map.releases[0].preRfc = false; break;
  case 'card': delete mapping.map.releases[0].historicalProjection.cards[0].text; break;
}
fs.writeFileSync(path, JSON.stringify(mapping, null, 2));
NODE
    run bash -c 'cd "$1" && node "$2" "$3" "$4"' _ "$root" "$MIGRATE" "$MAP" "$MAPPING"
    [ "$status" -ne 0 ] || { echo "$mode unexpectedly passed"; return 1; }
    [ "$before" = "$(shasum -a 256 "$MAP")" ]
    [ ! -e "$root/docs/story-maps/legacy-projection-manifest.json" ]
  done
}

@test "renderer rejects broken manifest and authority evidence" {
  local root="$BATS_TEST_TMPDIR/repo"
  fixture "$root"
  run bash -c 'cd "$1" && node "$2" "$3" "$4"' _ "$root" "$MIGRATE" "$MAP" "$MAPPING"
  [ "$status" -eq 0 ]
  local manifest="$root/docs/story-maps/legacy-projection-manifest.json"
  local decision="$root/docs/decisions/300-history.proposed.md"
  cp "$manifest" "$root/original-manifest.json"
  cp "$decision" "$root/original-decision.md"
  local mode

  for mode in missing-manifest schema map-id path source history missing-authority unconfirmed mismatched-authority; do
    cp "$root/original-manifest.json" "$manifest"
    cp "$root/original-decision.md" "$decision"
    case "$mode" in
      missing-manifest) rm "$manifest" ;;
      missing-authority) rm "$decision" ;;
      unconfirmed) sed 's/human-oversight: confirmed/human-oversight: pending/' "$root/original-decision.md" > "$decision" ;;
      mismatched-authority) sed -E 's/(STORY-MAP-990: )[a-f0-9]{64}/\1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff/' "$root/original-decision.md" > "$decision" ;;
      *) MODE="$mode" MANIFEST_PATH="$manifest" node - <<'NODE'
const fs = require('node:fs');
const path = process.env.MANIFEST_PATH;
const manifest = JSON.parse(fs.readFileSync(path, 'utf8'));
switch (process.env.MODE) {
  case 'schema': manifest.schemaVersion = 2; break;
  case 'map-id': manifest.maps[0].mapId = 'STORY-MAP-991'; break;
  case 'path': manifest.maps[0].path = 'docs/story-maps/accepted/wrong.html'; break;
  case 'source': manifest.maps[0].sourceSha256 = '0'.repeat(64); break;
  case 'history': manifest.maps[0].historicalSha256 = '0'.repeat(64); break;
}
fs.writeFileSync(path, JSON.stringify(manifest, null, 2));
NODE
      ;;
    esac
    run node "$REPO_ROOT/packages/itil/scripts/render-story-map.mjs" "$MAP"
    [ "$status" -ne 0 ] || { echo "$mode unexpectedly passed"; return 1; }
  done
}
