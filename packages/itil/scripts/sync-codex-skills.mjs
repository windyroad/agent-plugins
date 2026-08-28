#!/usr/bin/env node

import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const output = join(root, "skills-codex");
const hooksOutput = join(root, "hooks-codex");
const backup = join(root, ".pack-published-source");
const repoRoot = resolve(root, "../..");
const skills = readdirSync(join(root, "skills"), { withFileTypes: true })
  .filter((entry) => entry.isDirectory() && existsSync(join(root, "skills", entry.name, "SKILL.md")))
  .map((entry) => entry.name)
  .sort();
const sourceId = /\b(?:ADR-\d{3,}|P-?\d{3}|RFC-\d{3,}|JTBD-\d{3,}|STORY(?:-MAP)?-\d{3,}|R-?\d{3})\b/g;
const corpus = {
  ADR: "docs/decisions",
  P: "docs/problems",
  RFC: "docs/rfcs",
  JTBD: "docs/jtbd",
  "STORY-MAP": "docs/story-maps",
  STORY: "docs/stories",
  R: "docs/risks",
};
const kinds = {
  ADR: "architecture rule",
  P: "problem",
  RFC: "release design",
  JTBD: "user outcome",
  "STORY-MAP": "journey map",
  STORY: "delivery story",
  R: "standing risk",
};
const retired = new Map([
  ["RFC-062", "example release design"],
  ["STORY-008", "bootstrap capture-story-map delivery story"],
  ["STORY-010", "bootstrap list-stories delivery story"],
  ["STORY-011", "bootstrap reconcile-stories delivery story"],
  ["STORY-MAP-001", "RFC framework bootstrap journey map"],
  ["STORY-MAP-002", "take a problem from noticed to resolved journey map"],
]);

const preamble = `<!-- Generated from the runtime-neutral skill source. Do not edit. -->

> Codex runtime note: use \`request_user_input\` only where this contract
> explicitly requires a human decision. Resolve \`<itil-plugin-root>\` from
> this installed \`SKILL.md\`: it is two directories above the skill
> directory. Run bundled commands from \`<itil-plugin-root>/bin/\`; do not
> search the adopter repository or rely on those commands being on \`PATH\`.
> Spawn \`wr-itil:hang-off-check\` with the native Codex subagent tool, wait
> for it, and close that same agent.

`;

function walk(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });
}

function key(id) {
  const match = id.match(/^(STORY-MAP|STORY|ADR|RFC|JTBD|P|R)-?(\d+)$/);
  return match ? { type: match[1], number: String(Number(match[2])) } : null;
}

function titles() {
  const result = new Map(retired);
  for (const [type, relative] of Object.entries(corpus)) {
    for (const file of walk(join(repoRoot, relative)).filter((path) => path.endsWith(".md"))) {
      const number = file.match(/\/(?:ADR-|RFC-|JTBD-|STORY-MAP-|STORY-|R-?)?(\d{3})-[^/]+\.md$/i)?.[1];
      const heading = readFileSync(file, "utf8").match(/^#\s+(.+)$/m)?.[1];
      if (!number || !heading) continue;
      const prefix = new RegExp(`^(?:Architecture Decision Record\\s+)?(?:Problem\\s+)?(?:Risk\\s+)?(?:ADR-|RFC-|JTBD-|STORY-MAP-|STORY-|R)?${Number(number)}\\s*:?\\s*`, "i");
      const title = heading.replace(prefix, "").replace(sourceId, "").replace(/\s{2,}/g, " ").trim();
      if (title) result.set(`${type}-${number}`, title);
    }
  }
  return result;
}

const publicTitles = titles();

function sanitize(text) {
  return text.replace(sourceId, (id) => {
    const parsed = key(id);
    const title = publicTitles.get(`${parsed.type}-${String(parsed.number).padStart(3, "0")}`);
    if (!title) throw new Error(`No public title for ${id}`);
    return `the "${title}" ${kinds[parsed.type]}`;
  }).replaceAll("the the ", "the ").replaceAll("The the ", "The ");
}

function sanitizeCode(text) {
  return text.replace(sourceId, (id) => {
    const parsed = key(id);
    const title = publicTitles.get(`${parsed.type}-${String(parsed.number).padStart(3, "0")}`);
    if (!title) throw new Error(`No public title for ${id}`);
    return `${title}-${kinds[parsed.type]}`
      .normalize("NFKD")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "");
  });
}

function isCode(file) {
  const relative = file.slice(root.length + 1);
  return relative.startsWith("bin/") || [".js", ".mjs", ".cjs", ".sh"].includes(extname(file));
}

function runtimeTerms(text) {
  return text
    .replaceAll("AskUserQuestion", "request_user_input")
    .replaceAll("claude -p --permission-mode bypassPermissions --output-format json", "native Codex subagent")
    .replaceAll("claude -p --output-format json", "native Codex subagent")
    .replaceAll("claude -p", "native Codex subagent")
    .replaceAll("claude plugin list --json", "codex plugin list")
    .replaceAll("claude --version", "codex --version")
    .replace(/claude\s+\/wr-itil:/g, "/wr-itil:")
    .replaceAll("Claude Code", "Codex")
    .replace(/\bClaude\b/g, "Codex")
    .replaceAll("CLAUDE_SESSION_ID", "CODEX_THREAD_ID")
    .replaceAll("version-claude-code", "version-codex")
    .replaceAll(".claude", ".codex");
}

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
  const helperBlock = /Land the commit via the \*\*`wr-risk-scorer-restage-commit`\*\*[\s\S]*?```bash\nwr-risk-scorer-restage-commit \\\n  -m "docs\(problems\): capture P<NNN> <title>" \\\n  -- docs\/problems\/open\/<NNN>-<kebab-title>\.md docs\/problems\/README\.md\n# If README-history\.md was modified, append it to the path list:\n#   -- docs\/problems\/open\/<NNN>-<kebab-title>\.md docs\/problems\/README\.md docs\/problems\/README-history\.md\n```/;
  let result = runtimeTerms(bareName(skill, text))
    .replaceAll("Agent tool", "native Codex subagent tool")
    .replaceAll("Agent-tool", "native-Codex-subagent-tool")
    .replaceAll("Skill tool", "installed skill invocation")
    .replaceAll("Skill-tool", "installed-skill-invocation")
    .replaceAll("packages/itil/", "<itil-plugin-root>/");
  result = result.replace(helperBlock, `Land the commit in one Bash call so the risk assessment cannot leave a partially re-staged index:

\`\`\`bash
git add -- docs/problems/open/<NNN>-<kebab-title>.md docs/problems/README.md
if git diff --cached --quiet --exit-code; then exit 1; fi
git commit -m "docs(problems): capture P<NNN> <title>"
# Add docs/problems/README-history.md to the git add list when it changed.
\`\`\``);
  result = result.replace(/(?<![\w/])(wr-itil-[a-z0-9-]+)/g, "<itil-plugin-root>/bin/$1");
  result = runtimeTerms(sanitize(result));
  const runtimeNote = preamble;
  if (!result.startsWith("---\n")) return runtimeNote + result;
  const end = result.indexOf("\n---\n", 4);
  return end === -1 ? runtimeNote + result : result.slice(0, end + 5) + "\n" + runtimeNote + result.slice(end + 5);
}

function clean() {
  rmSync(output, { recursive: true, force: true });
  rmSync(hooksOutput, { recursive: true, force: true });
}

function publishedFiles() {
  const roots = ["skills", "agents", "hooks", "scripts", "lib", "bin", "templates"];
  return [join(root, "README.md"), join(root, "CHANGELOG.md"), ...roots.flatMap((dir) => walk(join(root, dir)))]
    .filter((file) => !file.includes("/test/") && !file.includes("/eval/"))
    .filter((file) => file !== fileURLToPath(import.meta.url));
}

function restore() {
  if (!existsSync(backup)) return;
  for (const file of walk(backup)) {
    const relative = file.slice(backup.length + 1);
    cpSync(file, join(root, relative));
  }
  rmSync(backup, { recursive: true, force: true });
}

if (process.argv.includes("--clean")) {
  clean();
  process.exit(0);
}

if (process.argv.includes("--restore-pack")) {
  restore();
  clean();
  process.exit(0);
}

if (!process.argv.includes("--build") && !process.argv.includes("--pack")) {
  console.error("Usage: sync-codex-skills.mjs --build | --pack | --restore-pack | --clean");
  process.exit(2);
}

if (process.argv.includes("--pack")) {
  if (existsSync(backup)) throw new Error("Refusing to pack: published-source backup already exists");
  for (const file of publishedFiles()) {
    const relative = file.slice(root.length + 1);
    const saved = join(backup, relative);
    mkdirSync(dirname(saved), { recursive: true });
    cpSync(file, saved);
    const text = readFileSync(file, "utf8");
    writeFileSync(file, isCode(file) ? sanitizeCode(text) : sanitize(text), "utf8");
  }
}

clean();
for (const skill of skills) {
  const source = join(root, "skills", skill);
  const target = join(output, skill);
  cpSync(source, target, {
    recursive: true,
    filter: (path) => !path.split("/").some((part) => ["test", "eval", "evals"].includes(part)),
  });
  const file = join(target, "SKILL.md");
  const sourceText = readFileSync(file, "utf8");
  const runtimeSource = skill === "work-problems" ? "codex-work-problems.md" : undefined;
  const runtimeText = runtimeSource ? readFileSync(join(root, "scripts", runtimeSource), "utf8") : sourceText;
  writeFileSync(file, transform(skill, runtimeText), "utf8");
  for (const supporting of walk(target).filter((path) => path !== file)) {
    writeFileSync(supporting, runtimeTerms(sanitize(readFileSync(supporting, "utf8"))), "utf8");
  }
}

mkdirSync(hooksOutput, { recursive: true });
writeFileSync(join(hooksOutput, "hooks.json"), `${JSON.stringify({
  hooks: {
    SessionStart: [{ matcher: "startup", hooks: [{ type: "command", command: "\${CLAUDE_PLUGIN_ROOT}/hooks/itil-codex-dispatch.sh session-start" }] }],
    UserPromptSubmit: [{ hooks: [{ type: "command", command: "\${CLAUDE_PLUGIN_ROOT}/hooks/itil-codex-dispatch.sh user-prompt" }] }],
    PreToolUse: [{ matcher: "Bash|Write|Edit|Read|request_user_input|AskUserQuestion", hooks: [{ type: "command", command: "\${CLAUDE_PLUGIN_ROOT}/hooks/itil-codex-dispatch.sh pre-tool" }] }],
    PostToolUse: [{ matcher: "Bash|Write|Edit", hooks: [{ type: "command", command: "\${CLAUDE_PLUGIN_ROOT}/hooks/itil-codex-dispatch.sh post-tool" }] }],
    Stop: [{ hooks: [{ type: "command", command: "\${CLAUDE_PLUGIN_ROOT}/hooks/itil-codex-dispatch.sh stop" }] }],
  },
}, null, 2)}\n`);

console.error(`Generated ${skills.length} Codex ITIL skills and 5 hook registrations.`);
