/**
 * Shared install utilities for @windyroad/* packages.
 * Used by both per-plugin installers and the meta-installer.
 */

import { execSync } from "node:child_process";

const MARKETPLACE_REPO = "windyroad/agent-plugins";
const MARKETPLACE_NAME = "windyroad";
const CODEX_MARKETPLACE_PATH = ".";
const CODEX_MARKETPLACE_NAME = "windyroad-local";

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
export function installPackage(pluginName, { deps = [], scope = "project", runtime = "claude" } = {}) {
  console.log(`\nInstalling @windyroad/${pluginName.replace("wr-", "")} (${scope} scope)...\n`);

  if (runtime === "claude" || runtime === "both") {
    addMarketplace();
    installPlugin(pluginName, { scope });
  }

  if (runtime === "codex" || runtime === "both") {
    addCodexMarketplace();
    installCodexPlugin(pluginName);
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
export function updatePackage(pluginName, { scope = "project", runtime = "claude" } = {}) {
  console.log(`\nUpdating @windyroad/${pluginName.replace("wr-", "")}...\n`);

  if (runtime === "claude" || runtime === "both") {
    run(
      `claude plugin marketplace update ${MARKETPLACE_NAME}`,
      "Updating marketplace"
    );
    updatePlugin(pluginName, { scope });
  }

  if (runtime === "codex" || runtime === "both") {
    updateCodexMarketplace();
    installCodexPlugin(pluginName);
  }

  console.log(`\nDone! Restart ${runtime === "codex" ? "Codex" : runtime === "both" ? "Claude Code and Codex" : "Claude Code"} to apply updates.\n`);
}

/**
 * Uninstall a single package.
 */
export function uninstallPackage(pluginName, { runtime = "claude" } = {}) {
  console.log(`\nUninstalling @windyroad/${pluginName.replace("wr-", "")}...\n`);

  if (runtime === "claude" || runtime === "both") {
    uninstallPlugin(pluginName);
  }

  if (runtime === "codex" || runtime === "both") {
    uninstallCodexPlugin(pluginName);
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
