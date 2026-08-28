#!/usr/bin/env node

import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const utils = await import(resolve(__dirname, "../lib/install-utils.mjs"));

const PLUGIN = "wr-retrospective";
const DEPS = ["wr-itil", "wr-risk-scorer"];
const AGENTS = [];

const flags = utils.parseStandardArgs(process.argv);

if (flags.help) {
  console.log(`
Usage: npx @windyroad/retrospective [options]

Session retrospectives that update briefings and create problem tickets

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

if (flags.uninstall) {
  utils.uninstallPackage(PLUGIN, { agents: AGENTS, scope: flags.scope, runtime: flags.runtime });
} else if (flags.update) {
  utils.updatePackage(PLUGIN, { agents: AGENTS, scope: flags.scope, runtime: flags.runtime });
} else {
  utils.installPackage(PLUGIN, { agents: AGENTS, deps: DEPS, scope: flags.scope, runtime: flags.runtime });
}
