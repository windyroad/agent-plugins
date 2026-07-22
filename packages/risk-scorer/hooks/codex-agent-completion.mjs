#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
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

function statePath(input, target) {
  return join(riskDir(input.session_id), `codex-agent-${Buffer.from(target).toString("base64url")}`);
}

function rememberSpawn(input) {
  const role = input.tool_input?.agent_type;
  const target = response(input).task_name;
  if (!riskAgentRoles.has(role) || typeof target !== "string" || !target.startsWith("/")) return;
  mkdirSync(riskDir(input.session_id), { recursive: true });
  writeFileSync(statePath(input, target), role, "utf8");
}

function markCompletion(input) {
  const target = input.tool_input?.target;
  const output = response(input).previous_status?.completed;
  if (typeof target !== "string" || typeof output !== "string" || !output) return;

  const state = statePath(input, target);
  if (!existsSync(state)) return;
  const role = readFileSync(state, "utf8");
  if (!riskAgentRoles.has(role)) return;

  const synthetic = {
    ...input,
    tool_name: "Agent",
    tool_input: { subagent_type: role, prompt: "" },
    tool_response: { content: [{ type: "text", text: output }] },
  };
  const result = spawnSync(join(hookDir, "risk-score-mark.sh"), {
    cwd: input.cwd || process.cwd(),
    env: process.env,
    input: JSON.stringify(synthetic),
    encoding: "utf8",
  });
  if (result.status === 0) rmSync(state, { force: true });
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

if (input.tool_name === "collaborationspawn_agent") rememberSpawn(input);
if (input.tool_name === "collaborationinterrupt_agent") markCompletion(input);
