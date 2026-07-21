#!/usr/bin/env node

import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const utils = await import(resolve(__dirname, "../lib/install-utils.mjs"));

const PLUGIN = "wr-risk-scorer";
const DEPS = [];
const PACKAGE_ROOT = resolve(__dirname, "..");

const flags = utils.parseStandardArgs(process.argv);

if (flags.help) {
  console.log(`
Usage: npx @windyroad/risk-scorer [options]

Pipeline risk scoring, commit/push gates, and secret leak detection

Options:
  --update     Update this plugin and its skills
  --uninstall  Remove this plugin
  --scope      Installation scope: project (default) or user
  --runtime    Runtime to install for: claude (default), codex, or both
  --dry-run    Show what would be done without executing
  --help, -h   Show this help
`);
  process.exit(0);
}

if (flags.dryRun) {
  utils.setDryRun(true);
  console.log("[dry-run mode — no commands will be executed]\n");
}

utils.checkPrerequisites({ runtime: flags.runtime });

function codexInstall() {
  utils.run(`codex plugin marketplace add ${PACKAGE_ROOT}`, "Codex marketplace: windyroad-local");
  utils.run(`codex plugin add ${PLUGIN}@windyroad-local`, PLUGIN);
}

function codexUninstall() {
  utils.run(`codex plugin remove ${PLUGIN}`, `Removing ${PLUGIN}`);
}

if (flags.uninstall) {
  if (flags.runtime === "claude" || flags.runtime === "both") {
    utils.uninstallPackage(PLUGIN, { runtime: "claude" });
  }
  if (flags.runtime === "codex" || flags.runtime === "both") {
    codexUninstall();
  }
} else if (flags.update) {
  if (flags.runtime === "claude" || flags.runtime === "both") {
    utils.updatePackage(PLUGIN, { scope: flags.scope, runtime: "claude" });
  }
  if (flags.runtime === "codex" || flags.runtime === "both") {
    codexInstall();
  }
} else if (flags.runtime === "codex") {
  console.log(`\nInstalling @windyroad/risk-scorer (${flags.scope} scope)...\n`);
  codexInstall();
  console.log("\nDone! Restart Codex to activate.\n");
} else if (flags.runtime === "both") {
  utils.installPackage(PLUGIN, { deps: DEPS, scope: flags.scope, runtime: "claude" });
  codexInstall();
  console.log("\nDone! Restart Claude Code and Codex to activate.\n");
} else {
  utils.installPackage(PLUGIN, { deps: DEPS, scope: flags.scope, runtime: "claude" });
}
