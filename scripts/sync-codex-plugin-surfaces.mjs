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
const reviewerCompletion = {
  "style-guide": { role: "wr-style-guide:agent", writer: "style-guide-mark-reviewed.sh", policy: "docs/STYLE-GUIDE.md" },
  "voice-tone": { role: "wr-voice-tone:agent", writer: "voice-tone-mark-reviewed.sh", policy: "docs/VOICE-AND-TONE.md" },
}[packageName];

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
  if (reviewerCompletion) {
    config.hooks.PostToolUse ||= [];
    config.hooks.PostToolUse.push({
      matcher: "collaborationspawn_agent|collaborationwait_agent|collaborationinterrupt_agent|spawn_agent|wait_agent|interrupt_agent|close_agent|multi_agent_v1__spawn_agent|multi_agent_v1__wait_agent|multi_agent_v1__close_agent",
      hooks: [{ type: "command", command: 'node "${PLUGIN_ROOT}/hooks-codex/codex-agent-completion.mjs"' }],
    });
    config.hooks.SubagentStop ||= [];
    config.hooks.SubagentStop.push({
      matcher: `^${reviewerCompletion.role}$`,
      hooks: [{ type: "command", command: 'node "${PLUGIN_ROOT}/hooks-codex/codex-agent-completion.mjs"' }],
    });
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
  if (reviewerCompletion) {
    writeFileSync(join(hooksOutput, "codex-agent-completion.mjs"), `#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, realpathSync, renameSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const hookDir = dirname(fileURLToPath(import.meta.url));
const role = ${JSON.stringify(reviewerCompletion.role)};
const writer = join(hookDir, "..", "hooks", ${JSON.stringify(reviewerCompletion.writer)});
const policy = ${JSON.stringify(reviewerCompletion.policy)};
const ttlSeconds = process.env.REVIEW_TTL ?? "3600";
const ttl = Number(ttlSeconds) * 1000;

function response(input) {
  if (typeof input.tool_response === "object" && input.tool_response) return input.tool_response;
  try { return JSON.parse(input.tool_response); } catch { return {}; }
}

function stateDir(sessionId) {
  return join(process.env.TMPDIR || "/tmp", \`claude-risk-\${sessionId}\`);
}

function statePath(input, target, suffix = "") {
  return join(stateDir(input.session_id), \`codex-review-\${Buffer.from(role + ":" + target).toString("base64url")}\${suffix}\`);
}

function normalizeTarget(target) {
  if (typeof target !== "string") return "";
  return target.startsWith("/root/") ? target.slice("/root/".length) : target;
}

function policyHash(root) {
  const result = spawnSync("bash", ["-c", 'source "$1"; _substance_hash_path "$2"', "review-policy",
    join(hookDir, "..", "hooks", "lib", "gate-helpers.sh"), policy], { cwd: root, encoding: "utf8" });
  const hash = result.stdout?.trim();
  return result.status === 0 && /^[a-f0-9]{64}$/.test(hash || "") ? hash : null;
}

function diagnostic(reason, input) {
  const dir = process.env.TMPDIR || "/tmp";
  const path = join(dir, "codex-review-completion-diagnostic.json");
  const temporary = join(dir, \`.codex-review-completion-diagnostic-\${process.pid}.tmp\`);
  try {
    mkdirSync(dir, { recursive: true });
    writeFileSync(temporary, JSON.stringify({
      timestamp: new Date().toISOString(),
      reason,
      event: input?.hook_event_name === "SubagentStop" ? "SubagentStop" : input?.tool_name || "unknown",
      role,
    }), { mode: 0o600 });
    renameSync(temporary, path);
  } catch {
    rmSync(temporary, { force: true });
  }
}

function checkout(cwd) {
  if (typeof cwd !== "string" || !cwd) return null;
  let root;
  try { root = realpathSync(cwd); } catch { return null; }
  const git = spawnSync("git", ["-C", root, "rev-parse", "--show-toplevel"], { encoding: "utf8" });
  if (git.status !== 0) return null;
  let gitRoot;
  try { gitRoot = realpathSync(git.stdout.trim()); } catch { return null; }
  if (gitRoot !== root) return null;
  const stat = statSync(root);
  return { root, physical: \`\${stat.dev}:\${stat.ino}\` };
}

function targetFromSpawn(input) {
  const result = response(input);
  return result.agent_id ?? result.task_name;
}

function clear(input, target) {
  for (const suffix of ["", ".claim", ".done"]) rmSync(statePath(input, target, suffix), { force: true });
}

function remember(input) {
  const target = normalizeTarget(targetFromSpawn(input));
  if (!target) return;
  mkdirSync(stateDir(input.session_id), { recursive: true });
  clear(input, target);
  if (input.tool_input?.agent_type !== role) return;
  const bound = checkout(input.cwd || process.cwd());
  if (!bound) {
    diagnostic("invalid-spawn-checkout", input);
    return;
  }
  const hash = policyHash(bound.root);
  if (!hash) {
    diagnostic("policy-hash-failed", input);
    return;
  }
  writeFileSync(statePath(input, target), JSON.stringify({ role, target, ...bound, policyHash: hash }), { mode: 0o600 });
}

function claim(input, target) {
  const path = statePath(input, target, ".claim");
  const done = statePath(input, target, ".done");
  if (existsSync(done)) return null;
  try { writeFileSync(path, "", { flag: "wx", mode: 0o600 }); }
  catch (error) {
    if (error?.code === "EEXIST") return null;
    throw error;
  }
  return { path, done };
}

function complete(input, target, output) {
  target = normalizeTarget(target);
  if (!target || typeof output !== "string" || !output) return;
  const path = statePath(input, target);
  if (existsSync(statePath(input, target, ".done"))) return;
  if (!existsSync(path)) {
    diagnostic("missing-parent-registration", input);
    return;
  }

  let registered, age;
  try {
    registered = JSON.parse(readFileSync(path, "utf8"));
    age = Date.now() - Math.floor(statSync(path).mtimeMs);
  }
  catch {
    diagnostic("malformed-registration", input);
    return;
  }
  if (registered.role !== role || registered.target !== target) {
    diagnostic("registration-mismatch", input);
    return;
  }
  if (!Number.isFinite(age) || age < 0) {
    diagnostic("invalid-registration-age", input);
    return;
  }
  if (age >= ttl) {
    diagnostic("stale-registration", input);
    return;
  }

  const current = checkout(input.cwd || process.cwd());
  if (!current || current.root !== registered.root || current.physical !== registered.physical) {
    diagnostic("checkout-mismatch", input);
    return;
  }

  const hash = policyHash(registered.root);
  if (!hash || hash !== registered.policyHash) {
    diagnostic(hash ? "policy-changed" : "policy-hash-failed", input);
    return;
  }

  const claimed = claim(input, target);
  if (!claimed) return;
  const synthetic = {
    ...input,
    cwd: registered.root,
    tool_name: "Agent",
    tool_input: { subagent_type: role, prompt: "" },
    tool_response: { content: [{ type: "text", text: output }] },
  };
  const result = spawnSync(writer, {
    cwd: registered.root,
    env: process.env,
    input: JSON.stringify(synthetic),
    encoding: "utf8",
  });
  if (result.status === 0) {
    renameSync(claimed.path, claimed.done);
    rmSync(path, { force: true });
    return;
  }
  rmSync(claimed.path, { force: true });
  diagnostic("marker-writer-failed", input);
  process.exitCode = 1;
}

function close(input) {
  complete(input, input.tool_input?.target, response(input).previous_status?.completed);
}

function wait(input) {
  const statuses = response(input).status;
  if (!statuses || typeof statuses !== "object") return;
  for (const [target, status] of Object.entries(statuses)) complete(input, target, status?.completed);
}

let body = "";
process.stdin.setEncoding("utf8");
for await (const chunk of process.stdin) body += chunk;
let input;
try { input = JSON.parse(body); } catch { process.exit(0); }
if (!/^[A-Za-z0-9-]+$/.test(input.session_id || "")) process.exit(0);
if (!/^[0-9]+$/.test(ttlSeconds) || !Number.isSafeInteger(ttl) || ttl <= 0) {
  diagnostic("invalid-review-ttl", input);
  process.exit(0);
}

if (["collaborationspawn_agent", "spawn_agent", "multi_agent_v1__spawn_agent"].includes(input.tool_name)) remember(input);
if (["collaborationinterrupt_agent", "interrupt_agent", "close_agent", "multi_agent_v1__close_agent"].includes(input.tool_name)) close(input);
if (["collaborationwait_agent", "wait_agent", "multi_agent_v1__wait_agent"].includes(input.tool_name)) wait(input);
if (input.hook_event_name === "SubagentStop") {
  if (input.agent_type !== role) diagnostic("unrelated-subagent-stop", input);
  else complete(input, input.agent_id, input.last_assistant_message);
}
`);
  }
}

if (process.argv.includes("--pack")) {
  rmSync(join(root, "skills"), { recursive: true, force: true });
  cpSync(skillsOutput, join(root, "skills"), { recursive: true });
  const projectedHooks = join(hooksOutput, "hooks.json");
  if (existsSync(projectedHooks)) cpSync(projectedHooks, join(root, "hooks", "hooks.json"));
}

console.error(`Generated Codex surfaces for @windyroad/${packageName}.`);
