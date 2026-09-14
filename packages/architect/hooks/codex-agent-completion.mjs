#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { CLOSE_TOOLS, SPAWN_TOOLS, WAIT_TOOLS, response } from "./lib/codex-completion-input.mjs";

const hookDir = dirname(fileURLToPath(import.meta.url));
const role = "wr-architect:agent";

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

function wait(input) {
  const statuses = response(input).status;
  if (!statuses || typeof statuses !== "object") return;
  for (const [target, status] of Object.entries(statuses)) {
    complete({ ...input, tool_input: { target }, tool_response: { previous_status: status } });
  }
}

let body = "";
process.stdin.setEncoding("utf8");
for await (const chunk of process.stdin) body += chunk;
let input;
try { input = JSON.parse(body); } catch { process.exit(0); }
if (!/^[A-Za-z0-9-]+$/.test(input.session_id || "")) process.exit(0);

if (SPAWN_TOOLS.has(input.tool_name)) remember(input);
if (CLOSE_TOOLS.has(input.tool_name)) complete(input);
if (WAIT_TOOLS.has(input.tool_name)) wait(input);
