#!/usr/bin/env node

import {
  copyFileSync,
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

> Codex runtime note: use \`request_user_input\` only in Plan Mode where this skill needs structured user input. Outside Plan Mode, ask one concise direct question only when no safe assumption exists. If a step refers to Claude-style agent dispatch or \`subagent_type\`, use a native Codex subagent workflow and spawn the matching installed \`wr-risk-scorer:<mode>\` custom agent. Wait for it, then close that same agent so the completion hook receives its final response. Do not substitute the built-in \`default\` agent when a hook consumes the subagent identity; restart Codex if the installed agent is not yet visible.

`;

const updatePolicyCodexAgentStep = `Run the Codex policy reviewer with this prompt:

> Review this draft risk policy for ISO 31000 compliance. Validate it.
>
> [paste the full draft policy content here]

Use a native Codex subagent workflow with the installed custom agent named \`wr-risk-scorer:policy\`. If it is not visible in the current session, restart Codex; do not substitute a different agent identity because the policy marker hook consumes it.`;

function transform(text) {
  const transformed = text
    .replaceAll("AskUserQuestion", "request_user_input")
    .replaceAll("`.claude/agents/risk-scorer-pipeline.md`", "`agents/pipeline.md`")
    .replace(
      `Run the risk-scorer agent (subagent_type: "risk-scorer") with this prompt:

> Review this draft risk policy for ISO 31000 compliance. Validate it.
>
> [paste the full draft policy content here]`,
      updatePolicyCodexAgentStep,
    );
  if (!transformed.startsWith("---\n")) return preamble + transformed;
  const frontmatterEnd = transformed.indexOf("\n---\n", 4);
  if (frontmatterEnd === -1) return preamble + transformed;
  const bodyStart = frontmatterEnd + 5;
  return transformed.slice(0, bodyStart) + "\n" + preamble + transformed.slice(bodyStart);
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
  for (const entry of readdirSync(sourceRoot, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const source = join(sourceRoot, entry.name, "agents", "openai.yaml");
    if (!existsSync(source)) continue;
    const target = join(targetRoot, entry.name, "agents", "openai.yaml");
    mkdirSync(dirname(target), { recursive: true });
    copyFileSync(source, target);
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
