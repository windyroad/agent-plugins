/**
 * Shared install utilities for @windyroad/* packages.
 * Used by both per-plugin installers and the meta-installer.
 */

import { execSync } from "node:child_process";
import { createHash } from "node:crypto";
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const MARKETPLACE_REPO = "windyroad/agent-plugins";
const MARKETPLACE_NAME = "windyroad";
const CODEX_MARKETPLACE_PATH = ".";
const CODEX_MARKETPLACE_NAME = "windyroad-local";
const PACKAGE_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

let _dryRun = false;

export { MARKETPLACE_REPO, MARKETPLACE_NAME, CODEX_MARKETPLACE_PATH, CODEX_MARKETPLACE_NAME };

export function setDryRun(value) {
  _dryRun = value;
}

export function isDryRun() {
  return _dryRun;
}

export function run(cmd, label) {
  console.log(`  ${label}...`);
  if (_dryRun) {
    console.log(`    [dry-run] ${cmd}`);
    return true;
  }
  try {
    execSync(cmd, { stdio: "inherit" });
    return true;
  } catch {
    console.error(`  FAILED: ${label}`);
    return false;
  }
}

function runtimesFor(runtime = "claude") {
  if (runtime === "both") return ["claude", "codex"];
  return [runtime];
}

export function checkPrerequisites({ runtime = "claude" } = {}) {
  if (_dryRun) return;

  for (const currentRuntime of runtimesFor(runtime)) {
    if (currentRuntime === "claude") {
      try {
        execSync("claude --version", { stdio: "pipe" });
      } catch {
        console.error(
          "Error: 'claude' CLI not found. Install Claude Code first:\n  https://docs.anthropic.com/en/docs/claude-code\n"
        );
        process.exit(1);
      }
    } else if (currentRuntime === "codex") {
      try {
        execSync("codex --version", { stdio: "pipe" });
      } catch {
        console.error(
          "Error: 'codex' CLI not found. Install Codex CLI first:\n  https://developers.openai.com/codex\n"
        );
        process.exit(1);
      }
    }
  }
}

export function addMarketplace() {
  return run(
    `claude plugin marketplace add ${MARKETPLACE_REPO}`,
    `Marketplace: ${MARKETPLACE_NAME}`
  );
}

export function addCodexMarketplace() {
  return run(
    `codex plugin marketplace add ${CODEX_MARKETPLACE_PATH}`,
    `Codex marketplace: ${CODEX_MARKETPLACE_NAME}`
  );
}

function codexMarketplace(pluginName) {
  return `windyroad-${pluginName.replace(/^wr-/, "")}-local`;
}

function codexMarketplaceRoot(pluginName) {
  const version = JSON.parse(readFileSync(join(PACKAGE_ROOT, "package.json"), "utf8")).version;
  return join(process.env.CODEX_HOME || join(homedir(), ".codex"), ".tmp", "marketplaces", `${pluginName}-${version}`);
}

function codexAgentDir(scope) {
  return scope === "user"
    ? join(process.env.CODEX_HOME || join(homedir(), ".codex"), "agents")
    : join(process.cwd(), ".codex", "agents");
}

function codexTerms(text) {
  return text
    .replaceAll("AskUserQuestion", "request_user_input")
    .replaceAll("Agent tool", "native Codex subagent tool")
    .replaceAll("Skill tool", "installed skill invocation")
    .replaceAll("Claude Code", "Codex")
    .replace(/\bClaude\b/g, "Codex")
    .replaceAll(".claude", ".codex");
}

function splitFrontmatter(markdown) {
  const end = markdown.indexOf("\n---\n", 4);
  return markdown.startsWith("---\n") && end !== -1
    ? { frontmatter: markdown.slice(4, end), body: markdown.slice(end + 5) }
    : { frontmatter: "", body: markdown };
}

function frontmatterDescription(frontmatter) {
  const lines = frontmatter.split(/\r?\n/);
  const start = lines.findIndex((line) => line.startsWith("description:"));
  if (start === -1) return "Windy Road reviewer.";
  const value = [lines[start].slice("description:".length).trim()];
  for (let index = start + 1; index < lines.length && /^\s+/.test(lines[index]); index += 1) {
    value.push(lines[index].trim());
  }
  return value.filter(Boolean).join(" ");
}

function renderCodexAgent(pluginName, agent) {
  const source = join(PACKAGE_ROOT, agent.source);
  const { frontmatter, body } = splitFrontmatter(readFileSync(source, "utf8"));
  const codexInstructions = agent.name === "wr-voice-tone:external-comms"
    ? `\n\n## Codex completion marker compatibility\n\nOn PASS, compute the lowercase SHA-256 marker key using the normalization specified above and append \`EXTERNAL_COMMS_VOICE_TONE_KEY: <64 lowercase hex characters>\`. Codex may hide the spawn prompt from PostToolUse hooks, so this emitted key is required. On FAIL, do not emit a key.`
    : "";
  const payload = [
    `# Do not edit by hand; update ${agent.source} and reinstall.`,
    `name = ${JSON.stringify(agent.name)}`,
    `description = ${JSON.stringify(frontmatterDescription(frontmatter))}`,
    'sandbox_mode = "read-only"',
    'developer_instructions = """',
    codexTerms(`${body.trimEnd()}${codexInstructions}`).replace(/\\/g, "\\\\").replace(/"""/g, '\\"\\"\\"').trimEnd(),
    '"""',
    "",
  ].join("\n");
  const owner = `# Generated by @windyroad/${pluginName.replace(/^wr-/, "")} from ${agent.source}.`;
  const hash = createHash("sha256").update(payload).digest("hex");
  return `${owner}\n# Generated content SHA-256: ${hash}\n${payload}`;
}

function isOwnedCodexAgent(content, pluginName, agent) {
  const owner = `# Generated by @windyroad/${pluginName.replace(/^wr-/, "")} from ${agent.source}.`;
  const lines = content.split("\n");
  const hash = lines[1]?.match(/^# Generated content SHA-256: ([0-9a-f]{64})$/)?.[1];
  return content.startsWith(`${owner}\n`) && Boolean(hash)
    && createHash("sha256").update(lines.slice(2).join("\n")).digest("hex") === hash;
}

function installCodexAgents(pluginName, agents, scope) {
  if (agents.length === 0 || _dryRun) return;
  const targetDir = codexAgentDir(scope);
  mkdirSync(targetDir, { recursive: true });
  for (const agent of agents) {
    const target = join(targetDir, agent.filename);
    const expected = renderCodexAgent(pluginName, agent);
    if (existsSync(target)) {
      const current = readFileSync(target, "utf8");
      if (current === expected) continue;
      if (!isOwnedCodexAgent(current, pluginName, agent)) {
        console.log(`Preserved user-managed Codex agent at ${target}.`);
        continue;
      }
    }
    writeFileSync(target, expected, "utf8");
  }
}

function uninstallCodexAgents(pluginName, agents, scope) {
  if (_dryRun) return;
  for (const targetDir of new Set([codexAgentDir(scope), codexAgentDir("user")])) {
    for (const agent of agents) {
      const target = join(targetDir, agent.filename);
      if (existsSync(target) && isOwnedCodexAgent(readFileSync(target, "utf8"), pluginName, agent)) rmSync(target);
    }
  }
}

function installPackedCodexPlugin(pluginName, { agents = [], scope = "project" } = {}) {
  const marketplace = codexMarketplace(pluginName);
  const root = codexMarketplaceRoot(pluginName);
  if (!_dryRun) {
    rmSync(root, { recursive: true, force: true });
    mkdirSync(dirname(root), { recursive: true });
    cpSync(PACKAGE_ROOT, root, { recursive: true });
    const hooks = join(root, "hooks-codex", "hooks.json");
    if (existsSync(hooks)) cpSync(hooks, join(root, "hooks", "hooks.json"));
  }
  if (!run(`codex plugin marketplace add ${JSON.stringify(root)}`, `Codex marketplace: ${marketplace}`)) return false;
  if (!run(`codex plugin add ${pluginName}@${marketplace}`, pluginName)) return false;
  installCodexAgents(pluginName, agents, scope);
  return true;
}

function uninstallPackedCodexPlugin(pluginName, { agents = [], scope = "project" } = {}) {
  const marketplace = codexMarketplace(pluginName);
  const removed = run(`codex plugin remove ${pluginName}@${marketplace}`, `Removing ${pluginName}`);
  run(`codex plugin marketplace remove ${marketplace}`, `Removing ${marketplace}`);
  uninstallCodexAgents(pluginName, agents, scope);
  if (!_dryRun) rmSync(codexMarketplaceRoot(pluginName), { recursive: true, force: true });
  return removed;
}

export function installPlugin(pluginName, { scope = "project" } = {}) {
  return run(
    `claude plugin install ${pluginName}@${MARKETPLACE_NAME} --scope ${scope}`,
    pluginName
  );
}

export function installCodexPlugin(pluginName) {
  return run(
    `codex plugin add ${pluginName}@${CODEX_MARKETPLACE_NAME}`,
    pluginName
  );
}

export function updatePlugin(pluginName, { scope = "project" } = {}) {
  return run(
    `claude plugin update "${pluginName}@${MARKETPLACE_NAME}" --scope ${scope}`,
    pluginName
  );
}

export function updateCodexMarketplace() {
  return run(
    `codex plugin marketplace add ${CODEX_MARKETPLACE_PATH}`,
    `Codex marketplace: ${CODEX_MARKETPLACE_NAME}`
  );
}

export function uninstallPlugin(pluginName) {
  return run(`claude plugin uninstall ${pluginName}`, `Removing ${pluginName}`);
}

export function uninstallCodexPlugin(pluginName) {
  return run(`codex plugin remove ${pluginName}`, `Removing ${pluginName}`);
}

/**
 * Install a single package: marketplace add + plugin install.
 */
export function installPackage(pluginName, { agents = [], deps = [], scope = "project", runtime = "claude" } = {}) {
  console.log(`\nInstalling @windyroad/${pluginName.replace("wr-", "")} (${scope} scope)...\n`);

  if (runtime === "claude" || runtime === "both") {
    addMarketplace();
    installPlugin(pluginName, { scope });
  }

  if (runtime === "codex" || runtime === "both") {
    if (!installPackedCodexPlugin(pluginName, { agents, scope })) process.exitCode = 1;
  }

  if (deps.length > 0) {
    console.log(`\nNote: This plugin works best with:`);
    for (const dep of deps) {
      console.log(`  - @windyroad/${dep.replace("wr-", "")} (npx @windyroad/${dep.replace("wr-", "")})`);
    }
  }

  console.log(
    `\nDone! Restart ${runtime === "codex" ? "Codex" : runtime === "both" ? "Claude Code and Codex" : "Claude Code"} to activate.\n`
  );
}

/**
 * Update a single package.
 */
export function updatePackage(pluginName, { agents = [], scope = "project", runtime = "claude" } = {}) {
  console.log(`\nUpdating @windyroad/${pluginName.replace("wr-", "")}...\n`);

  if (runtime === "claude" || runtime === "both") {
    run(
      `claude plugin marketplace update ${MARKETPLACE_NAME}`,
      "Updating marketplace"
    );
    updatePlugin(pluginName, { scope });
  }

  if (runtime === "codex" || runtime === "both") {
    if (!installPackedCodexPlugin(pluginName, { agents, scope })) process.exitCode = 1;
  }

  console.log(`\nDone! Restart ${runtime === "codex" ? "Codex" : runtime === "both" ? "Claude Code and Codex" : "Claude Code"} to apply updates.\n`);
}

/**
 * Uninstall a single package.
 */
export function uninstallPackage(pluginName, { agents = [], scope = "project", runtime = "claude" } = {}) {
  console.log(`\nUninstalling @windyroad/${pluginName.replace("wr-", "")}...\n`);

  if (runtime === "claude" || runtime === "both") {
    uninstallPlugin(pluginName);
  }

  if (runtime === "codex" || runtime === "both") {
    if (!uninstallPackedCodexPlugin(pluginName, { agents, scope })) process.exitCode = 1;
  }

  console.log(`\nDone. Restart ${runtime === "codex" ? "Codex" : runtime === "both" ? "Claude Code and Codex" : "Claude Code"} to apply changes.\n`);
}

/**
 * Parse standard flags used by all per-plugin installers.
 */
export function parseStandardArgs(argv) {
  const args = argv.slice(2);
  const flags = {
    help: args.includes("--help") || args.includes("-h"),
    uninstall: args.includes("--uninstall"),
    update: args.includes("--update"),
    dryRun: args.includes("--dry-run"),
    scope: "project",
    runtime: "claude",
  };
  const scopeIdx = args.indexOf("--scope");
  if (scopeIdx !== -1 && args[scopeIdx + 1]) {
    const val = args[scopeIdx + 1];
    if (["project", "user", "local"].includes(val)) {
      flags.scope = val;
    } else {
      console.error("--scope requires: project, user, or local");
      process.exit(1);
    }
  }
  const runtimeIdx = args.indexOf("--runtime");
  if (runtimeIdx !== -1 && args[runtimeIdx + 1]) {
    const val = args[runtimeIdx + 1];
    if (["claude", "codex", "both"].includes(val)) {
      flags.runtime = val;
    } else {
      console.error("--runtime requires: claude, codex, or both");
      process.exit(1);
    }
  }
  return flags;
}
