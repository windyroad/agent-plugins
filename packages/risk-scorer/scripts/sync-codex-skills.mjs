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

> Codex runtime note: use \`request_user_input\` only when this contract requires
> a human decision. Prefer the installed \`wr-risk-scorer:<mode>\` reviewer.
> If unavailable, or the native tool cannot select a named reviewer, use an
> independent general/default subagent with \`fork_turns: "none"\`. Prepare its
> complete message with \`node "<plugin-root>/scripts/codex-agents.mjs" --fallback-prompt <mode> < request.txt\`.
> Resolve \`<plugin-root>\` from this installed skill, two directories above
> the skill directory. The command includes the complete installed reviewer
> instructions, runtime requirements and original request. Pass its output
> verbatim as the subagent message; omit \`agent_type\` if unsupported.
> Keep the review read-only. Wait for completion, then call \`interrupt_agent\`
> once on that completed child so the normal hooks process its result. A FAIL
> requires remediation, not fallback. Never write markers manually, parse
> transcripts, launch nested \`codex exec\` or claim success without completion evidence.

`;

const updatePolicyCodexAgentStep = `Run the Codex policy reviewer with this prompt:

> Review this draft risk policy for ISO 31000 compliance. Validate it.
>
> [paste the full draft policy content here]

Use the installed \`wr-risk-scorer:policy\` reviewer when available. Otherwise use the instruction-backed general-reviewer fallback above with mode \`policy\`.`;

// Codex namespaces every skill by the plugin manifest `name`, so a skill's own
// frontmatter `name:` must be BARE or the prefix lands twice and the advertised
// invocation cannot be typed (P527). Scoped to the frontmatter block so a body
// line starting `name:` is never rewritten.
function bareName(skill, text) {
  if (!text.startsWith("---\n")) return text;
  const end = text.indexOf("\n---\n", 4);
  if (end === -1) return text;
  return text.slice(0, end).replace(/^name:.*$/m, `name: ${skill}`) + text.slice(end);
}

function transform(skill, text) {
  const transformed = bareName(skill, text)
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
      text: transform(entry, readFileSync(source, "utf8")),
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
