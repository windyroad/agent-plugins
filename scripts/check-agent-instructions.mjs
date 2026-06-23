#!/usr/bin/env node
// Lightweight drift guard for the shared human/agent behavioral rules that
// must stay aligned across Claude Code and Codex runtime instruction files.

import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, "..");

const files = {
  shared: join(REPO_ROOT, "docs", "agent-instructions", "shared-governance.md"),
  claude: join(REPO_ROOT, "CLAUDE.md"),
  codex: join(REPO_ROOT, "AGENTS.md"),
};

const contents = Object.fromEntries(
  Object.entries(files).map(([key, path]) => [key, readFileSync(path, "utf8").toLowerCase()]),
);

const checks = [
  ["shared", "act on obvious"],
  ["shared", "capture on correction"],
  ["shared", "project-generated artefacts"],
  ["shared", "mechanical"],
  ["shared", "substance ratification"],
  ["claude", "AskUserQuestion"],
  ["claude", ".claude/"],
  ["codex", "request_user_input"],
  ["codex", "Plan Mode"],
  ["codex", ".codex/"],
];

const missing = checks.filter(([file, token]) => !contents[file].includes(token.toLowerCase()));

if (missing.length > 0) {
  for (const [file, token] of missing) {
    console.error(`MISSING: ${file} instruction file does not contain ${JSON.stringify(token)}`);
  }
  console.error("");
  console.error("ERROR: agent instruction drift guard failed.");
  process.exit(1);
}

console.log("OK: shared Claude/Codex instruction guard tokens are present");
