/**
 * Shared install utilities for @windyroad/* packages.
 * Used by both per-plugin installers and the meta-installer.
 */

import { execSync } from "node:child_process";

const MARKETPLACE_REPO = "windyroad/agent-plugins";
const MARKETPLACE_NAME = "windyroad";

let _dryRun = false;

export { MARKETPLACE_REPO, MARKETPLACE_NAME };

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

export function checkPrerequisites() {
  if (_dryRun) return;

  try {
    execSync("claude --version", { stdio: "pipe" });
  } catch {
    console.error(
      "Error: 'claude' CLI not found. Install Claude Code first:\n  https://docs.anthropic.com/en/docs/claude-code\n"
    );
    process.exit(1);
  }
}

export function addMarketplace() {
  return run(
    `claude plugin marketplace add ${MARKETPLACE_REPO}`,
    `Marketplace: ${MARKETPLACE_NAME}`
  );
}

export function installPlugin(pluginName, { scope = "project" } = {}) {
  return run(
    `claude plugin install ${pluginName}@${MARKETPLACE_NAME} --scope ${scope}`,
    pluginName
  );
}

export function updatePlugin(pluginName, { scope = "project" } = {}) {
  return run(
    `claude plugin update "${pluginName}@${MARKETPLACE_NAME}" --scope ${scope}`,
    pluginName
  );
}

export function uninstallPlugin(pluginName) {
  return run(`claude plugin uninstall ${pluginName}`, `Removing ${pluginName}`);
}

/**
 * Install a single package: marketplace add + plugin install.
 */
export function installPackage(pluginName, { deps = [], scope = "project" } = {}) {
  console.log(`\nInstalling @windyroad/${pluginName.replace("wr-", "")} (${scope} scope)...\n`);

  addMarketplace();
  installPlugin(pluginName, { scope });

  if (deps.length > 0) {
    console.log(`\nNote: This plugin works best with:`);
    for (const dep of deps) {
      console.log(`  - @windyroad/${dep.replace("wr-", "")} (npx @windyroad/${dep.replace("wr-", "")})`);
    }
  }

  console.log(
    `\nDone! Restart Claude Code to activate.\n`
  );
}

/**
 * Update a single package.
 */
export function updatePackage(pluginName, { scope = "project" } = {}) {
  console.log(`\nUpdating @windyroad/${pluginName.replace("wr-", "")}...\n`);

  run(
    `claude plugin marketplace update ${MARKETPLACE_NAME}`,
    "Updating marketplace"
  );
  updatePlugin(pluginName, { scope });

  console.log("\nDone! Restart Claude Code to apply updates.\n");
}

/**
 * Uninstall a single package.
 */
export function uninstallPackage(pluginName) {
  console.log(`\nUninstalling @windyroad/${pluginName.replace("wr-", "")}...\n`);

  uninstallPlugin(pluginName);

  console.log("\nDone. Restart Claude Code to apply changes.\n");
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
  return flags;
}
