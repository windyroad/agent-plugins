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
