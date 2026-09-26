#!/usr/bin/env node

import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, readdirSync, realpathSync, renameSync, rmSync, statSync, utimesSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { CLOSE_TOOLS, SPAWN_TOOLS, WAIT_TOOLS, response } from "./lib/codex-completion-input.mjs";

const hookDir = dirname(fileURLToPath(import.meta.url));
const role = "wr-architect:agent";
const ttlText = process.env.REVIEW_TTL ?? "3600";
const ttl = Number(ttlText) * 1000;

function riskDir(sessionId) { return join(process.env.TMPDIR || "/tmp", `claude-risk-${sessionId}`); }
function transportDir() { return join(process.env.TMPDIR || "/tmp", "codex-review-transport"); }
function normalizeTarget(target) {
  if (typeof target !== "string") return "";
  return target.startsWith("/root/") ? target.slice(6) : target;
}
function id(sessionId, target) { return createHash("sha256").update(`${sessionId}\0${role}\0${target}`).digest("hex"); }
function statePath(sessionId, target, suffix = "") {
  return join(riskDir(sessionId), `codex-architect-${Buffer.from(target).toString("base64url")}${suffix}`);
}
function registrationPath(sessionId, target) { return join(transportDir(), `registration-${id(sessionId, target)}.json`); }
function receiptPath(sessionId, target, suffix = "") { return join(transportDir(), `receipt-${id(sessionId, target)}.json${suffix}`); }

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
  return { root, physical: `${stat.dev}:${stat.ino}` };
}

function policyHash(root) {
  const result = spawnSync("bash", ["-c", 'source "$1"; _substance_hash_path docs/decisions', "architect-policy", join(hookDir, "lib", "gate-helpers.sh")], { cwd: root, encoding: "utf8" });
  const hash = result.stdout?.trim();
  return result.status === 0 && /^[a-f0-9]{64}$/.test(hash || "") ? hash : null;
}

function parsedVerdict(output) {
  const result = spawnSync("bash", ["-c", 'source "$1"; architect_verdict', "architect-verdict", join(hookDir, "lib", "architect-verdict.sh")], {
    input: output,
    encoding: "utf8",
  });
  return result.status === 0 ? result.stdout.trim() : "";
}

function diagnostic(reason, input) {
  const path = join(process.env.TMPDIR || "/tmp", "codex-review-completion-diagnostic.json");
  const temporary = `${path}.${process.pid}.tmp`;
  try {
    writeFileSync(temporary, JSON.stringify({ timestamp: new Date().toISOString(), reason, role, event: input?.hook_event_name || input?.tool_name || "unknown" }), { mode: 0o600 });
    renameSync(temporary, path);
  } catch { rmSync(temporary, { force: true }); }
}

function reapTransport() {
  if (!existsSync(transportDir())) return;
  for (const name of readdirSync(transportDir())) {
    const path = join(transportDir(), name);
    try {
      const statAge = Date.now() - statSync(path).mtimeMs;
      if (/^(?:receipt|risk-receipt)-[a-f0-9]{64}\.json\.(?:claim|done)$/.test(name)) {
        if (!Number.isFinite(statAge) || statAge < 0 || statAge >= ttl) rmSync(path, { force: true });
        continue;
      }
      if (!/^(?:registration|receipt)-[a-f0-9]{64}\.json$/.test(name)) continue;
      const value = JSON.parse(readFileSync(path, "utf8"));
      if (value.role !== role) continue;
      const timestamp = name.startsWith("receipt-") ? value.completedAt : value.createdAt;
      const age = Date.now() - timestamp;
      if (!Number.isFinite(age) || age < 0 || age >= ttl) rmSync(path, { force: true });
    } catch { /* Another completion may own or remove this transport file. */ }
  }
}

function clear(sessionId, target) {
  for (const suffix of ["", ".claim", ".done"]) rmSync(statePath(sessionId, target, suffix), { force: true });
  rmSync(registrationPath(sessionId, target), { force: true });
  for (const suffix of ["", ".claim", ".done"]) rmSync(receiptPath(sessionId, target, suffix), { force: true });
}

function remember(input) {
  reapTransport();
  const result = response(input);
  const target = normalizeTarget(result.agent_id ?? result.task_name);
  if (!target) return;
  mkdirSync(riskDir(input.session_id), { recursive: true });
  clear(input.session_id, target);
  if (input.tool_input?.agent_type !== role) return;
  const bound = checkout(input.cwd || process.cwd());
  const hash = bound && policyHash(bound.root);
  if (!bound || !hash) return diagnostic(bound ? "policy-hash-failed" : "invalid-spawn-checkout", input);
  const registered = { parentSession: input.session_id, role, target, ...bound, policyHash: hash, createdAt: Date.now() };
  writeFileSync(statePath(input.session_id, target), JSON.stringify(registered), { mode: 0o600 });
  mkdirSync(transportDir(), { recursive: true, mode: 0o700 });
  writeFileSync(registrationPath(input.session_id, target), JSON.stringify(registered), { mode: 0o600 });
}

function valid(registered, input, target, age) {
  if (registered.role !== role || registered.target !== target) return diagnostic("registration-mismatch", input), false;
  if (!Number.isFinite(age) || age < 0) return diagnostic("invalid-registration-age", input), false;
  if (age >= ttl) return diagnostic("stale-registration", input), false;
  const current = checkout(input.cwd || process.cwd());
  if (!current || current.root !== registered.root || current.physical !== registered.physical) return diagnostic("checkout-mismatch", input), false;
  const hash = policyHash(current.root);
  if (!hash || hash !== registered.policyHash) return diagnostic(hash ? "policy-changed" : "policy-hash-failed", input), false;
  return true;
}

function writeMarker(input, registered, target, output, completedAt, claim, done) {
  const synthetic = { ...input, session_id: registered.parentSession, cwd: registered.root, tool_name: "Agent", tool_input: { subagent_type: role }, tool_response: { content: [{ type: "text", text: output }] } };
  const result = spawnSync(join(hookDir, "architect-mark-reviewed.sh"), { cwd: registered.root, env: process.env, input: JSON.stringify(synthetic), encoding: "utf8" });
  if (result.status !== 0) {
    rmSync(claim, { force: true });
    diagnostic("marker-writer-failed", input);
    return false;
  }
  renameSync(claim, done);
  rmSync(statePath(registered.parentSession, target), { force: true });
  rmSync(registrationPath(registered.parentSession, target), { force: true });
  const assessedAt = new Date(completedAt);
  for (const marker of [`/tmp/architect-reviewed-${registered.parentSession}`, `/tmp/architect-reviewed-${registered.parentSession}.hash`, `/tmp/architect-plan-reviewed-${registered.parentSession}`]) {
    if (existsSync(marker)) utimesSync(marker, assessedAt, assessedAt);
  }
  return true;
}

function complete(input, rawTarget, output) {
  const target = normalizeTarget(rawTarget);
  if (!target || typeof output !== "string" || !output) return;
  const state = statePath(input.session_id, target);
  if (!existsSync(state) || existsSync(`${state}.done`)) return;
  let registered, age;
  try { registered = JSON.parse(readFileSync(state, "utf8")); age = Date.now() - statSync(state).mtimeMs; }
  catch { return diagnostic("malformed-registration", input); }
  if (!valid(registered, input, target, age)) {
    rmSync(state, { force: true });
    rmSync(registrationPath(registered.parentSession || input.session_id, target), { force: true });
    return;
  }
  const claim = `${state}.claim`;
  try { writeFileSync(claim, "", { flag: "wx", mode: 0o600 }); }
  catch (error) { if (error?.code === "EEXIST") return; throw error; }
  writeMarker(input, registered, target, output, Date.now(), claim, `${state}.done`);
}

function registrations(input, target) {
  reapTransport();
  const current = checkout(input.cwd || process.cwd());
  if (!current || !existsSync(transportDir())) return [];
  return readdirSync(transportDir()).filter((name) => /^registration-[a-f0-9]{64}\.json$/.test(name)).flatMap((name) => {
    const path = join(transportDir(), name);
    try {
      const registered = JSON.parse(readFileSync(path, "utf8"));
      return registered.role === role && registered.target === target && registered.root === current.root && registered.physical === current.physical ? [{ registered, age: Date.now() - statSync(path).mtimeMs }] : [];
    } catch { return []; }
  });
}

function persist(input) {
  const target = normalizeTarget(input.task_name || input.agent_name || input.agent_id);
  const output = input.last_assistant_message;
  if (!target || typeof output !== "string" || !output) return;
  if (parsedVerdict(output) !== "PASS") return diagnostic("non-pass-output", input);
  const candidates = registrations(input, target);
  if (candidates.length !== 1) return diagnostic(candidates.length ? "ambiguous-parent-registration" : "missing-parent-registration", input);
  const { registered, age } = candidates[0];
  if (!valid(registered, input, target, age)) return;
  const path = receiptPath(registered.parentSession, target);
  if (existsSync(path) || existsSync(`${path}.done`)) return;
  try { writeFileSync(path, JSON.stringify({ ...registered, output, completedAt: Date.now() }), { flag: "wx", mode: 0o600 }); }
  catch (error) { if (error?.code !== "EEXIST") diagnostic("receipt-write-failed", input); }
}

function consume(input) {
  reapTransport();
  if (!existsSync(transportDir())) return;
  for (const name of readdirSync(transportDir()).filter((entry) => /^receipt-[a-f0-9]{64}\.json$/.test(entry))) {
    const path = join(transportDir(), name);
    let pending;
    try { pending = JSON.parse(readFileSync(path, "utf8")); } catch { diagnostic("malformed-receipt", input); continue; }
    if (pending.parentSession !== input.session_id || pending.role !== role) continue;
    if (!valid(pending, input, pending.target, Date.now() - pending.completedAt)) continue;
    const claim = `${path}.claim`;
    try { writeFileSync(claim, "", { flag: "wx", mode: 0o600 }); }
    catch (error) { if (error?.code === "EEXIST") continue; throw error; }
    if (writeMarker(input, pending, pending.target, pending.output, pending.completedAt, claim, `${path}.done`)) rmSync(path, { force: true });
  }
}

function close(input) { complete(input, input.tool_input?.target, response(input).previous_status?.completed); }
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
if (!/^[0-9]+$/.test(ttlText) || !Number.isSafeInteger(ttl) || ttl <= 0) process.exit(0);

try {
  if (SPAWN_TOOLS.has(input.tool_name)) remember(input);
  if (CLOSE_TOOLS.has(input.tool_name)) close(input);
  if (WAIT_TOOLS.has(input.tool_name)) wait(input);
  if (input.hook_event_name === "UserPromptSubmit" || input.hook_event_name === "PreToolUse" || ["Bash", "Edit", "Write", "ExitPlanMode"].includes(input.tool_name)) consume(input);
  if (input.hook_event_name === "SubagentStop") {
    if (input.agent_type !== role) diagnostic("unrelated-subagent-stop", input);
    else if (existsSync(statePath(input.session_id, normalizeTarget(input.agent_id)))) complete(input, input.agent_id, input.last_assistant_message);
    else persist(input);
  }
} catch {
  diagnostic("transport-error", input);
  process.exitCode = 0;
}
