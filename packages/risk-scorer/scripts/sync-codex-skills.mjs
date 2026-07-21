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

> Codex runtime note: use \`request_user_input\` only in Plan Mode where this skill needs structured user input. Outside Plan Mode, ask one concise direct question only when no safe assumption exists. If a step refers to Claude-style agent dispatch or \`subagent_type\`, use a native Codex subagent workflow: spawn the matching installed Codex custom agent when available, otherwise spawn the built-in \`default\` subagent and instruct it to read the plugin's sibling \`agents/*.md\` instructions in full before returning the same structured verdict block.

`;

const updatePolicyCodexAgentStep = `Run the Codex policy reviewer with this prompt:

> Review this draft risk policy for ISO 31000 compliance. Validate it.
>
> [paste the full draft policy content here]

Use a native Codex subagent workflow. Prefer the installed plugin agent named \`wr-risk-scorer:policy\` when available. In this source repo, the generated project-local alias \`wr-risk-scorer-policy\` may also be available for dogfooding. If neither custom agent is available in the current Codex session, spawn the built-in \`default\` subagent and instruct it to read \`agents/policy.md\` from this plugin in full before performing the review.`;

function transform(text) {
  return preamble + text
    .replaceAll("AskUserQuestion", "request_user_input")
    .replaceAll("`.claude/agents/risk-scorer-pipeline.md`", "`agents/pipeline.md`")
    .replace(
      `Run the risk-scorer agent (subagent_type: "risk-scorer") with this prompt:

> Review this draft risk policy for ISO 31000 compliance. Validate it.
>
> [paste the full draft policy content here]`,
      updatePolicyCodexAgentStep,
    );
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
