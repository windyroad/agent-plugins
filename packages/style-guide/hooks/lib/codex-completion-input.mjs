import { readdirSync } from "node:fs";

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
