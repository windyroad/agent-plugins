#!/usr/bin/env node

import { resolve, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync } from "node:fs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const utils = await import(resolve(__dirname, "../lib/install-utils.mjs"));

const PLUGIN = "wr-cruise";
const CODEX_MARKETPLACE = "windyroad-local";
const DEPS = [];
const PACKAGE_ROOT = resolve(__dirname, "..");
const PACKAGE_VERSION = JSON.parse(readFileSync(join(PACKAGE_ROOT, "package.json"), "utf8")).version;

function marketplaceRoot() {
  const home = process.env.CODEX_HOME || join(homedir(), ".codex");
  return join(home, ".tmp", "marketplaces", `wr-cruise-${PACKAGE_VERSION}`);
}

const flags = utils.parseStandardArgs(process.argv);

if (flags.runtime === "codex" || flags.runtime === "both") {
  const bundled = "/Applications/ChatGPT.app/Contents/Resources/codex";
  const binary = process.env.CODEX_BINARY || (existsSync(bundled) ? bundled : null);
  if (binary?.includes("/")) process.env.PATH = `${dirname(binary)}:${process.env.PATH || ""}`;
}

if (flags.help) {
  console.log(`
Usage: npx @windyroad/cruise [options]

Mechanical token-quota pacing for Claude Code and Codex

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
  const root = marketplaceRoot();
  if (!flags.dryRun) {
    rmSync(root, { recursive: true, force: true });
    mkdirSync(dirname(root), { recursive: true });
    cpSync(PACKAGE_ROOT, root, { recursive: true });
  }
  if (!utils.run(`codex plugin marketplace add ${JSON.stringify(root)}`, `Codex marketplace: ${CODEX_MARKETPLACE}`)) return false;
  return utils.run(`codex plugin add ${PLUGIN}@${CODEX_MARKETPLACE}`, PLUGIN);
}

function codexUninstall() {
  const removed = utils.run(`codex plugin remove ${PLUGIN}@${CODEX_MARKETPLACE}`, `Removing ${PLUGIN}`);
  utils.run(`codex plugin marketplace remove ${CODEX_MARKETPLACE}`, `Removing ${CODEX_MARKETPLACE}`);
  if (!flags.dryRun) rmSync(marketplaceRoot(), { recursive: true, force: true });
  const cache = resolve(process.env.CODEX_HOME || resolve(homedir(), ".codex"), "quota-state.json");
  try {
    if (JSON.parse(readFileSync(cache, "utf8")).source === "codex-app-server") {
      rmSync(cache);
      rmSync(`${cache}.pace`, { force: true });
    }
  } catch {}
  return removed;
}

if (flags.uninstall) {
  if (flags.runtime === "claude" || flags.runtime === "both") {
    utils.uninstallPackage(PLUGIN, { runtime: "claude" });
  }
  if ((flags.runtime === "codex" || flags.runtime === "both") && !codexUninstall()) process.exit(1);
} else if (flags.update) {
  if (flags.runtime === "claude" || flags.runtime === "both") {
    utils.updatePackage(PLUGIN, { scope: flags.scope, runtime: "claude" });
  }
  if ((flags.runtime === "codex" || flags.runtime === "both") && !codexInstall()) process.exit(1);
} else if (flags.runtime === "codex") {
  console.log(`\nInstalling @windyroad/cruise (${flags.scope} scope)...\n`);
  if (!codexInstall()) process.exit(1);
  console.log("\nDone! Restart Codex to activate.\n");
} else if (flags.runtime === "both") {
  utils.installPackage(PLUGIN, { deps: DEPS, scope: flags.scope, runtime: "claude" });
  if (!codexInstall()) process.exit(1);
  console.log("\nDone! Restart Claude Code and Codex to activate.\n");
} else {
  utils.installPackage(PLUGIN, { deps: DEPS, scope: flags.scope, runtime: "claude" });
}
