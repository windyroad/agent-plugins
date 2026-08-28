#!/usr/bin/env node

import {
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const skillsRoot = join(packageRoot, "skills");
const backupRoot = join(packageRoot, ".pack-claude-skills");
const publishedBackupRoot = join(packageRoot, ".pack-published-source");

const internalId = /\b(?:ADR-\d{3,}|P-?\d{3}|RFC-\d{3,}|JTBD-\d{3,}|STORY(?:-MAP)?-\d{3,}|R-?\d{3})\b/g;
const publicReferences = new Map([
  ["ADR-009", "session-scoped marker lifecycle rule"],
  ["ADR-013", "structured governance interaction rule"],
  ["ADR-014", "governance skills commit completed work rule"],
  ["ADR-017", "synced per-package shared-code rule"],
  ["ADR-018", "inter-iteration release cadence rule"],
  ["ADR-019", "clean-checkout AFK preflight rule"],
  ["ADR-020", "queued-changeset auto-release rule"],
  ["ADR-023", "runtime-path performance review rule"],
  ["ADR-026", "grounded agent-output rule"],
  ["ADR-031", "state-based problem-directory layout rule"],
  ["ADR-032", "governance-skill invocation rule"],
  ["ADR-038", "progressive governance disclosure budget"],
  ["ADR-040", "session-start briefing rule"],
  ["ADR-044", "decision-delegation rule"],
  ["ADR-045", "hook injection budget"],
  ["ADR-049", "installed script resolution rule"],
  ["ADR-052", "behavioural skill-testing rule"],
  ["ADR-056", "risk-register back-channel write contract"],
  ["ADR-064", "Needs-Direction handoff rule"],
  ["ADR-066", "architecture human-oversight rule"],
  ["ADR-067", "evidence-based effort estimation rule"],
  ["ADR-072", "propose-fix RFC requirement"],
  ["ADR-074", "ratify substance before dependent work rule"],
  ["ADR-077", "decisions-compendium load rule"],
  ["ADR-078", "per-edit compendium update rule"],
  ["ADR-110", "genuine ratification marker rule"],
  ["JTBD-001", "automated governance user outcome"],
  ["JTBD-006", "unattended backlog progress user outcome"],
  ["P-014", "missing lightweight governance-capture problem"],
  ["P-017", "multi-decision ADR intake failure"],
  ["P-040", "stale-origin preflight failure"],
  ["P-056", "next-ID origin lookup failure"],
  ["P-057", "rename-and-stage ordering failure"],
  ["P-078", "missed strong-correction capture failure"],
  ["P-088", "context-blind retrospective failure"],
  ["P-132", "mechanical-stage over-asking failure"],
  ["P-137", "unresolved published-reference failure"],
  ["P-155", "lightweight problem-capture requirement"],
  ["P-156", "lightweight ADR-capture requirement"],
  ["P-157", "pending-question startup surface requirement"],
  ["P-283", "unpinned architecture direction requirement"],
  ["P-302", "outcome-first ratification briefing requirement"],
  ["P-313", "pre-edit review catch-22"],
  ["P-315", "unratified dependent-work failure"],
  ["P-316", "rejected-decision drain recurrence"],
  ["P-327", "full-corpus context-cost problem"],
  ["P-339", "option-selection-before-drafting requirement"],
  ["P-340", "substance-confirmation evidence requirement"],
  ["P-348", "false human-oversight marker failure"],
  ["P-350", "opaque-identifier briefing failure"],
  ["P-352", "AFK question queue-and-continue rule"],
  ["P-354", "outcome-shaped ADR title requirement"],
  ["P-375", "self-firing cadence requirement"],
  ["RFC-045", "full-substance capture implementation design"],
]);

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
  let result = bareName(skill, text).replaceAll("AskUserQuestion", "request_user_input");
  for (const [command, replacement] of commands) {
    result = result.replaceAll(command, replacement);
  }
  result = result.replaceAll("packages/architect/", "<architect-plugin-root>/");
  result = result.replace(
    /is a `\$PATH`-resolved shim \([^)]* naming grammar\) dispatching `<architect-plugin-root>\/scripts\//,
    "is the bundled Codex script at `<architect-plugin-root>/scripts/",
  );
  if (!result.startsWith("---\n")) return preamble + result;
  const end = result.indexOf("\n---\n", 4);
  return end === -1
    ? preamble + result
    : result.slice(0, end + 5) + "\n" + preamble + result.slice(end + 5);
}

function artefactKey(id) {
  const match = id.match(/^(STORY-MAP|STORY|ADR|RFC|JTBD|P|R)-?(\d+)$/);
  return match ? `${match[1]}-${match[2]}` : id;
}

function stripInternalIds(text) {
  return text
    .replace(new RegExp(`${internalId.source}\\s*\\([^()\\n]+\\)`, "g"), (reference) => {
      const id = reference.match(internalId)?.[0];
      const label = publicReferences.get(artefactKey(id));
      if (!label) throw new Error(`No public rule label for ${id}`);
      return `the ${label}`;
    })
    .replace(internalId, (id) => {
      const label = publicReferences.get(artefactKey(id));
      if (!label) throw new Error(`No public rule label for ${id}`);
      return `the ${label}`;
    })
    .replaceAll("The the ", "The ")
    .replaceAll("the the ", "the ")
    .replaceAll("inverse-the ", "inverse ")
    .replaceAll(
      "the mechanical-stage over-asking failure inverse missed strong-correction capture failure guard",
      "the inverse over-ask guard",
    );
}

function walkFiles(root) {
  if (!existsSync(root)) return [];
  return readdirSync(root, { withFileTypes: true }).flatMap((entry) => {
    const path = join(root, entry.name);
    return entry.isDirectory() ? walkFiles(path) : [path];
  });
}

function backupAndSanitize(file, sanitizer) {
  const relative = file.slice(packageRoot.length + 1);
  const backup = join(publishedBackupRoot, relative);
  mkdirSync(dirname(backup), { recursive: true });
  cpSync(file, backup);
  writeFileSync(file, sanitizer(readFileSync(file, "utf8")), "utf8");
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
  if (existsSync(publishedBackupRoot)) {
    for (const backup of walkFiles(publishedBackupRoot)) {
      const relative = backup.slice(publishedBackupRoot.length + 1);
      cpSync(backup, join(packageRoot, relative));
    }
    rmSync(publishedBackupRoot, { recursive: true, force: true });
    console.log("Restored architect published source after pack.");
  }
  process.exit(0);
}

if (!process.argv.includes("--pack")) {
  console.error("Usage: sync-codex-skills.mjs --pack | --restore-pack");
  process.exit(2);
}

if (existsSync(backupRoot) || existsSync(publishedBackupRoot)) {
  console.error("Refusing to pack: a pack backup already exists");
  process.exit(1);
}

for (const file of [
  ...walkFiles(skillsRoot).filter((path) => path.endsWith(".md")),
  join(packageRoot, "README.md"),
  ...walkFiles(join(packageRoot, "agents")).filter((path) => path.endsWith(".md")),
]) {
  stripInternalIds(readFileSync(file, "utf8"));
}

renameSync(skillsRoot, backupRoot);
cpSync(backupRoot, skillsRoot, { recursive: true });
const files = skillFiles(skillsRoot);
for (const file of files) {
  const skill = basename(dirname(file));
  writeFileSync(file, stripInternalIds(transform(skill, readFileSync(file, "utf8"))), "utf8");
}
for (const file of walkFiles(skillsRoot).filter((file) => file.endsWith(".md") && !files.includes(file))) {
  writeFileSync(file, stripInternalIds(readFileSync(file, "utf8")), "utf8");
}

for (const file of [join(packageRoot, "README.md"), ...walkFiles(join(packageRoot, "agents")).filter((file) => file.endsWith(".md"))]) {
  backupAndSanitize(file, stripInternalIds);
}
console.log(`Packed ${files.length} Codex-facing architect skill file(s).`);
