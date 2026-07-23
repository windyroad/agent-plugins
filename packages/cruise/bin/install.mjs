#!/usr/bin/env node

import { resolve, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";
import { execFileSync } from "node:child_process";
import { cpSync, existsSync, mkdirSync, readFileSync, realpathSync, renameSync, rmSync, writeFileSync } from "node:fs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const utils = await import(resolve(__dirname, "../lib/install-utils.mjs"));

const PLUGIN = "wr-cruise";
const CODEX_MARKETPLACE = "windyroad-local";
const DEPS = [];
const PACKAGE_ROOT = resolve(__dirname, "..");
const PACKAGE_VERSION = JSON.parse(readFileSync(join(PACKAGE_ROOT, "package.json"), "utf8")).version;
const CODEX_HOME = process.env.CODEX_HOME || join(homedir(), ".codex");
const CODEX_CONFIG = join(CODEX_HOME, "cruise.config.json");

function configuredCodexBinary() {
  try {
    const value = JSON.parse(readFileSync(CODEX_CONFIG, "utf8")).codex_binary;
    return typeof value === "string" && value ? value : null;
  } catch {
    return null;
  }
}

function resolveCodexBinary(probe) {
  const candidates = [
    process.env.CODEX_BINARY,
    configuredCodexBinary(),
    "/Applications/Codex.app/Contents/Resources/codex",
    "/Applications/ChatGPT.app/Contents/Resources/codex",
  ];
  try {
    candidates.push(execFileSync("which", ["codex"], { encoding: "utf8" }).trim());
  } catch {}
  for (const candidate of candidates) {
    if (!candidate || !existsSync(candidate)) continue;
    const binary = realpathSync(candidate);
    if (!probe) return binary;
    try {
      execFileSync(binary, ["--version"], { stdio: "pipe" });
      return binary;
    } catch {}
  }
  return null;
}

function updateCodexConfig(binary) {
  if (flags.dryRun) return true;
  let config = {};
  if (existsSync(CODEX_CONFIG)) {
    try {
      config = JSON.parse(readFileSync(CODEX_CONFIG, "utf8"));
      if (!config || Array.isArray(config) || typeof config !== "object") throw new Error("not an object");
    } catch {
      console.error(`  FAILED: ${CODEX_CONFIG} is not valid JSON; preserving it unchanged`);
      return false;
    }
  }
  if (binary) config.codex_binary = binary;
  else delete config.codex_binary;
  mkdirSync(dirname(CODEX_CONFIG), { recursive: true });
  if (!Object.keys(config).length) {
    rmSync(CODEX_CONFIG, { force: true });
    return true;
  }
  const temporary = `${CODEX_CONFIG}.${process.pid}.tmp`;
  writeFileSync(temporary, `${JSON.stringify(config, null, 2)}\n`, { mode: 0o600 });
  renameSync(temporary, CODEX_CONFIG);
  return true;
}

function marketplaceRoot() {
  const home = process.env.CODEX_HOME || join(homedir(), ".codex");
  return join(home, ".tmp", "marketplaces", `wr-cruise-${PACKAGE_VERSION}`);
}

const flags = utils.parseStandardArgs(process.argv);
const codexBinary = flags.runtime === "codex" || flags.runtime === "both" ? resolveCodexBinary(!flags.dryRun) : null;
const codexCommand = JSON.stringify(codexBinary || "codex");

if (flags.runtime === "codex" || flags.runtime === "both") {
  if (codexBinary) process.env.PATH = `${dirname(codexBinary)}:${process.env.PATH || ""}`;
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

if (flags.runtime === "claude" || flags.runtime === "both") {
  utils.checkPrerequisites({ runtime: "claude" });
}
if ((flags.runtime === "codex" || flags.runtime === "both") && !flags.dryRun) {
  if (!codexBinary) {
    console.error("Error: Codex CLI not found or unusable. Install Codex CLI first:\n  https://developers.openai.com/codex\n");
    process.exit(1);
  }
}

function codexInstall() {
  const root = marketplaceRoot();
  if (!flags.dryRun) {
    rmSync(root, { recursive: true, force: true });
    mkdirSync(dirname(root), { recursive: true });
    cpSync(PACKAGE_ROOT, root, { recursive: true });
  }
  if (!utils.run(`${codexCommand} plugin marketplace add ${JSON.stringify(root)}`, `Codex marketplace: ${CODEX_MARKETPLACE}`)) return false;
  if (!utils.run(`${codexCommand} plugin add ${PLUGIN}@${CODEX_MARKETPLACE}`, PLUGIN)) return false;
  return updateCodexConfig(codexBinary);
}

function codexUninstall() {
  const removed = utils.run(`${codexCommand} plugin remove ${PLUGIN}@${CODEX_MARKETPLACE}`, `Removing ${PLUGIN}`);
  if (!removed) return false;
  utils.run(`${codexCommand} plugin marketplace remove ${CODEX_MARKETPLACE}`, `Removing ${CODEX_MARKETPLACE}`);
  if (flags.dryRun) return true;
  rmSync(marketplaceRoot(), { recursive: true, force: true });
  const cache = resolve(process.env.CODEX_HOME || resolve(homedir(), ".codex"), "quota-state.json");
  try {
    if (JSON.parse(readFileSync(cache, "utf8")).source === "codex-app-server") {
      rmSync(cache);
      rmSync(`${cache}.pace`, { force: true });
    }
  } catch {}
  rmSync(resolve(CODEX_HOME, "quota-state.error.json"), { force: true });
  return updateCodexConfig(null) && removed;
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
