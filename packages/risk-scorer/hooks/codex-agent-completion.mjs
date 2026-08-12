#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, realpathSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { dirname, isAbsolute, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const hookDir = dirname(fileURLToPath(import.meta.url));
const riskAgentRoles = new Set([
  "wr-risk-scorer:pipeline",
  "wr-risk-scorer:plan",
  "wr-risk-scorer:wip",
  "wr-risk-scorer:policy",
  "wr-risk-scorer:external-comms",
  "wr-risk-scorer:inbound-report",
]);

function response(input) {
  if (typeof input.tool_response === "object" && input.tool_response) return input.tool_response;
  try {
    return JSON.parse(input.tool_response);
  } catch {
    return {};
  }
}

function riskDir(sessionId) {
  return join(process.env.TMPDIR || "/tmp", `claude-risk-${sessionId}`);
}

function statePath(input, target, suffix = "") {
  return join(riskDir(input.session_id), `codex-agent-${Buffer.from(target).toString("base64url")}${suffix}`);
}

function clearTarget(input, target) {
  for (const suffix of ["", ".claim", ".done"]) {
    rmSync(statePath(input, target, suffix), { force: true });
  }
}

function spawnTarget(input) {
  const result = response(input);
  return result.agent_id ?? result.task_name;
}

function rememberSpawn(input) {
  const role = input.tool_input?.agent_type;
  const target = spawnTarget(input);
  if (typeof target !== "string" || !target) return;
  mkdirSync(riskDir(input.session_id), { recursive: true });
  clearTarget(input, target);
  if (!riskAgentRoles.has(role)) return;
  writeFileSync(statePath(input, target), role, "utf8");
}

function claimTarget(input, target) {
  const claim = statePath(input, target, ".claim");
  const done = statePath(input, target, ".done");
  if (existsSync(done)) return null;
  mkdirSync(riskDir(input.session_id), { recursive: true });
  try {
    writeFileSync(claim, "", { flag: "wx" });
  } catch (error) {
    if (error?.code === "EEXIST") return null;
    throw error;
  }
  return { claim, done };
}

function pipelineAssessment(output) {
  const roots = [...output.matchAll(/^RISK_CWD:[ \t]*(.+)$/gm)];
  if (roots.length !== 1) return null;

  const declaredRoot = roots[0][1].trim();
  if (!isAbsolute(declaredRoot)) return null;

  let root;
  try {
    root = realpathSync(declaredRoot);
  } catch {
    return null;
  }
  const git = spawnSync("git", ["-C", root, "rev-parse", "--show-toplevel"], { encoding: "utf8" });
  if (git.status !== 0) return null;

  let gitRoot;
  try {
    gitRoot = realpathSync(git.stdout.trim());
  } catch {
    return null;
  }
  if (gitRoot !== root) return null;

  let sanitized = output.split(/\r?\n/).filter((line) => !line.startsWith("RISK_CWD:")).join("\n");
  for (const privatePath of new Set([declaredRoot, root])) {
    sanitized = sanitized.split(privatePath).join("<assessed-root>");
  }
  return { root, output: sanitized };
}

function markTarget(input, target, output) {
  if (typeof target !== "string" || typeof output !== "string" || !output) return;

  const state = statePath(input, target);
  if (!existsSync(state)) return;
  const role = readFileSync(state, "utf8");
  if (!riskAgentRoles.has(role)) return;
  const claim = claimTarget(input, target);
  if (!claim) return;

  const assessment = role === "wr-risk-scorer:pipeline" ? pipelineAssessment(output) : null;
  if (role === "wr-risk-scorer:pipeline" && !assessment) {
    rmSync(claim.claim, { force: true });
    process.exitCode = 1;
    return;
  }

  const cwd = assessment?.root || input.cwd || process.cwd();

  const synthetic = {
    ...input,
    cwd,
    tool_name: "Agent",
    tool_input: { subagent_type: role, prompt: "" },
    tool_response: { content: [{ type: "text", text: assessment?.output || output }] },
  };
  const result = spawnSync(join(hookDir, "risk-score-mark.sh"), {
    cwd,
    env: process.env,
    input: JSON.stringify(synthetic),
    encoding: "utf8",
  });
  if (result.status === 0) {
    renameSync(claim.claim, claim.done);
    rmSync(state, { force: true });
  } else {
    rmSync(claim.claim, { force: true });
    process.exitCode = 1;
  }
}

function markClose(input) {
  markTarget(input, input.tool_input?.target, response(input).previous_status?.completed);
}

function markWait(input) {
  const statuses = response(input).status;
  if (!statuses || typeof statuses !== "object") return;
  for (const [target, status] of Object.entries(statuses)) {
    markTarget(input, target, status?.completed);
  }
}

function markSubagentStop(input) {
  markTarget(input, input.agent_id, input.last_assistant_message);
}

let body = "";
process.stdin.setEncoding("utf8");
for await (const chunk of process.stdin) body += chunk;

let input;
try {
  input = JSON.parse(body);
} catch {
  process.exit(0);
}

if (!/^[A-Za-z0-9-]+$/.test(input.session_id || "")) process.exit(0);

if (["collaborationspawn_agent", "spawn_agent", "multi_agent_v1__spawn_agent"].includes(input.tool_name)) {
  rememberSpawn(input);
}
if (["collaborationinterrupt_agent", "interrupt_agent", "close_agent", "multi_agent_v1__close_agent"].includes(input.tool_name)) {
  markClose(input);
}
if (["collaborationwait_agent", "wait_agent", "multi_agent_v1__wait_agent"].includes(input.tool_name)) {
  markWait(input);
}
if (input.hook_event_name === "SubagentStop") {
  markSubagentStop(input);
}
