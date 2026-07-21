#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  PACKAGE="$REPO_ROOT/packages/risk-scorer"
}

@test "risk-scorer Codex plugin manifest exists and is packaged" {
  [ -f "$PACKAGE/.codex-plugin/plugin.json" ]
  run grep -n '"name": "wr-risk-scorer"' "$PACKAGE/.codex-plugin/plugin.json"
  [ "$status" -eq 0 ]
  run grep -n '"skills": "./skills/"' "$PACKAGE/.codex-plugin/plugin.json"
  [ "$status" -eq 0 ]
  run grep -n '".codex-plugin/"' "$PACKAGE/package.json"
  [ "$status" -eq 0 ]
  run grep -n '".agents/"' "$PACKAGE/package.json"
  [ "$status" -eq 0 ]
}

@test "risk-scorer repo-local marketplace entry exists" {
  run grep -n '"name": "wr-risk-scorer"' "$REPO_ROOT/.agents/plugins/marketplace.json"
  [ "$status" -eq 0 ]
  run grep -n '"path": "./packages/risk-scorer"' "$REPO_ROOT/.agents/plugins/marketplace.json"
  [ "$status" -eq 0 ]
}

@test "risk-scorer package-local marketplace entry exists for published Codex installs" {
  [ -f "$PACKAGE/.agents/plugins/marketplace.json" ]
  run grep -n '"name": "wr-risk-scorer"' "$PACKAGE/.agents/plugins/marketplace.json"
  [ "$status" -eq 0 ]
  run grep -n '"path": "."' "$PACKAGE/.agents/plugins/marketplace.json"
  [ "$status" -eq 0 ]
}

@test "risk-scorer installer exposes runtime option and passes it through" {
  run grep -n -- "--runtime" "$PACKAGE/bin/install.mjs"
  [ "$status" -eq 0 ]
  run grep -n 'codex plugin marketplace add ${PACKAGE_ROOT}' "$PACKAGE/bin/install.mjs"
  [ "$status" -eq 0 ]
  run grep -n "codexInstall()" "$PACKAGE/bin/install.mjs"
  [ "$status" -eq 0 ]
}

@test "risk-scorer Codex skills are generated during pack and source skills restore after pack" {
  run grep -n '"prepack": "node scripts/sync-codex-skills.mjs --pack"' "$PACKAGE/package.json"
  [ "$status" -eq 0 ]
  run grep -n '"postpack": "node scripts/sync-codex-skills.mjs --restore-pack"' "$PACKAGE/package.json"
  [ "$status" -eq 0 ]
  run grep -n "packages/risk-scorer/.pack-claude-skills/" "$REPO_ROOT/.gitignore"
  [ "$status" -eq 0 ]
  run grep -n "request_user_input" "$PACKAGE/scripts/sync-codex-skills.mjs"
  [ "$status" -eq 0 ]
  run grep -n "native Codex subagent workflow" "$PACKAGE/scripts/sync-codex-skills.mjs"
  [ "$status" -eq 0 ]
  run grep -n "codex exec" "$PACKAGE/scripts/sync-codex-skills.mjs"
  [ "$status" -ne 0 ]
}

@test "risk-scorer Codex smoke runner uses published npm installer then codex exec" {
  local runner="$PACKAGE/eval/run-codex-smoke.sh"
  [ -x "$runner" ]
  run grep -n "WR_RISK_SCORER_NPM_SPEC" "$runner"
  [ "$status" -eq 0 ]
  run grep -n "npm exec --yes --package" "$runner"
  [ "$status" -eq 0 ]
  run grep -n "windyroad-risk-scorer --runtime codex" "$runner"
  [ "$status" -eq 0 ]
  run grep -n "codex exec" "$runner"
  [ "$status" -eq 0 ]
  run grep -n -- "--ephemeral" "$runner"
  [ "$status" -eq 0 ]
  run grep -n "assess-release" "$runner"
  [ "$status" -eq 0 ]
  run grep -n "assess-external-comms" "$runner"
  [ "$status" -eq 0 ]
}
