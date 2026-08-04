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
  run grep -n 'codex plugin marketplace add ${JSON.stringify(marketplaceRoot)}' "$PACKAGE/bin/install.mjs"
  [ "$status" -eq 0 ]
  run grep -n "codexInstall()" "$PACKAGE/bin/install.mjs"
  [ "$status" -eq 0 ]
  run grep -n "installRiskAgents" "$PACKAGE/bin/install.mjs"
  [ "$status" -eq 0 ]
  run grep -n "uninstallRiskAgents" "$PACKAGE/bin/install.mjs"
  [ "$status" -eq 0 ]
}

@test "risk-scorer installer can prefer the Codex desktop binary" {
  grep -q '/Applications/ChatGPT.app/Contents/Resources/codex' "$PACKAGE/bin/install.mjs"
  grep -q 'process.env.CODEX_BINARY' "$PACKAGE/bin/install.mjs"
}

@test "risk-scorer removes the plugin from its package marketplace" {
  grep -Fq 'codex plugin remove ${PLUGIN}@${CODEX_MARKETPLACE}' "$PACKAGE/bin/install.mjs"
}

@test "risk-scorer repairs native Codex agents from Claude sources" {
  local generator="$PACKAGE/scripts/codex-agents.mjs"
  [ -f "$generator" ]
  run grep -n 'wr-risk-scorer:${mode}' "$generator"
  [ "$status" -eq 0 ]
  run grep -n "codex-agents.mjs\" --session-start" "$PACKAGE/hooks/risk-scorer-dispatch.sh"
  [ "$status" -eq 0 ]
  run grep -n "Do not substitute" "$PACKAGE/scripts/sync-codex-skills.mjs"
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
  run grep -n 'Do not parse transcripts or launch nested.*codex exec' "$PACKAGE/scripts/sync-codex-skills.mjs"
  [ "$status" -eq 0 ]
}

@test "risk-scorer Codex smoke runner packs current code and proves exact agent marker flow" {
  local runner="$PACKAGE/eval/run-codex-smoke.sh"
  [ -x "$runner" ]
  run grep -n "WR_RISK_SCORER_NPM_SPEC" "$runner"
  [ "$status" -eq 0 ]
  run grep -n 'npm pack "$REPO_ROOT/packages/risk-scorer"' "$runner"
  [ "$status" -eq 0 ]
  run grep -n "npm exec --yes --package" "$runner"
  [ "$status" -eq 0 ]
  run grep -n "windyroad-risk-scorer --runtime codex" "$runner"
  [ "$status" -eq 0 ]
  run grep -n '"$CODEX_BIN" exec' "$runner"
  [ "$status" -eq 0 ]
  run grep -n -- "--ephemeral" "$runner"
  [ "$status" -ne 0 ]
  run grep -n "wr-risk-scorer:external-comms" "$runner"
  [ "$status" -eq 0 ]
  run grep -n "external-comms-risk-reviewed" "$runner"
  [ "$status" -eq 0 ]
}
