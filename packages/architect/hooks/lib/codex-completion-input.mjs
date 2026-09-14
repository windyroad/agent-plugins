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
