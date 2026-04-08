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

  try {
    execSync("npx --version", { stdio: "pipe" });
  } catch {
    console.error(
      "Error: 'npx' not found. Install Node.js first:\n  https://nodejs.org\n"
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

export function installPlugin(pluginName) {
  return run(
    `claude plugin install ${pluginName}@${MARKETPLACE_NAME}`,
    pluginName
  );
}

export function updatePlugin(pluginName) {
  return run(`claude plugin update ${pluginName}`, pluginName);
}

export function uninstallPlugin(pluginName) {
  return run(`claude plugin uninstall ${pluginName}`, `Removing ${pluginName}`);
}

export function installSkills() {
  return run(
    `npx -y skills add --yes --all ${MARKETPLACE_REPO}`,
    "Skills (via skills package)"
  );
}

export function updateSkills() {
  return run("npx -y skills update", "Skills update");
}

export function removeSkills() {
  return run(
    `npx -y skills remove --yes --all ${MARKETPLACE_REPO}`,
    "Removing skills"
  );
}

/**
 * Install a single package: marketplace add + plugin install + skills.
 */
export function installPackage(pluginName, { deps = [] } = {}) {
  console.log(`\nInstalling @windyroad/${pluginName.replace("wr-", "")}...\n`);

  addMarketplace();
  installPlugin(pluginName);
  installSkills();

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
export function updatePackage(pluginName) {
  console.log(`\nUpdating @windyroad/${pluginName.replace("wr-", "")}...\n`);

  run(
    `claude plugin marketplace update ${MARKETPLACE_NAME}`,
    "Updating marketplace"
  );
  updatePlugin(pluginName);
  updateSkills();

  console.log("\nDone! Restart Claude Code to apply updates.\n");
}

/**
 * Uninstall a single package.
 */
export function uninstallPackage(pluginName) {
  console.log(`\nUninstalling @windyroad/${pluginName.replace("wr-", "")}...\n`);

  uninstallPlugin(pluginName);

  console.log("\nDone. Restart Claude Code to apply changes.\n");
  console.log("Note: Skills are shared across packages. Run");
  console.log("  npx @windyroad/agent-plugins --uninstall");
  console.log("to remove all skills.\n");
}

/**
 * Parse standard flags used by all per-plugin installers.
 */
export function parseStandardArgs(argv) {
  const args = argv.slice(2);
  return {
    help: args.includes("--help") || args.includes("-h"),
    uninstall: args.includes("--uninstall"),
    update: args.includes("--update"),
    dryRun: args.includes("--dry-run"),
  };
}
