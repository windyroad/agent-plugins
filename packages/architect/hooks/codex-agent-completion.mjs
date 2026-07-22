#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const hookDir = dirname(fileURLToPath(import.meta.url));
const role = "wr-architect:agent";

function response(input) {
  if (typeof input.tool_response === "object" && input.tool_response) return input.tool_response;
  try { return JSON.parse(input.tool_response); } catch { return {}; }
}

function riskDir(sessionId) {
  return join(process.env.TMPDIR || "/tmp", `claude-risk-${sessionId}`);
}

function statePath(input, target) {
  return join(riskDir(input.session_id), `codex-architect-${Buffer.from(target).toString("base64url")}`);
}

function remember(input) {
  const target = response(input).agent_id ?? response(input).task_name;
  if (typeof target !== "string" || !target) return;
  mkdirSync(riskDir(input.session_id), { recursive: true });
  rmSync(statePath(input, target), { force: true });
  if (input.tool_input?.agent_type === role) writeFileSync(statePath(input, target), role, "utf8");
}

function complete(input) {
  const target = input.tool_input?.target;
  const output = response(input).previous_status?.completed;
  if (typeof target !== "string" || typeof output !== "string") return;
  const state = statePath(input, target);
  if (!existsSync(state) || readFileSync(state, "utf8") !== role) return;
  rmSync(state, { force: true });
  const synthetic = {
    ...input,
    tool_name: "Agent",
    tool_input: { subagent_type: role },
    tool_response: { content: [{ type: "text", text: output }] },
  };
  spawnSync(join(hookDir, "architect-mark-reviewed.sh"), {
    cwd: input.cwd || process.cwd(),
    env: process.env,
    input: JSON.stringify(synthetic),
    encoding: "utf8",
  });
}

let body = "";
process.stdin.setEncoding("utf8");
for await (const chunk of process.stdin) body += chunk;
let input;
try { input = JSON.parse(body); } catch { process.exit(0); }
if (!/^[A-Za-z0-9-]+$/.test(input.session_id || "")) process.exit(0);

if (["collaborationspawn_agent", "spawn_agent", "multi_agent_v1__spawn_agent"].includes(input.tool_name)) remember(input);
if (["collaborationinterrupt_agent", "close_agent", "multi_agent_v1__close_agent"].includes(input.tool_name)) complete(input);
