#!/usr/bin/env node

import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, readdirSync, realpathSync, renameSync, rmSync, statSync, utimesSync, writeFileSync } from "node:fs";
import { dirname, isAbsolute, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { CLOSE_TOOLS, SPAWN_TOOLS, WAIT_TOOLS, response } from "./lib/codex-completion-input.mjs";

const hookDir = dirname(fileURLToPath(import.meta.url));
const riskAgentRoles = new Set([
  "wr-risk-scorer:pipeline",
  "wr-risk-scorer:plan",
  "wr-risk-scorer:wip",
  "wr-risk-scorer:policy",
  "wr-risk-scorer:external-comms",
  "wr-risk-scorer:inbound-report",
]);

function riskDir(sessionId) {
  return join(process.env.TMPDIR || "/tmp", `claude-risk-${sessionId}`);
}

function pendingDir() {
  return join(process.env.TMPDIR || "/tmp", "claude-risk-pending");
}

function transportDir() {
  return join(process.env.TMPDIR || "/tmp", "codex-review-transport");
}

function normalizeTarget(target) {
  if (typeof target !== "string") return "";
  return target.startsWith("/root/") ? target.slice("/root/".length) : target;
}

function transportId(sessionId, role, target) {
  return createHash("sha256").update(`${sessionId}\0${role}\0${target}`).digest("hex");
}

function transportRegistrationPath(sessionId, role, target) {
  return join(transportDir(), `registration-${transportId(sessionId, role, target)}.json`);
}

function transportReceiptPath(sessionId, role, target, suffix = "") {
  return join(transportDir(), `risk-receipt-${transportId(sessionId, role, target)}.json${suffix}`);
}

function directoryBinding(cwd) {
  if (typeof cwd !== "string" || !cwd) return null;
  let root;
  try { root = realpathSync(cwd); } catch { return null; }
  const stat = statSync(root);
  return { root, physical: `${stat.dev}:${stat.ino}` };
}

function policyHash(root) {
  if (!existsSync(join(root, "RISK-POLICY.md"))) return null;
  const result = spawnSync("bash", ["-c", 'source "$1"; _substance_hash_path RISK-POLICY.md', "risk-policy",
    join(hookDir, "lib", "gate-helpers.sh")], { cwd: root, encoding: "utf8" });
  const hash = result.stdout?.trim();
  return result.status === 0 && /^[a-f0-9]{64}$/.test(hash || "") ? hash : null;
}

function policyBinding(root) {
  const path = join(root, "RISK-POLICY.md");
  if (!existsSync(path)) return { kind: "absent" };
  const hash = policyHash(root);
  return hash ? { kind: "hash", value: hash } : null;
}

function policyMatches(root, binding) {
  if (!binding || !["absent", "hash"].includes(binding.kind)) return false;
  const exists = existsSync(join(root, "RISK-POLICY.md"));
  if (binding.kind === "absent") return !exists;
  const current = policyHash(root);
  return Boolean(current && current === binding.value);
}

function expectedExternalKey(prompt) {
  if (typeof prompt !== "string" || !prompt) return null;
  const result = spawnSync("bash", ["-c", 'source "$1"; value="$(cat)"; derive_external_comms_key_from_prompt "$value"',
    "external-key", join(hookDir, "lib", "external-comms-key.sh")], { input: prompt, encoding: "utf8" });
  const key = result.stdout?.trim();
  return result.status === 0 && /^[a-f0-9]{64}$/.test(key || "") ? key : null;
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
  const normalized = target.startsWith("/root/") ? target.slice("/root/".length) : target;
  return join(riskDir(input.session_id), `codex-agent-${Buffer.from(normalized).toString("base64url")}${suffix}`);
}

function clearTarget(input, target) {
  const state = statePath(input, target);
  if (existsSync(state)) {
    try {
      const previousRole = readFileSync(state, "utf8");
      if (riskAgentRoles.has(previousRole)) {
        rmSync(transportRegistrationPath(input.session_id, previousRole, normalizeTarget(target)), { force: true });
        for (const suffix of ["", ".claim", ".done"]) {
          rmSync(transportReceiptPath(input.session_id, previousRole, normalizeTarget(target), suffix), { force: true });
        }
      }
    } catch { /* The local state is best-effort cleanup only. */ }
  }
  for (const suffix of ["", ".claim", ".done"]) {
    rmSync(statePath(input, target, suffix), { force: true });
  }
}

function spawnTarget(input) {
  const result = response(input);
  return result.agent_id ?? result.task_name;
}

function rememberSpawn(input) {
  reapRegisteredTransport();
  const role = input.tool_input?.agent_type;
  const target = spawnTarget(input);
  if (typeof target !== "string" || !target) return;
  mkdirSync(riskDir(input.session_id), { recursive: true });
  clearTarget(input, target);
  if (!riskAgentRoles.has(role)) return;
  writeFileSync(statePath(input, target), role, "utf8");
  const normalized = normalizeTarget(target);
  const bound = directoryBinding(input.cwd || process.cwd());
  if (!bound) return;
  const prompt = input.tool_input?.message ?? input.tool_input?.prompt ?? "";
  const policy = policyBinding(bound.root);
  if (!policy) return;
  const wipStateHash = role === "wr-risk-scorer:wip" ? stateHash(bound.root) : null;
  const wipCheckoutId = role === "wr-risk-scorer:wip" ? checkoutId(bound.root) : null;
  if (role === "wr-risk-scorer:wip" && (!wipStateHash || !wipCheckoutId)) return;
  const registered = {
    parentSession: input.session_id,
    role,
    target: normalized,
    ...bound,
    policy,
    promptDigest: createHash("sha256").update(prompt).digest("hex"),
    expectedKey: role === "wr-risk-scorer:external-comms" ? expectedExternalKey(prompt) : null,
    wipStateHash,
    wipCheckoutId,
    createdAt: Date.now(),
  };
  mkdirSync(transportDir(), { recursive: true, mode: 0o700 });
  writeFileSync(transportRegistrationPath(input.session_id, role, normalized), JSON.stringify(registered), { mode: 0o600 });
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
    rmSync(transportRegistrationPath(input.session_id, role, normalizeTarget(target)), { force: true });
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

function genericTtl() {
  const text = process.env.RISK_TTL || "3600";
  if (!/^[0-9]+$/.test(text)) return null;
  const value = Number(text) * 1000;
  return Number.isSafeInteger(value) && value > 0 ? value : null;
}

function reapRegisteredTransport() {
  const ttl = genericTtl();
  if (!ttl || !existsSync(transportDir())) return;
  for (const name of readdirSync(transportDir())) {
    const path = join(transportDir(), name);
    try {
      const statAge = Date.now() - statSync(path).mtimeMs;
      if (/^(?:receipt|risk-receipt)-[a-f0-9]{64}\.json\.(?:claim|done)$/.test(name)) {
        if (!Number.isFinite(statAge) || statAge < 0 || statAge >= ttl) rmSync(path, { force: true });
        continue;
      }
      if (!/^(?:registration|risk-receipt)-[a-f0-9]{64}\.json$/.test(name)) continue;
      const value = JSON.parse(readFileSync(path, "utf8"));
      if (!riskAgentRoles.has(value.role)) continue;
      const timestamp = name.startsWith("risk-receipt-") ? value.completedAt : value.createdAt;
      const age = Date.now() - timestamp;
      if (!Number.isFinite(age) || age < 0 || age >= ttl) rmSync(path, { force: true });
    } catch { /* Another completion may own or remove this transport file. */ }
  }
}

function registrationCandidates(input, role, target) {
  reapRegisteredTransport();
  if (!existsSync(transportDir())) return [];
  const current = directoryBinding(input.cwd || process.cwd());
  return readdirSync(transportDir())
    .filter((name) => /^registration-[a-f0-9]{64}\.json$/.test(name))
    .flatMap((name) => {
      const path = join(transportDir(), name);
      try {
        const registered = JSON.parse(readFileSync(path, "utf8"));
        if (registered.role !== role || registered.target !== target) return [];
        if (role !== "wr-risk-scorer:pipeline" && (!current || registered.root !== current.root || registered.physical !== current.physical)) return [];
        return [{ path, registered }];
      } catch { return []; }
    });
}

function singleLine(output, label) {
  return [...output.matchAll(new RegExp(`^${label}:[ \\t]*(.+)$`, "gm"))];
}

function applicableAssessment(role, output, registered, reject = () => {}) {
  if (typeof output !== "string" || !output) return reject("missing-output"), null;
  if (role === "wr-risk-scorer:pipeline") {
    let reason;
    const assessment = pipelineAssessment(output, (value) => { reason = value; });
    if (!assessment || !/^RISK_SCORES: commit=\d+ push=\d+ release=\d+$/m.test(assessment.output)) {
      reject(reason || "missing-risk-scores");
      return null;
    }
    const hash = stateHash(assessment.root);
    if (!hash) return reject("state-hash-failed"), null;
    const assessmentPolicy = policyBinding(assessment.root);
    if (!assessmentPolicy) return reject("policy-hash-failed"), null;
    return { output: assessment.output, assessmentRoot: assessment.root, assessmentPolicy,
      checkoutId: checkoutId(assessment.root), stateHash: hash };
  }
  if (role === "wr-risk-scorer:external-comms") {
    const verdicts = singleLine(output, "EXTERNAL_COMMS_RISK_VERDICT");
    const keys = singleLine(output, "EXTERNAL_COMMS_RISK_KEY");
    const key = keys.length === 1 ? keys[0][1].trim().replaceAll("`", "") : "";
    if (verdicts.length !== 1 || verdicts[0][1].trim() !== "PASS") return reject("non-pass-verdict"), null;
    if (!/^[a-f0-9]{64}$/.test(key)) return reject("invalid-external-comms-key"), null;
    if (!registered.expectedKey) return reject("missing-external-comms-key-binding"), null;
    if (registered.expectedKey !== key) return reject("external-comms-key-mismatch"), null;
    return { output, root: registered.root, key };
  }
  if (role === "wr-risk-scorer:plan" || role === "wr-risk-scorer:policy") {
    const verdicts = singleLine(output, "RISK_VERDICT");
    if (verdicts.length !== 1 || verdicts[0][1].trim() !== "PASS") return reject("non-pass-verdict"), null;
    return { output, root: registered.root };
  }
  if (role === "wr-risk-scorer:wip") {
    const verdicts = singleLine(output, "RISK_VERDICT");
    if (verdicts.length !== 1 || !/^(CONTINUE|COMMIT)$/.test(verdicts[0][1].trim())) return reject("non-authorizing-wip-verdict"), null;
    const currentHash = stateHash(registered.root);
    if (!currentHash || currentHash !== registered.wipStateHash || checkoutId(registered.root) !== registered.wipCheckoutId) return reject("wip-state-changed"), null;
    return { output, root: registered.root, wipStateHash: currentHash, wipCheckoutId: registered.wipCheckoutId };
  }
  reject("unsupported-marker-role");
  return null;
}

function registrationValid(input, registered) {
  const ttl = genericTtl();
  const age = Date.now() - registered.createdAt;
  if (!ttl) return diagnoseSubagentStop(input, "rejected", "invalid-risk-ttl"), false;
  if (!Number.isFinite(age) || age < 0 || age >= ttl) return diagnoseSubagentStop(input, "rejected", "stale-parent-registration"), false;
  if (!registered.policy || !["absent", "hash"].includes(registered.policy.kind)) return diagnoseSubagentStop(input, "rejected", "invalid-policy-binding"), false;
  if (!policyMatches(registered.root, registered.policy)) return diagnoseSubagentStop(input, "rejected", "policy-changed"), false;
  return true;
}

function persistRegisteredPending(input) {
  const role = input.agent_type;
  const target = normalizeTarget(input.task_name || input.agent_name || input.agent_id);
  if (!riskAgentRoles.has(role) || !target) return false;
  const candidates = registrationCandidates(input, role, target);
  if (candidates.length !== 1) {
    diagnoseSubagentStop(input, "rejected", candidates.length ? "ambiguous-parent-registration" : "missing-parent-registration");
    return false;
  }
  const { registered } = candidates[0];
  if (!registrationValid(input, registered)) return true;
  let rejection;
  const assessment = applicableAssessment(role, input.last_assistant_message, registered, (reason) => { rejection = reason; });
  if (!assessment) {
    diagnoseSubagentStop(input, "rejected", rejection || "invalid-assessment");
    return true;
  }
  const path = transportReceiptPath(registered.parentSession, role, target);
  if (existsSync(path) || existsSync(`${path}.done`)) {
    diagnoseSubagentStop(input, "duplicate", "fresh-parent-bound-receipt-exists");
    return true;
  }
  try {
    writeFileSync(path, JSON.stringify({ ...registered, ...assessment, completedAt: Date.now() }), { flag: "wx", mode: 0o600 });
    diagnoseSubagentStop(input, "receipt-written", "parent-bound-receipt");
  } catch (error) {
    diagnoseSubagentStop(input, error?.code === "EEXIST" ? "duplicate" : "rejected", error?.code === "EEXIST" ? "receipt-race" : "receipt-write-failed");
  }
  return true;
}

function markerPaths(role, session, pending) {
  const dir = riskDir(session);
  if (role === "wr-risk-scorer:pipeline") return ["commit", "push", "release", "commit-born", "push-born", "release-born", "state-hash", "checkout-id"].map((name) => join(dir, name));
  if (role === "wr-risk-scorer:plan") return [join(dir, "plan-reviewed"), join(dir, "state-hash")];
  if (role === "wr-risk-scorer:wip") return [join(dir, "wip-reviewed")];
  if (role === "wr-risk-scorer:policy") return [join(dir, "policy-reviewed")];
  if (role === "wr-risk-scorer:external-comms") return [join(dir, `external-comms-risk-reviewed-${pending.key}`)];
  return [];
}

function consumeRegisteredPending(input) {
  reapRegisteredTransport();
  if (!existsSync(transportDir())) return;
  const current = directoryBinding(process.cwd());
  for (const name of readdirSync(transportDir()).filter((entry) => /^risk-receipt-[a-f0-9]{64}\.json$/.test(entry))) {
    const path = join(transportDir(), name);
    let pending;
    try { pending = JSON.parse(readFileSync(path, "utf8")); } catch { continue; }
    if (pending.parentSession !== input.session_id || !riskAgentRoles.has(pending.role)) continue;
    if (!registrationValid(input, pending)) continue;
    if (pending.role === "wr-risk-scorer:pipeline") {
      if (!current || checkoutId(current.root) !== pending.checkoutId || stateHash(current.root) !== pending.stateHash) continue;
      if (current.root !== pending.assessmentRoot || !policyMatches(current.root, pending.assessmentPolicy)) continue;
    } else {
      if (!current || current.root !== pending.root || current.physical !== pending.physical) continue;
      if (pending.role === "wr-risk-scorer:wip" &&
          (checkoutId(current.root) !== pending.wipCheckoutId || stateHash(current.root) !== pending.wipStateHash)) continue;
    }
    const claim = `${path}.claim`;
    try { writeFileSync(claim, "", { flag: "wx", mode: 0o600 }); }
    catch (error) { if (error?.code === "EEXIST") continue; throw error; }
    try {
      const markerRoot = pending.role === "wr-risk-scorer:pipeline" ? pending.assessmentRoot : pending.root;
      const synthetic = { ...input, session_id: pending.parentSession, cwd: markerRoot, tool_name: "Agent",
        tool_input: { subagent_type: pending.role, prompt: "" }, tool_response: { content: [{ type: "text", text: pending.output }] } };
      const result = spawnSync(join(hookDir, "risk-score-mark.sh"), { cwd: markerRoot, env: process.env, input: JSON.stringify(synthetic), encoding: "utf8" });
      if (result.status !== 0) {
        diagnoseSubagentStop(input, "rejected", "marker-writer-failed");
        continue;
      }
      const assessedAt = new Date(pending.completedAt);
      for (const marker of markerPaths(pending.role, pending.parentSession, pending)) if (existsSync(marker)) utimesSync(marker, assessedAt, assessedAt);
      renameSync(path, `${path}.done`);
      rmSync(transportRegistrationPath(pending.parentSession, pending.role, pending.target), { force: true });
      rmSync(statePath({ session_id: pending.parentSession }, pending.target), { force: true });
    } finally { rmSync(claim, { force: true }); }
  }
}

function markSubagentStop(input) {
  const state = typeof input.agent_id === "string" ? statePath(input, input.agent_id) : "";
  if (state && existsSync(state)) {
    markTarget(input, input.agent_id, input.last_assistant_message);
    return;
  }
  persistRegisteredPending(input);
}

function consumePending(input) {
  if (!/^[A-Za-z0-9-]+$/.test(input.session_id || "")) return;
  consumeRegisteredPending(input);
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

try {
  if (process.argv.includes("--consume-pending")) {
    consumePending(input);
  } else if (!/^[A-Za-z0-9-]+$/.test(input.session_id || "")) {
    if (process.argv.includes("--subagent-stop")) diagnoseSubagentStop(input, "rejected", "invalid-session-id");
  } else {
    if (SPAWN_TOOLS.has(input.tool_name)) rememberSpawn(input);
    if (CLOSE_TOOLS.has(input.tool_name)) markClose(input);
    if (WAIT_TOOLS.has(input.tool_name)) markWait(input);
    if (input.hook_event_name === "SubagentStop") markSubagentStop(input);
  }
} catch {
  diagnoseSubagentStop(input, "rejected", "transport-error");
  process.exitCode = 0;
}
