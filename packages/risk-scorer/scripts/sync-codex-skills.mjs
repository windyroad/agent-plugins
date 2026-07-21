#!/usr/bin/env node

import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const packageRoot = resolve(__dirname, "..");
const skillsRoot = join(packageRoot, "skills");
const backupRoot = join(packageRoot, ".pack-claude-skills");
const mode = process.argv.includes("--check") ? "check" : "sync";
const packMode = process.argv.includes("--pack");
const restoreMode = process.argv.includes("--restore-pack");

const preamble = `<!-- Generated from packages/risk-scorer/skills/*/SKILL.md by packages/risk-scorer/scripts/sync-codex-skills.mjs during npm pack. Do not edit packaged output directly. -->

> Codex runtime note: use \`request_user_input\` where this skill needs structured user input. If a step refers to Claude-style agent dispatch or \`subagent_type\`, invoke the matching installed Codex agent when available; in \`codex exec\` or any runtime without custom-agent dispatch, perform the same review inline from the plugin's sibling \`agents/*.md\` instructions and preserve the structured verdict blocks.

`;

function transform(text) {
  return preamble + text
    .replaceAll("AskUserQuestion", "request_user_input")
    .replaceAll("`.claude/agents/risk-scorer-pipeline.md`", "`agents/pipeline.md`");
}

function generatedFiles(sourceRoot, targetRoot) {
  const entries = readdirSync(sourceRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();

  const generated = [];
  for (const entry of entries) {
    const source = join(sourceRoot, entry, "SKILL.md");
    if (!existsSync(source)) {
      continue;
    }
    generated.push({
      path: join(targetRoot, entry, "SKILL.md"),
      text: transform(readFileSync(source, "utf8")),
    });
  }
  return generated;
}

function writeGenerated(sourceRoot, targetRoot) {
  const generated = generatedFiles(sourceRoot, targetRoot);
  rmSync(targetRoot, { recursive: true, force: true });
  for (const { path, text } of generated) {
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, text, "utf8");
  }
  return generated.length;
}

if (restoreMode) {
  if (existsSync(backupRoot)) {
    rmSync(skillsRoot, { recursive: true, force: true });
    renameSync(backupRoot, skillsRoot);
    console.log("Restored Claude skill source after pack.");
  }
  process.exit(0);
}

if (packMode) {
  if (existsSync(backupRoot)) {
    console.error(`Refusing to pack: backup already exists at ${backupRoot}`);
    process.exit(1);
  }
  renameSync(skillsRoot, backupRoot);
  const count = writeGenerated(backupRoot, skillsRoot);
  console.log(`Packed ${count} Codex-facing risk-scorer skill file(s).`);
  process.exit(0);
}

console.error("Usage: sync-codex-skills.mjs --pack | --restore-pack");
process.exit(mode === "check" ? 0 : 2);
