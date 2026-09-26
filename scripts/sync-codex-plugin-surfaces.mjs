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
const reviewerCompletions = {
  jtbd: [
    { role: "wr-jtbd:agent", writer: "jtbd-mark-reviewed.sh", policy: "docs/jtbd", passPattern: "^[ \\t]*>?[ \\t]*\\*\\*JTBD Review: PASS\\*\\*[ \\t]*$", firstLineOnly: true, verdictFile: "/tmp/jtbd-verdict" },
  ],
  "style-guide": [
    { role: "wr-style-guide:agent", writer: "style-guide-mark-reviewed.sh", policy: "docs/STYLE-GUIDE.md", passPattern: "^[ \\t]*>?[ \\t]*\\*\\*Style Guide Review: PASS\\*\\*.*$" },
  ],
  "voice-tone": [
    { role: "wr-voice-tone:agent", writer: "voice-tone-mark-reviewed.sh", policy: "docs/VOICE-AND-TONE.md", passPattern: "^[ \\t]*>?[ \\t]*\\*\\*Voice & Tone Review: PASS\\*\\*.*$" },
    { role: "wr-voice-tone:external-comms", writer: "external-comms-mark-reviewed.sh", policy: "docs/VOICE-AND-TONE.md", passPattern: "^EXTERNAL_COMMS_VOICE_TONE_VERDICT:[ \\t]*PASS$" },
  ],
}[packageName] ?? [];

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
      for (const hook of group.hooks || []) {
        if (hook.command) hook.command = hook.command.replaceAll("${CLAUDE_PLUGIN_ROOT}", "${PLUGIN_ROOT}");
        if (packageName === "voice-tone" && event === "UserPromptSubmit") hook.additionalContextLimit = 0;
      }
      if ((event === "PreToolUse" || event === "PostToolUse") && /Edit|Write|Agent/.test(group.matcher || "")) {
        for (const hook of group.hooks || []) {
          const command = hook.command;
          hook.command = `bash "\${PLUGIN_ROOT}/hooks-codex/codex-adapter.sh" ${JSON.stringify(command)}`;
        }
      }
    }
  }
  if (reviewerCompletions.length > 0) {
    config.hooks.UserPromptSubmit ||= [];
    config.hooks.PreToolUse ||= [];
    config.hooks.PostToolUse ||= [];
    config.hooks.SubagentStop ||= [];
    const completionCommands = reviewerCompletions.map((_completion, index) => {
      const filename = index === 0 ? "codex-agent-completion.mjs" : `codex-agent-completion-${index + 1}.mjs`;
      return { type: "command", command: `node "\${PLUGIN_ROOT}/hooks-codex/${filename}"` };
    });
    config.hooks.PostToolUse.push({
      matcher: "collaboration.spawn_agent|collaboration.wait_agent|collaboration.interrupt_agent|collaborationspawn_agent|collaborationwait_agent|collaborationinterrupt_agent|spawn_agent|wait_agent|interrupt_agent|close_agent|multi_agent_v1__spawn_agent|multi_agent_v1__wait_agent|multi_agent_v1__close_agent",
      hooks: completionCommands,
    });
    config.hooks.UserPromptSubmit.push({ hooks: completionCommands });
    config.hooks.PreToolUse.unshift({
      matcher: "Bash|Edit|Write|ExitPlanMode",
      hooks: completionCommands,
    });
    for (const [index, completion] of reviewerCompletions.entries()) {
      const filename = index === 0 ? "codex-agent-completion.mjs" : `codex-agent-completion-${index + 1}.mjs`;
      const command = `node "\${PLUGIN_ROOT}/hooks-codex/${filename}"`;
      config.hooks.SubagentStop.push({
        matcher: `^${completion.role}$`,
        hooks: [{ type: "command", command }],
      });
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
  for (const [index, completion] of reviewerCompletions.entries()) {
    const filename = index === 0 ? "codex-agent-completion.mjs" : `codex-agent-completion-${index + 1}.mjs`;
    writeFileSync(join(hooksOutput, filename), `#!/usr/bin/env node

import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, readdirSync, realpathSync, renameSync, rmSync, statSync, utimesSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { CLOSE_TOOLS, SPAWN_TOOLS, WAIT_TOOLS, response } from "../hooks/lib/codex-completion-input.mjs";

const hookDir = dirname(fileURLToPath(import.meta.url));
const role = ${JSON.stringify(completion.role)};
const writer = join(hookDir, "..", "hooks", ${JSON.stringify(completion.writer)});
const policy = ${JSON.stringify(completion.policy)};
const passPattern = new RegExp(${JSON.stringify(completion.passPattern)}, "m");
const firstLineOnly = ${JSON.stringify(Boolean(completion.firstLineOnly))};
const verdictFile = ${JSON.stringify(completion.verdictFile ?? null)};
const ttlSeconds = process.env.REVIEW_TTL ?? "3600";
const ttl = Number(ttlSeconds) * 1000;

function stateDir(sessionId) {
  return join(process.env.TMPDIR || "/tmp", \`claude-risk-\${sessionId}\`);
}

function transportDir() {
  return join(process.env.TMPDIR || "/tmp", "codex-review-transport");
}

function statePath(input, target, suffix = "") {
  return join(stateDir(input.session_id), \`codex-review-\${Buffer.from(role + ":" + target).toString("base64url")}\${suffix}\`);
}

function transportId(sessionId, target) {
  return createHash("sha256").update(sessionId + "\\0" + role + "\\0" + target).digest("hex");
}

function registrationPath(sessionId, target) {
  return join(transportDir(), \`registration-\${transportId(sessionId, target)}.json\`);
}

function receiptPath(sessionId, target, suffix = "") {
  return join(transportDir(), \`receipt-\${transportId(sessionId, target)}.json\${suffix}\`);
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

function expectedExternalKey(prompt) {
  if (role !== "wr-voice-tone:external-comms" || typeof prompt !== "string" || !prompt) return null;
  const result = spawnSync("bash", ["-c", 'source "$1"; value="$(cat)"; derive_external_comms_key_from_prompt "$value"',
    "external-key", join(hookDir, "..", "hooks", "lib", "external-comms-key.sh")], { input: prompt, encoding: "utf8" });
  const key = result.stdout?.trim();
  return result.status === 0 && /^[a-f0-9]{64}$/.test(key || "") ? key : null;
}

function outputAllowed(output, registered) {
  const candidate = firstLineOnly ? output.split(/\\r?\\n/).find((line) => line.trim()) || "" : output;
  if (!passPattern.test(candidate)) return false;
  if (verdictFile) {
    try { if (readFileSync(verdictFile, "utf8").trim() !== "PASS") return false; }
    catch { return false; }
  }
  if (role !== "wr-voice-tone:external-comms") return true;
  const keys = [...output.matchAll(/^EXTERNAL_COMMS_VOICE_TONE_KEY:[ \\t]*([a-f0-9]{64})$/gm)];
  if (keys.length !== 1) return false;
  return Boolean(registered.expectedKey && registered.expectedKey === keys[0][1]);
}

function reapTransport() {
  if (!existsSync(transportDir())) return;
  for (const name of readdirSync(transportDir())) {
    const path = join(transportDir(), name);
    try {
      const statAge = Date.now() - statSync(path).mtimeMs;
      if (/^(?:receipt|risk-receipt)-[a-f0-9]{64}\\.json\\.(?:claim|done)$/.test(name)) {
        if (!Number.isFinite(statAge) || statAge < 0 || statAge >= ttl) rmSync(path, { force: true });
        continue;
      }
      if (!/^(?:registration|receipt)-[a-f0-9]{64}\\.json$/.test(name)) continue;
      const value = JSON.parse(readFileSync(path, "utf8"));
      if (value.role !== role) continue;
      const timestamp = name.startsWith("receipt-") ? value.completedAt : value.createdAt;
      const age = Date.now() - timestamp;
      if (!Number.isFinite(age) || age < 0 || age >= ttl) rmSync(path, { force: true });
    } catch { /* Another completion may own or remove this transport file. */ }
  }
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
  rmSync(registrationPath(input.session_id, target), { force: true });
  for (const suffix of ["", ".claim", ".done"]) rmSync(receiptPath(input.session_id, target, suffix), { force: true });
}

function remember(input) {
  reapTransport();
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
  const prompt = input.tool_input?.message ?? input.tool_input?.prompt ?? "";
  const externalKey = expectedExternalKey(prompt);
  const registered = { parentSession: input.session_id, role, target, ...bound, policyHash: hash,
    promptDigest: createHash("sha256").update(prompt).digest("hex"), expectedKey: externalKey, createdAt: Date.now() };
  writeFileSync(statePath(input, target), JSON.stringify(registered), { mode: 0o600 });
  if (role === "wr-voice-tone:external-comms" && !externalKey) {
    diagnostic("missing-external-comms-key-binding", input);
    return;
  }
  mkdirSync(transportDir(), { recursive: true, mode: 0o700 });
  writeFileSync(registrationPath(input.session_id, target), JSON.stringify(registered), { mode: 0o600 });
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

function validRegistration(registered, input, target, age) {
  if (registered.role !== role || registered.target !== target) {
    diagnostic("registration-mismatch", input);
    return false;
  }
  if (!Number.isFinite(age) || age < 0) {
    diagnostic("invalid-registration-age", input);
    return false;
  }
  if (age >= ttl) {
    diagnostic("stale-registration", input);
    return false;
  }
  const current = checkout(input.cwd || process.cwd());
  if (!current || current.root !== registered.root || current.physical !== registered.physical) {
    diagnostic("checkout-mismatch", input);
    return false;
  }
  const hash = policyHash(registered.root);
  if (!hash || hash !== registered.policyHash) {
    diagnostic(hash ? "policy-changed" : "policy-hash-failed", input);
    return false;
  }
  return true;
}

function writeMarker(input, registered, target, output, completedAt, claimed) {
  const synthetic = {
    ...input,
    session_id: registered.parentSession,
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
  if (result.status !== 0) {
    rmSync(claimed.path, { force: true });
    diagnostic("marker-writer-failed", input);
    return false;
  }
  renameSync(claimed.path, claimed.done);
  rmSync(statePath({ session_id: registered.parentSession }, target), { force: true });
  rmSync(registrationPath(registered.parentSession, target), { force: true });
  const assessedAt = new Date(completedAt);
  for (const candidate of [
    join(process.env.TMPDIR || "/tmp", \`${packageName}-reviewed-\${registered.parentSession}\`),
    join(process.env.TMPDIR || "/tmp", \`${packageName}-plan-reviewed-\${registered.parentSession}\`),
  ]) {
    if (existsSync(candidate)) utimesSync(candidate, assessedAt, assessedAt);
    if (existsSync(candidate + ".hash")) utimesSync(candidate + ".hash", assessedAt, assessedAt);
  }
  if (role === "wr-voice-tone:external-comms") {
    const keys = [...output.matchAll(/^EXTERNAL_COMMS_VOICE_TONE_KEY:[ \\t]*([a-f0-9]{64})$/gm)];
    if (keys.length === 1) {
      const keyed = join(stateDir(registered.parentSession), \`external-comms-voice-tone-reviewed-\${keys[0][1]}\`);
      if (existsSync(keyed)) utimesSync(keyed, assessedAt, assessedAt);
    }
  }
  return true;
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
  if (!validRegistration(registered, input, target, age)) {
    rmSync(path, { force: true });
    rmSync(registrationPath(registered.parentSession || input.session_id, target), { force: true });
    return;
  }

  const claimed = claim(input, target);
  if (!claimed) return;
  writeMarker(input, registered, target, output, Date.now(), claimed);
}

function registrations(input, target) {
  reapTransport();
  if (!existsSync(transportDir())) return [];
  const current = checkout(input.cwd || process.cwd());
  if (!current) return [];
  return readdirSync(transportDir())
    .filter((name) => /^registration-[a-f0-9]{64}\\.json$/.test(name))
    .flatMap((name) => {
      const path = join(transportDir(), name);
      try {
        const registered = JSON.parse(readFileSync(path, "utf8"));
        return registered.role === role && registered.target === target &&
          registered.root === current.root && registered.physical === current.physical
          ? [{ path, registered, age: Date.now() - Math.floor(statSync(path).mtimeMs) }]
          : [];
      } catch { return []; }
    });
}

function persistPending(input, target, output) {
  target = normalizeTarget(target);
  if (!target || typeof output !== "string" || !output) return;
  const candidates = registrations(input, target);
  if (candidates.length !== 1) {
    diagnostic(candidates.length ? "ambiguous-parent-registration" : "missing-parent-registration", input);
    return;
  }
  const { registered, age } = candidates[0];
  if (!validRegistration(registered, input, target, age)) return;
  if (!outputAllowed(output, registered)) {
    diagnostic("non-pass-or-mismatched-output", input);
    return;
  }
  const path = receiptPath(registered.parentSession, target);
  if (existsSync(path) || existsSync(path + ".done")) return;
  try {
    writeFileSync(path, JSON.stringify({ ...registered, output, completedAt: Date.now() }), { flag: "wx", mode: 0o600 });
  } catch (error) {
    if (error?.code !== "EEXIST") diagnostic("receipt-write-failed", input);
  }
}

function consumePending(input) {
  reapTransport();
  if (!existsSync(transportDir())) return;
  const prefix = \`receipt-\`;
  for (const name of readdirSync(transportDir()).filter((entry) => entry.startsWith(prefix) && entry.endsWith(".json"))) {
    const path = join(transportDir(), name);
    let pending, age;
    try {
      pending = JSON.parse(readFileSync(path, "utf8"));
      age = Date.now() - pending.completedAt;
    } catch {
      diagnostic("malformed-receipt", input);
      continue;
    }
    if (pending.parentSession !== input.session_id || pending.role !== role) continue;
    if (!validRegistration(pending, input, pending.target, age)) continue;
    const claimPath = path + ".claim";
    const donePath = path + ".done";
    try { writeFileSync(claimPath, "", { flag: "wx", mode: 0o600 }); }
    catch (error) { if (error?.code === "EEXIST") continue; throw error; }
    const claimed = { path: claimPath, done: donePath };
    if (writeMarker(input, pending, pending.target, pending.output, pending.completedAt, claimed)) {
      rmSync(path, { force: true });
    }
  }
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

try {
  if (SPAWN_TOOLS.has(input.tool_name)) remember(input);
  if (CLOSE_TOOLS.has(input.tool_name)) close(input);
  if (WAIT_TOOLS.has(input.tool_name)) wait(input);
  if (input.hook_event_name === "UserPromptSubmit" || input.hook_event_name === "PreToolUse" || ["Bash", "Edit", "Write", "ExitPlanMode"].includes(input.tool_name)) consumePending(input);
  if (input.hook_event_name === "SubagentStop") {
    if (input.agent_type !== role) diagnostic("unrelated-subagent-stop", input);
    else {
      const target = input.task_name || input.agent_name || input.agent_id;
      const local = statePath(input, normalizeTarget(target));
      if (existsSync(local)) complete(input, target, input.last_assistant_message);
      else persistPending(input, target, input.last_assistant_message);
    }
  }
} catch {
  diagnostic("transport-error", input);
  process.exitCode = 0;
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
