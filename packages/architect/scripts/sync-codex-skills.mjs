#!/usr/bin/env node

import {
  cpSync,
  existsSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const skillsRoot = join(packageRoot, "skills");
const backupRoot = join(packageRoot, ".pack-claude-skills");

const preamble = `<!-- Generated from the Claude skill source during npm pack. -->

> Codex runtime note: use \`request_user_input\` in Plan Mode for structured
> questions. Resolve \`<architect-plugin-root>\` from this installed
> \`SKILL.md\` path: it is two directories above the skill directory. Replace
> that token with the absolute path before running a bundled script; never
> search the adopter repository or rely on a \`wr-architect-*\` command being
> on \`PATH\`. Spawn the installed \`wr-architect:agent\` custom agent with the
> native Codex subagent tool, wait for it, and close the same agent.

`;

const commands = new Map([
  ["wr-architect-detect-unoversighted", "bash \"<architect-plugin-root>/scripts/detect-unoversighted.sh\""],
  ["wr-architect-generate-decisions-compendium", "bash \"<architect-plugin-root>/scripts/generate-decisions-compendium.sh\""],
  ["wr-architect-is-decision-unconfirmed", "bash \"<architect-plugin-root>/scripts/is-decision-unconfirmed.sh\""],
  ["wr-architect-mark-oversight-confirmed", "bash \"<architect-plugin-root>/scripts/mark-oversight-confirmed.sh\""],
]);

function transform(text) {
  let result = text.replaceAll("AskUserQuestion", "request_user_input");
  for (const [command, replacement] of commands) {
    result = result.replaceAll(command, replacement);
  }
  result = result.replaceAll("packages/architect/", "<architect-plugin-root>/");
  result = result.replace(
    "is a `$PATH`-resolved shim (ADR-049 naming grammar) dispatching `<architect-plugin-root>/scripts/",
    "is the bundled Codex script at `<architect-plugin-root>/scripts/",
  );
  if (!result.startsWith("---\n")) return preamble + result;
  const end = result.indexOf("\n---\n", 4);
  return end === -1
    ? preamble + result
    : result.slice(0, end + 5) + "\n" + preamble + result.slice(end + 5);
}

function skillFiles(root) {
  return readdirSync(root, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => join(root, entry.name, "SKILL.md"))
    .filter(existsSync);
}

if (process.argv.includes("--restore-pack")) {
  if (existsSync(backupRoot)) {
    rmSync(skillsRoot, { recursive: true, force: true });
    renameSync(backupRoot, skillsRoot);
    console.log("Restored Claude architect skill source after pack.");
  }
  process.exit(0);
}

if (!process.argv.includes("--pack")) {
  console.error("Usage: sync-codex-skills.mjs --pack | --restore-pack");
  process.exit(2);
}

if (existsSync(backupRoot)) {
  console.error(`Refusing to pack: backup already exists at ${backupRoot}`);
  process.exit(1);
}

renameSync(skillsRoot, backupRoot);
cpSync(backupRoot, skillsRoot, { recursive: true });
const files = skillFiles(skillsRoot);
for (const file of files) writeFileSync(file, transform(readFileSync(file, "utf8")), "utf8");
console.log(`Packed ${files.length} Codex-facing architect skill file(s).`);
