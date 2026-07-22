#!/usr/bin/env node

import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";
import { existsSync, readFileSync, rmSync } from "node:fs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const utils = await import(resolve(__dirname, "../lib/install-utils.mjs"));

const PLUGIN = "wr-cruise";
const DEPS = [];
const PACKAGE_ROOT = resolve(__dirname, "..");

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
  utils.run(`codex plugin marketplace add ${PACKAGE_ROOT}`, "Codex marketplace: windyroad-local");
  utils.run(`codex plugin add ${PLUGIN}@windyroad-local`, PLUGIN);
}

function codexUninstall() {
  utils.run(`codex plugin remove ${PLUGIN}`, `Removing ${PLUGIN}`);
  const cache = resolve(process.env.CODEX_HOME || resolve(homedir(), ".codex"), "quota-state.json");
  try {
    if (JSON.parse(readFileSync(cache, "utf8")).source === "codex-app-server") {
      rmSync(cache);
      rmSync(`${cache}.pace`, { force: true });
    }
  } catch {}
}

if (flags.uninstall) {
  if (flags.runtime === "claude" || flags.runtime === "both") {
    utils.uninstallPackage(PLUGIN, { runtime: "claude" });
  }
  if (flags.runtime === "codex" || flags.runtime === "both") codexUninstall();
} else if (flags.update) {
  if (flags.runtime === "claude" || flags.runtime === "both") {
    utils.updatePackage(PLUGIN, { scope: flags.scope, runtime: "claude" });
  }
  if (flags.runtime === "codex" || flags.runtime === "both") codexInstall();
} else if (flags.runtime === "codex") {
  console.log(`\nInstalling @windyroad/cruise (${flags.scope} scope)...\n`);
  codexInstall();
  console.log("\nDone! Restart Codex to activate.\n");
} else if (flags.runtime === "both") {
  utils.installPackage(PLUGIN, { deps: DEPS, scope: flags.scope, runtime: "claude" });
  codexInstall();
  console.log("\nDone! Restart Claude Code and Codex to activate.\n");
} else {
  utils.installPackage(PLUGIN, { deps: DEPS, scope: flags.scope, runtime: "claude" });
}
