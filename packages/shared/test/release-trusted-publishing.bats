#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  WORKFLOW="$REPO_ROOT/.github/workflows/release.yml"
  VERIFY_TAGS="$REPO_ROOT/scripts/verify-release-dist-tags.sh"
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "release uses one token-free OIDC workflow for stable and preview publishing" {
  [ -f "$WORKFLOW" ]
  [ ! -e "$REPO_ROOT/.github/workflows/release-preview.yml" ]
  [ "$(grep -Rl 'npm publish\|npm run release' "$REPO_ROOT/.github/workflows" --include='*.yml' | wc -l | tr -d ' ')" -eq 1 ]
  grep -F 'id-token: write' "$WORKFLOW"
  grep -F 'node-version: 24' "$WORKFLOW"
  grep -F 'npm@11.5.1' "$WORKFLOW"
  grep -F 'publish: npm run release' "$WORKFLOW"
  grep -F "if: steps.changesets.outputs.hasChangesets == 'false'" "$WORKFLOW"
  grep -F 'bash scripts/verify-release-dist-tags.sh' "$WORKFLOW"
  grep -F 'npm publish --tag preview --provenance --access public' "$WORKFLOW"
  ! grep -E 'NPM_TOKEN|NPM_AUTH_TOKEN|NODE_AUTH_TOKEN' "$WORKFLOW"
}

@test "stable release fails when a published package is not tagged latest" {
  mkdir -p "$TEST_TMPDIR/packages/agent-plugins"
  printf '%s\n' '{"name":"@windyroad/agent-plugins","version":"0.2.0"}' \
    > "$TEST_TMPDIR/packages/agent-plugins/package.json"
  printf '%s\n' '#!/bin/bash' 'echo 0.1.6' > "$TEST_TMPDIR/npm"
  chmod +x "$TEST_TMPDIR/npm"

  run env PACKAGE_ROOT="$TEST_TMPDIR/packages" NPM_CMD="$TEST_TMPDIR/npm" \
    bash "$VERIFY_TAGS"

  [ "$status" -eq 1 ]
  [[ "$output" == *'@windyroad/agent-plugins@0.2.0 is published without latest (registry latest: 0.1.6)'* ]]
}
