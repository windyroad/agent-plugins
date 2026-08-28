#!/usr/bin/env node

import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const packageName = process.argv[2];
const root = join(repoRoot, "packages", packageName || "");
const skillsOutput = join(root, "skills-codex");
const hooksOutput = join(root, "hooks-codex");
const backup = join(root, ".pack-codex-source");
const supported = new Set(["c4", "connect", "jtbd", "retrospective", "style-guide", "tdd", "voice-tone"]);

if (!supported.has(packageName)) {
  console.error("Usage: sync-codex-plugin-surfaces.mjs <package> --build | --clean");
  process.exit(2);
}

function clean() {
  rmSync(skillsOutput, { recursive: true, force: true });
  rmSync(hooksOutput, { recursive: true, force: true });
}

function restore() {
  if (!existsSync(backup)) return;
  rmSync(join(root, "skills"), { recursive: true, force: true });
  cpSync(join(backup, "skills"), join(root, "skills"), { recursive: true });
  const hooks = join(backup, "hooks.json");
  if (existsSync(hooks)) cpSync(hooks, join(root, "hooks", "hooks.json"));
  rmSync(backup, { recursive: true, force: true });
}

function walk(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });
}

function runtimeTerms(text) {
  return text
    .replaceAll("AskUserQuestion", "request_user_input")
    .replaceAll("Agent tool", "native Codex subagent tool")
    .replaceAll("`Agent` tool", "native Codex subagent tool")
    .replaceAll("Agent-tool", "native-Codex-subagent-tool")
    .replaceAll("Task tool", "native Codex subagent tool")
    .replaceAll("Skill tool", "installed skill invocation")
    .replaceAll("`Skill` tool", "installed skill invocation")
    .replaceAll("Skill-tool", "installed-skill-invocation")
    .replace(/claude -p(?:\s+--[^\s]+(?:\s+[^\s]+)?)*?/g, "native Codex subagent")
    .replaceAll("Claude Code", "Codex")
    .replace(/\bClaude\b/g, "Codex")
    .replaceAll("CLAUDE_SESSION_ID", "CODEX_THREAD_ID")
    .replaceAll("subagent_type:", "agent_type:")
    .replaceAll("run_in_background: false", "wait_for_completion: true")
    .replaceAll("Agent(run_in_background: true)", "background native Codex subagent")
    .replaceAll(".claude", ".codex");
}

function transformSkill(text) {
  const note = `<!-- Generated from the runtime-neutral skill source. Do not edit. -->

> Codex runtime note: invoke installed skills directly, use
> \`request_user_input\` only when the contract requires a human decision, and
> use native Codex subagents for agent delegation. Resolve bundled files from
> this installed plugin instead of the adopter repository.

`;
  const result = runtimeTerms(text);
  if (!result.startsWith("---\n")) return note + result;
  const end = result.indexOf("\n---\n", 4);
  return end === -1 ? note + result : result.slice(0, end + 5) + "\n" + note + result.slice(end + 5);
}

if (process.argv.includes("--clean")) {
  clean();
  process.exit(0);
}
if (process.argv.includes("--restore-pack")) {
  restore();
  clean();
  process.exit(0);
}
if (!process.argv.includes("--build") && !process.argv.includes("--pack")) {
  console.error("Usage: sync-codex-plugin-surfaces.mjs <package> --build | --pack | --restore-pack | --clean");
  process.exit(2);
}

if (process.argv.includes("--pack")) {
  if (existsSync(backup)) throw new Error(`Refusing to pack @windyroad/${packageName}: backup already exists`);
  mkdirSync(backup, { recursive: true });
  cpSync(join(root, "skills"), join(backup, "skills"), { recursive: true });
  const hooks = join(root, "hooks", "hooks.json");
  if (existsSync(hooks)) cpSync(hooks, join(backup, "hooks.json"));
}

clean();
for (const entry of readdirSync(join(root, "skills"), { withFileTypes: true })) {
  if (!entry.isDirectory() || !existsSync(join(root, "skills", entry.name, "SKILL.md"))) continue;
  const source = join(root, "skills", entry.name);
  const target = join(skillsOutput, entry.name);
  cpSync(source, target, {
    recursive: true,
    filter: (path) => !path.split("/").some((part) => ["test", "eval", "evals"].includes(part)),
  });
  const skill = join(target, "SKILL.md");
  writeFileSync(skill, transformSkill(readFileSync(skill, "utf8")), "utf8");
  for (const supporting of walk(target).filter((path) => path !== skill)) {
    writeFileSync(supporting, runtimeTerms(readFileSync(supporting, "utf8")), "utf8");
  }
}

const hooks = join(root, "hooks", "hooks.json");
if (existsSync(hooks)) {
  mkdirSync(hooksOutput, { recursive: true });
  const config = JSON.parse(readFileSync(hooks, "utf8"));
  for (const [event, groups] of Object.entries(config.hooks || {})) {
    for (const group of groups) {
      if (group.matcher) group.matcher = group.matcher.replaceAll("AskUserQuestion", "request_user_input");
      if ((event === "PreToolUse" || event === "PostToolUse") && /Edit|Write|Agent/.test(group.matcher || "")) {
        for (const hook of group.hooks || []) {
          const command = hook.command.replaceAll("${CLAUDE_PLUGIN_ROOT}", "${PLUGIN_ROOT}");
          hook.command = `bash "\${PLUGIN_ROOT}/hooks-codex/codex-adapter.sh" ${JSON.stringify(command)}`;
        }
      }
    }
  }
  writeFileSync(join(hooksOutput, "hooks.json"), `${JSON.stringify(config, null, 2)}\n`);
  writeFileSync(join(hooksOutput, "codex-adapter.sh"), `#!/usr/bin/env bash
set -uo pipefail

target="$1"
input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty')"

run_hook() {
  printf '%s' "$1" | "$target"
}

if [ "$tool" = "apply_patch" ]; then
  paths="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' | sed -nE 's/^\\*\\*\\* (Add|Update|Delete) File: (.*)$/\\2/p')"
  if [ -n "$paths" ]; then
    while IFS= read -r path; do
      payload="$(printf '%s' "$input" | jq --arg path "$path" '.tool_name = "Edit" | .tool_input.file_path = $path')"
      run_hook "$payload" || exit $?
    done <<< "$paths"
    exit 0
  fi
fi

if [ "$tool" = "spawn_agent" ] || [ "$tool" = "Agent" ]; then
  input="$(printf '%s' "$input" | jq '.tool_name = "Agent" | .tool_input.subagent_type = (.tool_input.agent_type // .tool_input.subagent_type // "") | .tool_input.prompt = (.tool_input.message // .tool_input.prompt // "")')"
fi

run_hook "$input"
`);
}

if (process.argv.includes("--pack")) {
  rmSync(join(root, "skills"), { recursive: true, force: true });
  cpSync(skillsOutput, join(root, "skills"), { recursive: true });
  const projectedHooks = join(hooksOutput, "hooks.json");
  if (existsSync(projectedHooks)) cpSync(projectedHooks, join(root, "hooks", "hooks.json"));
}

console.error(`Generated Codex surfaces for @windyroad/${packageName}.`);
