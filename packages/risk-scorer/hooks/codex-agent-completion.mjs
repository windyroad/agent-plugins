#!/usr/bin/env node

import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, readdirSync, realpathSync, renameSync, rmSync, statSync, utimesSync, writeFileSync } from "node:fs";
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

function pendingDir() {
  return join(process.env.TMPDIR || "/tmp", "claude-risk-pending");
}

function fieldType(input, field) {
  if (!input || !Object.prototype.hasOwnProperty.call(input, field)) return "absent";
  if (input[field] === null) return "null";
  if (Array.isArray(input[field])) return "array";
  return typeof input[field];
}

function diagnoseSubagentStop(input, outcome, reason) {
  const dir = pendingDir();
  const path = join(dir, "subagent-stop-diagnostic.json");
  const temporary = join(dir, `.subagent-stop-diagnostic-${process.pid}.tmp`);
  try {
    mkdirSync(dir, { recursive: true });
    writeFileSync(temporary, JSON.stringify({
      timestamp: new Date().toISOString(),
      outcome,
      reason,
      event: input?.hook_event_name === "SubagentStop" ? "SubagentStop" : "other",
      fields: Object.fromEntries([
        "session_id",
        "agent_id",
        "agent_type",
        "last_assistant_message",
      ].map((field) => [field, fieldType(input, field)])),
    }), { mode: 0o600 });
    renameSync(temporary, path);
  } catch {
    rmSync(temporary, { force: true });
  }
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

function pipelineAssessment(output, reject = () => {}) {
  if (typeof output !== "string" || !output) {
    reject("missing-output");
    return null;
  }
  const roots = [...output.matchAll(/^RISK_CWD:[ \t]*(.+)$/gm)];
  if (roots.length !== 1) {
    reject(roots.length ? "multiple-risk-cwd" : "missing-risk-cwd");
    return null;
  }

  const declaredRoot = roots[0][1].trim();
  if (!isAbsolute(declaredRoot)) {
    reject("relative-risk-cwd");
    return null;
  }

  let root;
  try {
    root = realpathSync(declaredRoot);
  } catch {
    reject("unreadable-risk-cwd");
    return null;
  }
  const git = spawnSync("git", ["-C", root, "rev-parse", "--show-toplevel"], { encoding: "utf8" });
  if (git.status !== 0) {
    reject("not-git-worktree");
    return null;
  }

  let gitRoot;
  try {
    gitRoot = realpathSync(git.stdout.trim());
  } catch {
    reject("unreadable-git-root");
    return null;
  }
  if (gitRoot !== root) {
    reject("risk-cwd-not-git-root");
    return null;
  }

  let sanitized = output.split(/\r?\n/).filter((line) => !line.startsWith("RISK_CWD:")).join("\n");
  for (const privatePath of new Set([declaredRoot, root])) {
    sanitized = sanitized.split(privatePath).join("<assessed-root>");
  }
  return { root, output: sanitized };
}

function checkoutId(root) {
  const stat = statSync(root);
  return createHash("sha256").update(`${stat.dev}:${stat.ino}`).digest("hex");
}

function stateHash(root) {
  const state = spawnSync(join(hookDir, "lib/pipeline-state.sh"), ["--hash-inputs"], {
    cwd: root,
    encoding: "utf8",
  });
  if (state.status !== 0) return null;
  return createHash("md5").update(state.stdout).digest("hex");
}

function completionId(input, output) {
  if (typeof input.session_id !== "string" || typeof input.agent_id !== "string") return null;
  return createHash("sha256").update(`${input.session_id}\0${input.agent_id}\0${output}`).digest("hex");
}

function pendingPath(id, hash, completion, suffix = "") {
  return join(pendingDir(), `${id}-${hash}-${completion}${suffix}`);
}

function freshReceipt(path) {
  if (!existsSync(path)) return false;
  const ttl = Number.parseInt(process.env.RISK_TTL || "3600", 10) * 1000;
  return Date.now() - statSync(path).mtimeMs < ttl;
}

function persistPendingPipeline(input) {
  diagnoseSubagentStop(input, "received", "pipeline-receipt-attempt");
  if (input.agent_type !== "wr-risk-scorer:pipeline") {
    diagnoseSubagentStop(input, "rejected", "unexpected-agent-type");
    return;
  }
  let rejection;
  const assessment = pipelineAssessment(input.last_assistant_message, (reason) => { rejection = reason; });
  if (!assessment) {
    diagnoseSubagentStop(input, "rejected", rejection || "invalid-assessment");
    return;
  }
  const id = checkoutId(assessment.root);
  const hash = stateHash(assessment.root);
  const completion = completionId(input, assessment.output);
  if (!hash) {
    diagnoseSubagentStop(input, "rejected", "state-hash-failed");
    return;
  }
  if (!completion) {
    diagnoseSubagentStop(input, "rejected", "missing-completion-identity");
    return;
  }
  if (!/^RISK_SCORES: commit=\d+ push=\d+ release=\d+$/m.test(assessment.output)) {
    diagnoseSubagentStop(input, "rejected", "missing-risk-scores");
    return;
  }
  mkdirSync(pendingDir(), { recursive: true });
  const path = pendingPath(id, hash, completion);
  for (const candidate of [path, `${path}.done`]) {
    if (freshReceipt(candidate)) {
      diagnoseSubagentStop(input, "duplicate", "fresh-receipt-exists");
      return;
    }
    rmSync(candidate, { force: true });
  }
  try {
    writeFileSync(path, JSON.stringify({
      role: input.agent_type,
      output: assessment.output,
      checkoutId: id,
      stateHash: hash,
      completionId: completion,
      createdAt: Date.now(),
    }), { flag: "wx", mode: 0o600 });
    diagnoseSubagentStop(input, "receipt-written", "checkout-bound-receipt");
  } catch (error) {
    if (error?.code === "EEXIST") {
      diagnoseSubagentStop(input, "duplicate", "receipt-race");
      return;
    }
    diagnoseSubagentStop(input, "rejected", "receipt-write-failed");
    throw error;
  }
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
  const state = typeof input.agent_id === "string" ? statePath(input, input.agent_id) : "";
  if (state && existsSync(state)) {
    markTarget(input, input.agent_id, input.last_assistant_message);
    return;
  }
  persistPendingPipeline(input);
}

function consumePending(input) {
  if (!/^[A-Za-z0-9-]+$/.test(input.session_id || "")) return;
  let root;
  try {
    root = realpathSync(process.cwd());
  } catch {
    return;
  }
  const git = spawnSync("git", ["-C", root, "rev-parse", "--show-toplevel"], { encoding: "utf8" });
  if (git.status !== 0 || realpathSync(git.stdout.trim()) !== root) return;

  const id = checkoutId(root);
  const hash = stateHash(root);
  if (!hash) return;
  const prefix = `${id}-${hash}-`;
  const pendingPaths = existsSync(pendingDir())
    ? readdirSync(pendingDir())
      .filter((name) => name.startsWith(prefix) && !name.endsWith(".claim") && !name.endsWith(".done"))
      .map((name) => join(pendingDir(), name))
      .sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs)
    : [];
  const path = pendingPaths[0];
  if (!path) return;

  const claim = `${path}.claim`;
  try {
    writeFileSync(claim, "", { flag: "wx", mode: 0o600 });
  } catch (error) {
    if (error?.code === "EEXIST") return;
    throw error;
  }

  try {
    const pending = JSON.parse(readFileSync(path, "utf8"));
    const ttl = Number.parseInt(process.env.RISK_TTL || "3600", 10) * 1000;
    if (pending.role !== "wr-risk-scorer:pipeline" || pending.checkoutId !== id ||
        pending.stateHash !== hash || typeof pending.output !== "string" ||
        typeof pending.completionId !== "string" || !path.endsWith(`-${pending.completionId}`) ||
        !Number.isFinite(pending.createdAt) || Date.now() - pending.createdAt < 0 ||
        Date.now() - pending.createdAt >= ttl) return;

    const synthetic = {
      ...input,
      cwd: root,
      tool_name: "Agent",
      tool_input: { subagent_type: pending.role, prompt: "" },
      tool_response: { content: [{ type: "text", text: pending.output }] },
    };
    const result = spawnSync(join(hookDir, "risk-score-mark.sh"), {
      cwd: root,
      env: process.env,
      input: JSON.stringify(synthetic),
      encoding: "utf8",
    });
    if (result.status !== 0) {
      process.exitCode = 1;
      return;
    }
    const assessedAt = new Date(pending.createdAt);
    const markers = ["commit", "push", "release", "commit-born", "push-born", "release-born"];
    if (/^RISK_BYPASS:\s*reducing\s*$/m.test(pending.output)) {
      markers.push("reducing-commit", "reducing-push", "reducing-release");
    } else if (/^RISK_BYPASS:\s*incident\s*$/m.test(pending.output)) {
      markers.push("incident-release");
    }
    for (const marker of markers) {
      const markerPath = join(riskDir(input.session_id), marker);
      if (existsSync(markerPath)) utimesSync(markerPath, assessedAt, assessedAt);
    }
    renameSync(path, `${path}.done`);
    for (const stale of pendingPaths.slice(1)) rmSync(stale, { force: true });
  } finally {
    rmSync(claim, { force: true });
  }
}

let body = "";
process.stdin.setEncoding("utf8");
for await (const chunk of process.stdin) body += chunk;

let input;
try {
  input = JSON.parse(body);
} catch {
  if (process.argv.includes("--subagent-stop")) {
    diagnoseSubagentStop({}, "rejected", "malformed-json");
  }
  process.exit(0);
}

if (process.argv.includes("--consume-pending")) {
  consumePending(input);
  process.exit(process.exitCode || 0);
}

if (!/^[A-Za-z0-9-]+$/.test(input.session_id || "")) {
  if (process.argv.includes("--subagent-stop")) {
    diagnoseSubagentStop(input, "rejected", "invalid-session-id");
  }
  process.exit(0);
}

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
