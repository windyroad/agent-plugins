#!/usr/bin/env bats

setup() {
  PACKAGE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  REPO_ROOT="$(cd "$PACKAGE/../.." && pwd)"
  PACKAGE_VERSION="$(node -p "require('$PACKAGE/package.json').version")"
  TMP="$(mktemp -d)"
  export CODEX_HOME="$TMP/codex-home"
}

teardown() {
  node "$PACKAGE/scripts/sync-codex-skills.mjs" --restore-pack >/dev/null 2>&1 || true
  rm -rf "$TMP"
}

assert_skill_frontmatter() {
  node --input-type=module - "$1" <<'NODE'
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { parse } from "yaml";

for (const skill of readdirSync(process.argv[2])) {
  const text = readFileSync(join(process.argv[2], skill, "SKILL.md"), "utf8");
  const end = text.indexOf("\n---\n", 4);
  if (!text.startsWith("---\n") || end === -1) throw new Error(`${skill}: missing YAML frontmatter`);
  parse(text.slice(4, end));
}
NODE
}

@test "default installer remains Claude-only" {
  run node "$PACKAGE/bin/install.mjs" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude plugin marketplace add"* ]]
  [[ "$output" != *"codex plugin marketplace add"* ]]
}

@test "generated Codex projection exposes the complete plugin" {
  run node "$PACKAGE/scripts/sync-codex-skills.mjs" --build
  [ "$status" -eq 0 ]
  source_count="$(find "$PACKAGE/skills" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/SKILL.md' ';' -print | wc -l | tr -d ' ')"
  [ "$(find "$PACKAGE/skills-codex" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" -eq "$source_count" ]
  [ -f "$PACKAGE/skills-codex/capture-problem/agents/openai.yaml" ]
  [ -f "$PACKAGE/skills-codex/capture-problem/REFERENCE.md" ]
  [ -f "$PACKAGE/skills-codex/scaffold-intake/templates/config.yml.tmpl" ]
  grep -Fq 'use `request_user_input`' "$PACKAGE/skills-codex/capture-problem/SKILL.md"
  grep -Fq '<itil-plugin-root>/bin/wr-itil-reconcile-readme' "$PACKAGE/skills-codex/reconcile-readme/SKILL.md"
  ! grep -Fq 'wr-risk-scorer-restage-commit' "$PACKAGE/skills-codex/capture-problem/SKILL.md"
  ! rg -q 'claude -p|claude --version|AskUserQuestion|\.claude/' "$PACKAGE/skills-codex"
  grep -Fq 'add-band' "$PACKAGE/skills-codex/capture-rfc/SKILL.md"
  grep -Fq 'Never create a new file under `docs/rfcs/`' "$PACKAGE/skills-codex/capture-rfc/SKILL.md"
  ! grep -Fq 'mark-rfc-capture-gate' "$PACKAGE/skills-codex/capture-rfc/SKILL.md"
  [ "$(find "$PACKAGE/skills-codex" -path '*/agents/openai.yaml' | wc -l | tr -d ' ')" -eq "$source_count" ]
  [ "$(jq '[.hooks[] | length] | add' "$PACKAGE/hooks-codex/hooks.json")" -eq 5 ]

  assert_skill_frontmatter "$PACKAGE/skills-codex"

  checkout="$TMP/test/checkout"
  mkdir -p "$checkout/packages"
  cp -R "$PACKAGE" "$checkout/packages/itil"
  cp -R "$REPO_ROOT/docs" "$checkout/docs"
  run node "$checkout/packages/itil/scripts/sync-codex-skills.mjs" --build
  [ "$status" -eq 0 ]
  [ -f "$checkout/packages/itil/skills-codex/work-problem/SKILL.md" ]
}

@test "generated Codex work-problems uses the persisted Goal tool surface" {
  run node "$PACKAGE/scripts/sync-codex-skills.mjs" --build
  [ "$status" -eq 0 ]
  skill="$PACKAGE/skills-codex/work-problems/SKILL.md"

  grep -Fq '`thread/goal/set`' "$skill"
  grep -Fq '`thread/goal/get`' "$skill"
  grep -Fq '`thread/goal/clear`' "$skill"
  grep -Fq 'The /wr-itil:work-problems AFK backlog drain is complete:' "$skill"
  ! grep -Fq 'If the task has a persistent Codex goal' "$skill"
  ! grep -Fq 'code.claude.com/docs/en/goal' "$skill"
  ! grep -Fq '`/goal`' "$skill"
}

@test "Codex agent registration is exact, scoped, repairable, and ownership-safe" {
  run node "$PACKAGE/scripts/codex-agent.mjs" --scope user
  [ "$status" -eq 0 ]
  target="$CODEX_HOME/agents/wr-itil-hang-off-check.toml"
  grep -Fq 'name = "wr-itil:hang-off-check"' "$target"

  run node "$PACKAGE/scripts/codex-agent.mjs" --scope user
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  project="$TMP/project-scope"
  mkdir -p "$project"
  run bash -c 'cd "$1" && node "$2" --scope project' _ "$project" "$PACKAGE/scripts/codex-agent.mjs"
  [ "$status" -eq 0 ]
  [ -f "$project/.codex/agents/wr-itil-hang-off-check.toml" ]

  printf '# local edit\n' >> "$target"
  modified="$(cat "$target")"
  node "$PACKAGE/scripts/codex-agent.mjs" --scope user >/dev/null
  [ "$(cat "$target")" = "$modified" ]
  node "$PACKAGE/scripts/codex-agent.mjs" --scope user --uninstall
  [ -e "$target" ]

  rm "$target"
  node "$PACKAGE/scripts/codex-agent.mjs" --scope user >/dev/null
  node --input-type=module - "$target" <<'NODE'
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
const target = process.argv[2];
const lines = readFileSync(target, "utf8").split("\n");
const payload = lines.slice(2).join("\n").replace('name = "wr-itil:hang-off-check"', 'name = "wr-itil:stale"');
const hash = createHash("sha256").update(payload).digest("hex");
writeFileSync(target, `${lines[0]}\n# Generated content SHA-256: ${hash}\n${payload}`);
NODE
  node "$PACKAGE/scripts/codex-agent.mjs" --scope user >/dev/null
  grep -Fq 'name = "wr-itil:hang-off-check"' "$target"

  printf '# user managed\n' > "$target"
  node "$PACKAGE/scripts/codex-agent.mjs" --scope user >/dev/null
  [ "$(cat "$target")" = "# user managed" ]
  node "$PACKAGE/scripts/codex-agent.mjs" --scope user --uninstall
  [ -e "$target" ]

  rm "$target"
  node "$PACKAGE/scripts/codex-agent.mjs" --scope user >/dev/null
  node "$PACKAGE/scripts/codex-agent.mjs" --scope user --uninstall
  [ ! -e "$target" ]
}

@test "Codex hook projection repairs the agent and dispatches lifecycle checks" {
  node "$PACKAGE/scripts/sync-codex-skills.mjs" --build >/dev/null
  input='{"session_id":"codex-itil-test","prompt":"FFS, that is wrong"}'

  run env CODEX_THREAD_ID=test bash "$PACKAGE/hooks/itil-codex-dispatch.sh" session-start <<<"$input"
  [ "$status" -eq 0 ]
  [ -f "$CODEX_HOME/agents/wr-itil-hang-off-check.toml" ]

  run bash "$PACKAGE/hooks/itil-codex-dispatch.sh" user-prompt <<<"$input"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MANDATORY"* ]]
  [[ "$output" == *"capture-problem"* ]]

  run bash "$PACKAGE/hooks/itil-codex-dispatch.sh" user-prompt <<<'{"session_id":"codex-itil-test","prompt":"$wr-itil:work-problems"}'
  [ "$status" -eq 0 ]
  run bash "$PACKAGE/hooks/itil-codex-dispatch.sh" pre-tool <<<'{"session_id":"codex-itil-test","tool_name":"request_user_input","tool_input":{}}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"MID-LOOP ASK DETECTED"* ]]

  project="$TMP/project"
  mkdir -p "$project/.codex/plans"
  pre_payload="$(jq -n --arg path "$project/.codex/plans/generated.md" '{tool_name:"Write",tool_input:{file_path:$path}}')"
  run bash -c 'cd "$1" && printf "%s" "$2" | "$3" pre-tool' _ "$project" "$pre_payload" "$PACKAGE/hooks/itil-codex-dispatch.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision": "deny"'* ]]
  [[ "$output" == *"AGENTS.md"* ]]

  allowed_payload="$(jq -n --arg path "$project/.codex/agents/wr-itil.toml" '{tool_name:"Write",tool_input:{file_path:$path}}')"
  run bash -c 'cd "$1" && printf "%s" "$2" | "$3" pre-tool' _ "$project" "$allowed_payload" "$PACKAGE/hooks/itil-codex-dispatch.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  post_payload='{"tool_name":"Edit","tool_input":{"file_path":"packages/foo/skills/bar/SKILL.md","old_string":"x","new_string":"Full scope deferred to /wr-itil:manage-rfc accepted transition."},"tool_response":{"success":true}}'
  run bash "$PACKAGE/hooks/itil-codex-dispatch.sh" post-tool <<<"$post_payload"
  [ "$status" -eq 0 ]
  [[ "$output" == *"P375 ADVISORY"* ]]

  fix_project="$TMP/fix-project"
  mkdir -p "$fix_project/docs/problems/open"
  git -C "$fix_project" init -q
  git -C "$fix_project" config user.email test@example.com
  git -C "$fix_project" config user.name Test
  printf '# Problem\n' > "$fix_project/docs/problems/open/345-test.md"
  git -C "$fix_project" add .
  git -C "$fix_project" commit -qm 'docs: add problem'
  printf 'fix\n' > "$fix_project/fix.txt"
  git -C "$fix_project" add .
  git -C "$fix_project" commit -qm 'fix: repair P345'
  run bash -c 'cd "$1" && printf "%s" "$2" | "$3" post-tool' _ "$fix_project" '{"tool_name":"Bash","tool_input":{"command":"git commit"}}' "$PACKAGE/hooks/itil-codex-dispatch.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"P345 ADVISORY"* ]]

  run bash "$PACKAGE/hooks/itil-codex-dispatch.sh" post-tool <<<'{"tool_name":"Edit","tool_input":{"file_path":"README.md","old_string":"x","new_string":"done"}}'
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  run bash "$PACKAGE/hooks/itil-codex-dispatch.sh" stop <<<'{"last_assistant_message":"Would you like me to continue?"}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"request_user_input"* ]]

  run bash "$PACKAGE/hooks/itil-codex-dispatch.sh" stop <<<'{"last_assistant_message":"The requested work is complete."}'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  rm -f /tmp/itil-correction-detect-announced-codex-itil-test
}

@test "packed artefact preserves Claude and installs the complete Codex plugin" {
  before="$(git hash-object "$PACKAGE/skills/capture-problem/SKILL.md")"
  run npm pack "$PACKAGE" --pack-destination "$TMP"
  [ "$status" -eq 0 ]
  [ "$before" = "$(git hash-object "$PACKAGE/skills/capture-problem/SKILL.md")" ]
  tarball="$(find "$TMP" -maxdepth 1 -name '*.tgz' -print -quit)"
  tar -xzf "$tarball" -C "$TMP"

  while IFS= read -r shell_file; do
    bash -n "$shell_file"
  done < <(find "$TMP/package" -type f \( -name '*.sh' -o -path '*/bin/wr-*' \) -print)

  [ -f "$TMP/package/skills/manage-problem/SKILL.md" ]
  [ -f "$TMP/package/skills-codex/capture-problem/SKILL.md" ]
  [ -f "$TMP/package/skills-codex/manage-problem/SKILL.md" ]
  [ -f "$TMP/package/skills-codex/work-problems/SKILL.md" ]
  assert_skill_frontmatter "$TMP/package/skills"
  assert_skill_frontmatter "$TMP/package/skills-codex"
  grep -Fq 'add-band' "$TMP/package/skills/capture-rfc/SKILL.md"
  grep -Fq 'add-band' "$TMP/package/skills-codex/capture-rfc/SKILL.md"
  ! grep -Fq 'docs/rfcs/RFC-' "$TMP/package/skills/capture-rfc/SKILL.md"
  [ "$(jq -r '.hooks // empty' "$TMP/package/.codex-plugin/plugin.json")" = "" ]
  ! rg -q '\b(ADR-[0-9]{3,}|P-?[0-9]{3}|RFC-[0-9]{3,}|JTBD-[0-9]{3,}|STORY(-MAP)?-[0-9]{3,}|R-?[0-9]{3})\b' "$TMP/package"

  run env CODEX_BINARY="$(command -v codex)" npm exec --yes --package "$tarball" -- windyroad-itil --runtime codex --scope user
  [ "$status" -eq 0 ]
  staged="$CODEX_HOME/.tmp/marketplaces/wr-itil-$PACKAGE_VERSION"
  [ "$(jq -r .version "$staged/.codex-plugin/plugin.json")" = "$PACKAGE_VERSION" ]
  [ "$(jq '[.hooks[] | length] | add' "$staged/hooks/hooks.json")" -eq 5 ]
  [ "$(jq '[.hooks[] | length] | add' "$staged/hooks-codex/hooks.json")" -eq 5 ]
  project="$TMP/staged-project"
  mkdir -p "$project/.codex/plans"
  pre_payload="$(jq -n --arg path "$project/.codex/plans/generated.md" '{tool_name:"Write",tool_input:{file_path:$path}}')"
  run bash -c 'cd "$1" && printf "%s" "$2" | "$3" pre-tool' _ "$project" "$pre_payload" "$staged/hooks/itil-codex-dispatch.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision": "deny"'* ]]
  [[ "$output" != *'syntax error'* ]]
  run codex plugin list
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-itil@windyroad-itil-local"* ]]
  plugin_line="$(printf '%s\n' "$output" | grep '^wr-itil@windyroad-itil-local')"
  [[ "$plugin_line" == *" $PACKAGE_VERSION "* ]]
  [ -f "$CODEX_HOME/agents/wr-itil-hang-off-check.toml" ]
}
