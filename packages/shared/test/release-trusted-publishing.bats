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
  grep -F 'bash scripts/verify-release-dist-tags.sh --pre-publish' "$REPO_ROOT/package.json"
  grep -F 'bash scripts/verify-release-dist-tags.sh --pre-publish' "$WORKFLOW"
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
    POST_PUBLISH_ATTEMPTS=1 bash "$VERIFY_TAGS"

  [ "$status" -eq 1 ]
  [[ "$output" == *'@windyroad/agent-plugins@0.2.0 is published without latest (registry latest: 0.1.6)'* ]]
}

@test "stable release retries while npm latest is still propagating" {
  make_candidate_package
  printf '%s\n' '#!/bin/bash' \
    'count_file="'"$TEST_TMPDIR"'/count"' \
    'count=$(cat "$count_file" 2>/dev/null || echo 0)' \
    'count=$((count + 1))' \
    'echo "$count" > "$count_file"' \
    'if [ "$count" -lt 2 ]; then echo 0.1.7; else echo 0.2.0; fi' \
    > "$TEST_TMPDIR/npm"
  chmod +x "$TEST_TMPDIR/npm"

  run env PACKAGE_ROOT="$TEST_TMPDIR/packages" NPM_CMD="$TEST_TMPDIR/npm" \
    POST_PUBLISH_ATTEMPTS=2 POST_PUBLISH_DELAY=0 bash "$VERIFY_TAGS"

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMPDIR/count")" -eq 2 ]
}

@test "pre-publish allows a version absent from npm" {
  make_candidate_package
  make_fake_npm absent 0.1.7

  run env PACKAGE_ROOT="$TEST_TMPDIR/packages" NPM_CMD="$TEST_TMPDIR/npm" \
    bash "$VERIFY_TAGS" --pre-publish

  [ "$status" -eq 0 ]
}

@test "pre-publish allows an unchanged version already tagged latest" {
  make_candidate_package
  make_fake_npm 0.2.0 0.2.0

  run env PACKAGE_ROOT="$TEST_TMPDIR/packages" NPM_CMD="$TEST_TMPDIR/npm" \
    bash "$VERIFY_TAGS" --pre-publish

  [ "$status" -eq 0 ]
}

@test "pre-publish rejects an immutable version collision" {
  make_candidate_package
  make_fake_npm 0.2.0 0.1.7

  run env PACKAGE_ROOT="$TEST_TMPDIR/packages" NPM_CMD="$TEST_TMPDIR/npm" \
    bash "$VERIFY_TAGS" --pre-publish

  [ "$status" -eq 1 ]
  [[ "$output" == *'@windyroad/agent-plugins@0.2.0 already exists but is not latest (registry latest: 0.1.7); choose a new version'* ]]
}

make_candidate_package() {
  mkdir -p "$TEST_TMPDIR/packages/agent-plugins"
  printf '%s\n' '{"name":"@windyroad/agent-plugins","version":"0.2.0"}' \
    > "$TEST_TMPDIR/packages/agent-plugins/package.json"
}

make_fake_npm() {
  exact="$1"
  latest="$2"
  printf '%s\n' '#!/bin/bash' \
    'if [[ "$*" == *"dist-tags.latest"* ]]; then echo '"$latest"'; exit 0; fi' \
    'if [ "'"$exact"'" = absent ]; then exit 1; fi' \
    'echo '"$exact" \
    > "$TEST_TMPDIR/npm"
  chmod +x "$TEST_TMPDIR/npm"
}
