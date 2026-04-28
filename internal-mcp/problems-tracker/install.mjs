#!/usr/bin/env node
// Idempotent installer — adds (or updates) the `problems-tracker` MCP server
// entry in Claude desktop's config. Safe to run repeatedly.
//
// Usage:  node install.mjs
//         node install.mjs --uninstall
//         node install.mjs --config /path/to/some_other_config.json

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';

const HERE = dirname(fileURLToPath(import.meta.url));
const SERVER_PATH = resolve(HERE, 'server.mjs');
const SERVER_KEY = 'problems-tracker';

// Use the absolute path to the Node binary running this installer.
// The Claude desktop GUI spawns subprocesses with a minimal PATH (often just
// /usr/bin:/bin) and won't find `node` if it's installed via Homebrew (/opt/
// homebrew/bin) or nvm (~/.nvm/versions/...). Hardcoding `process.execPath`
// makes the registration immune to that.
const NODE_BIN = process.execPath;

const args = new Set(process.argv.slice(2));
let configPath = process.env.CLAUDE_CONFIG ||
  resolve(homedir(), 'Library/Application Support/Claude/claude_desktop_config.json');

// Allow --config <path>
const argv = process.argv.slice(2);
const cIdx = argv.indexOf('--config');
if (cIdx >= 0 && argv[cIdx + 1]) configPath = resolve(argv[cIdx + 1]);

const uninstall = args.has('--uninstall');

const desiredEntry = {
  command: NODE_BIN,
  args: [SERVER_PATH],
};

function loadConfig() {
  if (!existsSync(configPath)) return {};
  const raw = readFileSync(configPath, 'utf8');
  if (!raw.trim()) return {};
  try {
    return JSON.parse(raw);
  } catch (e) {
    throw new Error(`Existing config at ${configPath} is not valid JSON: ${e.message}`);
  }
}

function entriesMatch(a, b) {
  return a && b &&
    a.command === b.command &&
    JSON.stringify(a.args || []) === JSON.stringify(b.args || []);
}

function saveConfig(cfg) {
  mkdirSync(dirname(configPath), { recursive: true });
  writeFileSync(configPath, JSON.stringify(cfg, null, 2) + '\n', 'utf8');
}

const cfg = loadConfig();
cfg.mcpServers = cfg.mcpServers || {};
const existing = cfg.mcpServers[SERVER_KEY];

if (uninstall) {
  if (!existing) {
    console.log(`No '${SERVER_KEY}' entry in ${configPath}. Nothing to do.`);
    process.exit(0);
  }
  delete cfg.mcpServers[SERVER_KEY];
  saveConfig(cfg);
  console.log(`Removed '${SERVER_KEY}' from ${configPath}.`);
  console.log('Quit and reopen the Claude desktop app to apply.');
  process.exit(0);
}

if (entriesMatch(existing, desiredEntry)) {
  console.log(`'${SERVER_KEY}' already installed at ${configPath}. No change.`);
  process.exit(0);
}

cfg.mcpServers[SERVER_KEY] = desiredEntry;
saveConfig(cfg);

const verb = existing ? 'Updated' : 'Added';
console.log(`${verb} '${SERVER_KEY}' in ${configPath}.`);
console.log(`Server path: ${SERVER_PATH}`);
console.log('');
console.log('Next: quit and reopen the Claude desktop app, then reload the open-problems artifact.');
