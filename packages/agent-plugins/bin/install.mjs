#!/usr/bin/env node

import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const utils = await import(resolve(__dirname, "../lib/install-utils.mjs"));

const PLUGINS = [
  "wr-architect",
  "wr-risk-scorer",
  "wr-voice-tone",
  "wr-style-guide",
  "wr-jtbd",
  "wr-tdd",
  "wr-retrospective",
  "wr-problem",
  "wr-c4",
  "wr-wardley",
];

const HELP = `
Usage: npx @windyroad/agent-plugins [options]

Install, update, or uninstall all Windy Road AI agent plugins and skills.

Commands:
  (default)         Install all plugins and skills
  --update          Update marketplace and reinstall all plugins and skills
  --uninstall       Remove all plugins and skills

Options:
  --plugin <names>  Install only specific plugins (space-separated)
                    e.g. --plugin architect tdd risk-scorer
  --dry-run         Show what would be done without executing
  --help, -h        Show this help

Available plugins:
  architect, risk-scorer, voice-tone, style-guide, jtbd,
  tdd, problem, retrospective, c4, wardley

Examples:
  npx @windyroad/agent-plugins
  npx @windyroad/agent-plugins --plugin architect tdd risk-scorer
  npx @windyroad/agent-plugins --update
  npx @windyroad/agent-plugins --uninstall
`;

function parseArgs(argv) {
  const args = argv.slice(2);
  const flags = {
    help: false,
    uninstall: false,
    update: false,
    dryRun: false,
    plugins: null,
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case "--help":
      case "-h":
        flags.help = true;
        break;
      case "--uninstall":
        flags.uninstall = true;
        break;
      case "--update":
        flags.update = true;
        break;
      case "--dry-run":
        flags.dryRun = true;
        break;
      case "--plugin":
      case "--plugins": {
        flags.plugins = [];
        while (i + 1 < args.length && !args[i + 1].startsWith("--")) {
          i++;
          // Accept both "architect" and "wr-architect"
          const raw = args[i];
          const name = raw.startsWith("wr-") ? raw : `wr-${raw}`;
          if (PLUGINS.includes(name)) {
            flags.plugins.push(name);
          } else {
            const available = PLUGINS.map((p) => p.replace("wr-", "")).join(", ");
            console.error(`Unknown plugin: ${raw}\nAvailable: ${available}`);
            process.exit(1);
          }
        }
        if (flags.plugins.length === 0) {
          const available = PLUGINS.map((p) => p.replace("wr-", "")).join(", ");
          console.error(`--plugin requires at least one name.\nAvailable: ${available}`);
          process.exit(1);
        }
        break;
      }
      default:
        console.error(`Unknown option: ${args[i]}\n`);
        console.log(HELP);
        process.exit(1);
    }
  }

  return flags;
}

function doInstall(plugins) {
  console.log("\nInstalling Windy Road AI agent plugins...\n");

  console.log("[1/2] Adding marketplace...");
  utils.addMarketplace();

  console.log(`\n[2/2] Installing plugins (${plugins.length})...`);
  let installed = 0;
  for (const plugin of plugins) {
    if (utils.installPlugin(plugin)) installed++;
  }
  console.log(`  ${installed}/${plugins.length} plugins installed.`);

  console.log(`
Done! Restart Claude Code to activate all plugins.

Installed:
  - ${installed} plugins (agents, hooks, and skills)
  - Type /wr: to see skills in autocomplete

To update:    npx @windyroad/agent-plugins --update
To uninstall: npx @windyroad/agent-plugins --uninstall
`);
}

function doUpdate(plugins) {
  console.log("\nUpdating Windy Road AI agent plugins...\n");

  console.log("[1/2] Updating marketplace...");
  utils.run(
    `claude plugin marketplace update ${utils.MARKETPLACE_NAME}`,
    `Marketplace: ${utils.MARKETPLACE_NAME}`
  );

  console.log(`\n[2/2] Updating plugins (${plugins.length})...`);
  let updated = 0;
  for (const plugin of plugins) {
    if (utils.updatePlugin(plugin)) updated++;
  }
  console.log(`  ${updated}/${plugins.length} plugins updated.`);

  console.log("\nDone! Restart Claude Code to apply updates.\n");
}

function doUninstall(plugins) {
  console.log("\nUninstalling Windy Road plugins...\n");

  for (const plugin of plugins) {
    utils.uninstallPlugin(plugin);
  }

  console.log("\nDone. Restart Claude Code to apply changes.\n");
}

const flags = parseArgs(process.argv);

if (flags.help) {
  console.log(HELP);
  process.exit(0);
}

if (flags.dryRun) {
  utils.setDryRun(true);
  console.log("[dry-run mode — no commands will be executed]\n");
}

utils.checkPrerequisites();

const plugins = flags.plugins ?? PLUGINS;

if (flags.uninstall) {
  doUninstall(plugins);
} else if (flags.update) {
  doUpdate(plugins);
} else {
  doInstall(plugins);
}
