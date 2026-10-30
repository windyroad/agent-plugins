import { readdirSync, readFileSync, rmSync } from "node:fs";
import { createHash } from "node:crypto";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export function reviewerFallbackPrompt(role, instructions, request) {
  return `WR_REVIEWER_FALLBACK: ${role}\n<reviewer-instructions>\n${instructions}</reviewer-instructions>\n\n${request}`;
}

// A general reviewer is identified by the installed contract actually supplied
// at dispatch, never by its task name or its returned verdict.
export function reviewerDispatch(input, loadInstructions) {
  const options = input.tool_input || {};
  const prompt = options.message ?? options.prompt ?? "";
  const named = options.agent_type;
  try {
    if (named && named !== "default") {
      return loadInstructions(named) ? { role: named, prompt } : null;
    }
    if (options.fork_turns !== "none" || typeof prompt !== "string") return null;
    const role = prompt.match(/^WR_REVIEWER_FALLBACK: ([a-z0-9-]+:[a-z0-9-]+)\n/)?.[1];
    if (!role) return null;
    const instructions = loadInstructions(role);
    if (!instructions) return null;
    const prefix = `WR_REVIEWER_FALLBACK: ${role}\n<reviewer-instructions>\n${instructions}</reviewer-instructions>\n\n`;
    if (!prompt.startsWith(prefix) || !prompt.slice(prefix.length).trim()) return null;
    return { role, prompt: prompt.slice(prefix.length), reviewerTransport: "general",
      reviewerInstructionsHash: createHash("sha256").update(instructions).digest("hex") };
  } catch { return null; }
}

export function reviewerInstructionsMatch(registered, loadInstructions) {
  if (registered.reviewerTransport === undefined) return true;
  if (registered.reviewerTransport !== "general") return false;
  try {
    const instructions = loadInstructions(registered.role);
    return Boolean(instructions && registered.reviewerInstructionsHash ===
      createHash("sha256").update(instructions).digest("hex"));
  } catch { return false; }
}

// Native replay claims share a target key with legacy receipts. In native mode
// invalidate only a demonstrably owned general registration, never its claims.
export function clearGeneralReview(input, role, target, paths) {
  const owned = value => value.reviewerTransport === "general" && value.role === role &&
    value.parentSession === input.session_id && value.target === target;
  try {
    if (!owned(JSON.parse(readFileSync(paths.registration, "utf8")))) return false;
  } catch { return false; }
  rmSync(paths.state, { force: true });
  rmSync(paths.registration, { force: true });
  try {
    if (owned(JSON.parse(readFileSync(paths.receipt, "utf8")))) rmSync(paths.receipt, { force: true });
  } catch { /* No pending general receipt to invalidate. */ }
  return true;
}

// Resolve only this session's state files, including completed claims so an
// ambiguous short name cannot consume a different reviewer after delivery.
export function completionTarget(rawTarget, directory, prefix, rolePrefix = "") {
  if (typeof rawTarget !== "string" || !rawTarget) return "";
  const canonical = rawTarget.startsWith("/root/");
  const target = canonical ? rawTarget.slice(6) : rawTarget;
  let files;
  try { files = readdirSync(directory); } catch { return ""; }
  const targets = new Set();
  for (const file of files) {
    if (!file.startsWith(prefix)) continue;
    const encoded = file.slice(prefix.length).replace(/\.(claim|done)$/, "");
    const decoded = Buffer.from(encoded, "base64url").toString();
    if (Buffer.from(decoded).toString("base64url") !== encoded || !decoded.startsWith(rolePrefix)) continue;
    targets.add(decoded.slice(rolePrefix.length));
  }
  if (targets.has(target)) return target;
  if (canonical) return "";
  const matches = [...targets].filter((registered) => registered.endsWith("/" + target));
  return matches.length === 1 ? matches[0] : "";
}

export const SPAWN_TOOLS = new Set([
  "collaboration.spawn_agent",
  "collaborationspawn_agent",
  "spawn_agent",
  "multi_agent_v1__spawn_agent",
]);

export const WAIT_TOOLS = new Set([
  "collaboration.wait_agent",
  "collaborationwait_agent",
  "wait_agent",
  "multi_agent_v1__wait_agent",
]);

export const CLOSE_TOOLS = new Set([
  "collaboration.interrupt_agent",
  "collaborationinterrupt_agent",
  "interrupt_agent",
  "close_agent",
  "multi_agent_v1__close_agent",
]);

export function parsedResponse(value) {
  if (Array.isArray(value)) {
    const text = value
      .filter((item) => item && typeof item === "object" && typeof item.text === "string")
      .map((item) => item.text)
      .join("\n");
    return parsedResponse(text);
  }
  if (typeof value === "object" && value) return value;
  try {
    return parsedResponse(JSON.parse(value));
  } catch {
    return {};
  }
}

export function response(input) {
  return parsedResponse(input?.tool_response);
}

// This only prepares a prompt. Hooks independently verify their own installed
// instruction source before registering or accepting a general review.
if (process.argv[2] === "--fallback-prompt" && process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv[2] !== "--fallback-prompt" || process.argv.length !== 5) {
    console.error("Usage: codex-completion-input.mjs --fallback-prompt <role> <installed-agent.md> < request.txt");
    process.exitCode = 1;
  } else {
    process.stdout.write(reviewerFallbackPrompt(process.argv[3], readFileSync(process.argv[4], "utf8"), readFileSync(0, "utf8")));
  }
}
