#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  WORKFLOW="$REPO_ROOT/.github/workflows/release.yml"
}

@test "release uses one token-free OIDC workflow for stable and preview publishing" {
  [ -f "$WORKFLOW" ]
  [ ! -e "$REPO_ROOT/.github/workflows/release-preview.yml" ]
  [ "$(grep -Rl 'npm publish\|npm run release' "$REPO_ROOT/.github/workflows" --include='*.yml' | wc -l | tr -d ' ')" -eq 1 ]
  grep -F 'id-token: write' "$WORKFLOW"
  grep -F 'node-version: 24' "$WORKFLOW"
  grep -F 'npm@11.5.1' "$WORKFLOW"
  grep -F 'publish: npm run release' "$WORKFLOW"
  grep -F 'npm publish --tag preview --provenance --access public' "$WORKFLOW"
  ! grep -E 'NPM_TOKEN|NPM_AUTH_TOKEN|NODE_AUTH_TOKEN' "$WORKFLOW"
}
