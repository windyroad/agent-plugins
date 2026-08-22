#!/usr/bin/env node

import { execSync } from "node:child_process";
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync } from "node:fs";
import { homedir } from "node:os";
import { resolve, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const utils = await import(resolve(__dirname, "../lib/install-utils.mjs"));
const agents = await import(resolve(__dirname, "../scripts/codex-agent.mjs"));

const PLUGIN = "wr-itil";
const CODEX_MARKETPLACE = "windyroad-itil-local";
const DEPS = ["wr-risk-scorer"];
const PACKAGE_ROOT = resolve(__dirname, "..");
const PACKAGE_VERSION = JSON.parse(readFileSync(join(PACKAGE_ROOT, "package.json"), "utf8")).version;

function codexMarketplaceRoot() {
  const home = process.env.CODEX_HOME || join(homedir(), ".codex");
  return join(home, ".tmp", "marketplaces", `wr-itil-${PACKAGE_VERSION}`);
}

const flags = utils.parseStandardArgs(process.argv);

if (flags.runtime === "codex" || flags.runtime === "both") {
  const bundled = "/Applications/ChatGPT.app/Contents/Resources/codex";
  const binary = process.env.CODEX_BINARY || (existsSync(bundled) ? bundled : null);
  if (binary?.includes("/")) process.env.PATH = `${dirname(binary)}:${process.env.PATH || ""}`;
}

if (flags.help) {
  console.log(`
Usage: npx @windyroad/itil [options]

ITIL-aligned problem management with WSJF prioritisation

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

function warnMissingCodexDependency() {
  if (flags.dryRun) return;
  try {
    const installed = execSync("codex plugin list", { encoding: "utf8" });
    if (!installed.includes("wr-risk-scorer@")) {
      console.warn("Warning: wr-itil requires wr-risk-scorer; install @windyroad/risk-scorer for Codex.");
    }
  } catch {
    console.warn("Warning: could not verify the wr-risk-scorer Codex dependency.");
  }
}

function codexInstall() {
  const root = codexMarketplaceRoot();
  if (!flags.dryRun) {
    rmSync(root, { recursive: true, force: true });
    mkdirSync(dirname(root), { recursive: true });
    cpSync(PACKAGE_ROOT, root, { recursive: true });
    cpSync(join(root, "hooks-codex", "hooks.json"), join(root, "hooks", "hooks.json"));
  }
  if (!utils.run(`codex plugin marketplace add ${JSON.stringify(root)}`, `Codex marketplace: ${CODEX_MARKETPLACE}`)) return false;
  if (!utils.run(`codex plugin add ${PLUGIN}@${CODEX_MARKETPLACE}`, PLUGIN)) return false;
  if (!flags.dryRun) agents.installAgent(agents.agentDir(flags.scope));
  warnMissingCodexDependency();
  return true;
}

function codexUninstall() {
  const removed = utils.run(`codex plugin remove ${PLUGIN}@${CODEX_MARKETPLACE}`, `Removing ${PLUGIN}`);
  utils.run(`codex plugin marketplace remove ${CODEX_MARKETPLACE}`, `Removing ${CODEX_MARKETPLACE}`);
  if (!flags.dryRun) {
    for (const target of new Set([agents.agentDir(flags.scope), agents.agentDir("user")])) agents.uninstallAgent(target);
    rmSync(codexMarketplaceRoot(), { recursive: true, force: true });
  }
  return removed;
}

if (flags.uninstall) {
  if (flags.runtime === "claude" || flags.runtime === "both") utils.uninstallPackage(PLUGIN, { runtime: "claude" });
  if ((flags.runtime === "codex" || flags.runtime === "both") && !codexUninstall()) process.exit(1);
} else if (flags.update) {
  if (flags.runtime === "claude" || flags.runtime === "both") utils.updatePackage(PLUGIN, { scope: flags.scope, runtime: "claude" });
  if ((flags.runtime === "codex" || flags.runtime === "both") && !codexInstall()) process.exit(1);
} else if (flags.runtime === "codex") {
  console.log(`\nInstalling @windyroad/itil (${flags.scope} scope)...\n`);
  if (!codexInstall()) process.exit(1);
  console.log("\nDone! Restart Codex to activate.\n");
} else if (flags.runtime === "both") {
  utils.installPackage(PLUGIN, { deps: DEPS, scope: flags.scope, runtime: "claude" });
  if (!codexInstall()) process.exit(1);
  console.log("\nDone! Restart Claude Code and Codex to activate.\n");
} else {
  utils.installPackage(PLUGIN, { deps: DEPS, scope: flags.scope, runtime: "claude" });
}
