#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
}

@test "Codex-compatible skills declare exact WR-prefixed display names" {
  while IFS="|" read -r package skill display_name; do
    local metadata="$REPO_ROOT/packages/$package/skills/$skill/agents/openai.yaml"
    [ -f "$metadata" ]
    grep -Fxq "  display_name: \"$display_name\"" "$metadata"
    grep -Eq '^  short_description: ".+"$' "$metadata"
  done <<'EOF'
architect|capture-adr|WR Architect: Capture ADR
architect|create-adr|WR Architect: Create ADR
architect|review-decisions|WR Architect: Review Decisions
architect|review-design|WR Architect: Review Design
cruise|status|WR Cruise: Status
wardley|generate|WR Wardley: Generate
risk-scorer|assess-external-comms|WR Risk Scorer: Assess External Comms
risk-scorer|assess-inbound-report|WR Risk Scorer: Assess Inbound Report
risk-scorer|assess-release|WR Risk Scorer: Assess Release
risk-scorer|assess-wip|WR Risk Scorer: Assess WIP
risk-scorer|bootstrap-catalog|WR Risk Scorer: Bootstrap Catalog
risk-scorer|create-risk|WR Risk Scorer: Create Risk
risk-scorer|external-comms|WR Risk Scorer: External Comms
risk-scorer|pipeline|WR Risk Scorer: Pipeline
risk-scorer|update-policy|WR Risk Scorer: Update Policy
risk-scorer|wip|WR Risk Scorer: WIP
EOF
}

# Coverage is derived from .codex-plugin/ presence, including packages that
# project canonical skill sources into a generated runtime directory.
@test "every skill of every Codex-bearing package declares interface metadata" {
  local missing=() manifests=("$REPO_ROOT"/packages/*/.codex-plugin/plugin.json)
  # Guard the unmatched-glob case, or a path rename makes this test vacuous.
  [ -f "${manifests[0]}" ]
  for manifest in "${manifests[@]}"; do
    local package_dir
    package_dir="$(dirname "$(dirname "$manifest")")"
    for skill in "$package_dir"/skills/*/SKILL.md; do
      [ -f "$skill" ] || continue
      local metadata
      metadata="$(dirname "$skill")/agents/openai.yaml"
      [ -f "$metadata" ] || missing+=("${metadata#"$REPO_ROOT"/}")
    done
  done
  [ "${#missing[@]}" -eq 0 ] || {
    printf 'missing interface metadata: %s\n' "${missing[@]}"
    false
  }
}

@test "risk-scorer Codex pack transform preserves skill interface metadata" {
  local tmp="$BATS_TEST_TMPDIR/risk-scorer"
  mkdir -p "$tmp/scripts"
  cp "$REPO_ROOT/packages/risk-scorer/scripts/sync-codex-skills.mjs" "$tmp/scripts/"
  cp -R "$REPO_ROOT/packages/risk-scorer/skills" "$tmp/"

  run node "$tmp/scripts/sync-codex-skills.mjs" --pack
  [ "$status" -eq 0 ]
  grep -Fxq '  display_name: "WR Risk Scorer: Update Policy"' \
    "$tmp/skills/update-policy/agents/openai.yaml"

  run node "$tmp/scripts/sync-codex-skills.mjs" --restore-pack
  [ "$status" -eq 0 ]
}

# P527: Codex namespaces every skill by the plugin manifest `name`, so a skill's
# own frontmatter `name:` must be BARE. A prefixed one lands twice and the
# advertised invocation cannot be typed. Coverage is derived from generator
# presence, not hand-enumerated, so a package that gains a projection cannot
# ship without this check (same property the metadata test above relies on).
@test "every Codex projection generator emits a bare frontmatter name" {
  local generators=("$REPO_ROOT"/packages/*/scripts/sync-codex-skills.mjs)
  # Guard the unmatched-glob case, or a path rename makes this test vacuous.
  [ -f "${generators[0]}" ]

  # NOT $BATS_TEST_TMPDIR: it contains a path component named `test`, and itil's
  # projection filters any path with one out of the copy, so the fixture would
  # vanish and the assertion would never run.
  local sandbox
  sandbox="$(mktemp -d)"

  local offenders=()
  for generator in "${generators[@]}"; do
    local package tmp mode outdir
    package="$(basename "$(dirname "$(dirname "$generator")")")"
    tmp="$sandbox/$package"
    mkdir -p "$tmp/scripts" "$tmp/skills/demo-skill" "$tmp/agents"
    cp "$generator" "$tmp/scripts/sync-codex-skills.mjs"
    : > "$tmp/README.md"
    : > "$tmp/CHANGELOG.md"
    # The prefixed name is the defect under test: the generator must strip it.
    printf '%s\n' '---' "name: wr-$package:demo-skill" 'description: Demo' '---' \
      'Body.' > "$tmp/skills/demo-skill/SKILL.md"

    # itil projects into skills-codex/; architect and risk-scorer rewrite
    # skills/ in place at pack time. Read the output wherever it lands.
    if grep -q '\-\-build' "$generator"; then
      mode="--build"
      outdir="$tmp/skills-codex"
    else
      mode="--pack"
      outdir="$tmp/skills"
    fi

    run node "$tmp/scripts/sync-codex-skills.mjs" "$mode"
    [ "$status" -eq 0 ] || {
      printf '%s generator failed on %s: %s\n' "$package" "$mode" "$output"
      rm -rf "$sandbox"
      false
    }
    [ -f "$outdir/demo-skill/SKILL.md" ]

    local declared
    # Not awk -F': *': a still-prefixed name would be truncated at its second
    # colon and the failure message would misreport what was generated.
    declared="$(sed -n 's/^name: //p' "$outdir/demo-skill/SKILL.md" | head -1)"
    [ "$declared" = "demo-skill" ] || offenders+=("$package: name=$declared want=demo-skill")
  done
  rm -rf "$sandbox"

  [ "${#offenders[@]}" -eq 0 ] || {
    printf 'generated skill name is not bare: %s\n' "${offenders[@]}"
    false
  }
}

@test "the bare-name rewrite is scoped to frontmatter and spares display names" {
  local tmp="$BATS_TEST_TMPDIR/scoped"
  mkdir -p "$tmp/scripts" "$tmp/skills/update-policy/agents"
  cp "$REPO_ROOT/packages/risk-scorer/scripts/sync-codex-skills.mjs" "$tmp/scripts/"
  printf '%s\n' '---' 'name: wr-risk-scorer:update-policy' 'description: Demo' '---' \
    'Body line.' 'name: this body line must survive' > "$tmp/skills/update-policy/SKILL.md"
  printf '%s\n' 'interface:' '  display_name: "WR Risk Scorer: Update Policy"' \
    '  short_description: "Demo"' > "$tmp/skills/update-policy/agents/openai.yaml"

  run node "$tmp/scripts/sync-codex-skills.mjs" --pack
  [ "$status" -eq 0 ]

  grep -Fxq 'name: update-policy' "$tmp/skills/update-policy/SKILL.md"
  grep -Fxq 'name: this body line must survive' "$tmp/skills/update-policy/SKILL.md"
  grep -Fxq '  display_name: "WR Risk Scorer: Update Policy"' \
    "$tmp/skills/update-policy/agents/openai.yaml"
}
