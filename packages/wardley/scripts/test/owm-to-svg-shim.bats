#!/usr/bin/env bats
#
# Behavioural coverage for the version-stable converter entry point (P437).
# Asserts what an adopter experiences: the command and its dispatch target both
# reach the published tarball, and the command resolves to the newest installed
# version rather than the one a caller happened to name.
#
# @adr ADR-049 (plugin scripts resolve via bin/ on $PATH)
# @adr ADR-080 (highest-version-wins shim wrapper)
# @adr ADR-052 (behavioural tests by default)
# @problem P437

setup() {
  PACKAGE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

# Packs the workspace once per test into $TMP and extracts it to $1.
pack_into() {
  local dest="$1"
  npm pack "$PACKAGE" --pack-destination "$TMP" >/dev/null
  local tarball
  tarball="$(find "$TMP" -maxdepth 1 -name '*.tgz' -print -quit)"
  [ -n "$tarball" ] || return 1
  mkdir -p "$dest"
  tar -xzf "$tarball" -C "$dest" --strip-components=1
}

@test "the published tarball carries the converter command and the file it dispatches to" {
  run npm pack "$PACKAGE" --pack-destination "$TMP"
  [ "$status" -eq 0 ]
  tarball="$(find "$TMP" -maxdepth 1 -name '*.tgz' -print -quit)"
  [ -n "$tarball" ]

  run tar -tzf "$tarball"
  [ "$status" -eq 0 ]
  # Guard against a vacuous pass: an empty listing must fail here, not slip
  # through the membership assertions below.
  [ "${#lines[@]}" -gt 0 ]
  [[ "$output" == *"package/bin/wr-wardley-owm-to-svg"* ]]
  [[ "$output" == *"package/scripts/owm-to-svg.sh"* ]]
  [[ "$output" == *"package/skills/generate/owm-to-svg.mjs"* ]]
  # The behavioural tests themselves stay out of the shipped artefact.
  [[ "$output" != *"package/scripts/test/"* ]]
}

@test "the command converts a map when invoked from an unrelated working directory" {
  pack_into "$TMP/install"
  cat > "$TMP/sample.owm" <<'OWM'
title Sample
anchor Reader [0.95, 0.55]
component Map [0.70, 0.60]
Reader->Map
OWM
  mkdir -p "$TMP/elsewhere"
  cd "$TMP/elsewhere"

  run "$TMP/install/bin/wr-wardley-owm-to-svg" "$TMP/sample.owm" "$TMP/sample.svg"
  [ "$status" -eq 0 ]
  [ -s "$TMP/sample.svg" ]
  run cat "$TMP/sample.svg"
  [[ "$output" == *"<svg"* ]]
  [[ "$output" == *"Sample"* ]]
}

@test "from a versioned cache the command dispatches to the newest installed version" {
  # Two versions side by side, as a marketplace cache holds them. The caller
  # invokes the older one; the newer one must answer.
  pack_into "$TMP/cache/wr-wardley/0.9.0"
  pack_into "$TMP/cache/wr-wardley/0.10.0"

  # Mark which version each dispatch target belongs to, so the assertion can
  # tell them apart by behaviour rather than by inspecting the shim source.
  for v in 0.9.0 0.10.0; do
    cat > "$TMP/cache/wr-wardley/$v/scripts/owm-to-svg.sh" <<EOF
#!/usr/bin/env bash
echo "dispatched-to-$v"
EOF
    chmod +x "$TMP/cache/wr-wardley/$v/scripts/owm-to-svg.sh"
  done

  run "$TMP/cache/wr-wardley/0.9.0/bin/wr-wardley-owm-to-svg"
  [ "$status" -eq 0 ]
  # sort -V, not lexicographic: 0.10.0 is newer than 0.9.0.
  [[ "$output" == *"dispatched-to-0.10.0"* ]]
}
