import { readFile, writeFile, readdir, realpath, mkdir, rm, lstat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse } from 'yaml';

const root = await realpath(path.resolve(process.argv[2] ?? fileURLToPath(new URL('../../', import.meta.url))));
const docs = path.join(root, 'website/src/content/docs');
const manifest = JSON.parse(await readFile(path.join(root, 'website/public-sources.json'), 'utf8'));
const forbidden = /(?:\b(?:ADR|STORY|RFC|P)[- ]?\d{3}\b|PRIVATE_\w+_SENTINEL|\/Users\/|docs\/(?:audits|plans|problems))/;
const text = (value) => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

async function readSource(relative, expected) {
  if (relative !== expected || path.isAbsolute(relative) || relative.split('/').includes('..')) throw new Error(`Unapproved public source: ${relative}`);
  const target = path.join(root, relative);
  if (await realpath(target) !== target || (await lstat(target)).isSymbolicLink()) throw new Error(`Symlink public source: ${relative}`);
  return readFile(target, 'utf8');
}

function publicText(value, label) {
  if (typeof value !== 'string' || !value.trim() || forbidden.test(value)) throw new Error(`Unapproved public source text: ${label}; supply a reviewed public summary`);
  return text(value.trim());
}

function page(title, description, body) {
  return `---\ntitle: ${JSON.stringify(title)}\ndescription: ${JSON.stringify(description)}\n---\n\n${body}\n`;
}

function skillBands(readme) {
  const bands = new Map();
  let maturityColumn = -1;
  for (const line of readme.split('\n')) {
    if (!line.startsWith('|')) { maturityColumn = -1; continue; }
    const cells = line.split('|').slice(1, -1).map((cell) => cell.trim());
    if (cells[0] === 'Skill') { maturityColumn = cells.indexOf('Maturity'); continue; }
    const band = cells[maturityColumn];
    if (!['Experimental', 'Alpha', 'Beta', 'Stable'].includes(band)) continue;
    for (const [, command] of cells[0].matchAll(/`\/(wr-[a-z0-9-]+:[a-z-]+)`/g)) {
      if (bands.has(command) && bands.get(command) !== band) throw new Error(`Conflicting public skill maturity: ${command}`);
      bands.set(command, band);
    }
  }
  return bands;
}

for (const name of manifest.pages) {
  if (!/^[a-z][a-z-]*\.md$/.test(name)) throw new Error(`Unapproved public page: ${name}`);
  await readSource(`website/src/content/docs/${name}`, `website/src/content/docs/${name}`);
}
for (const item of await readdir(docs, { withFileTypes: true })) {
  if (item.isSymbolicLink()) throw new Error(`Symlink public page: ${item.name}`);
  if (!manifest.pages.includes(item.name) && !['plugins', 'skills'].includes(item.name)) throw new Error(`Unapproved public page: ${item.name}`);
}

const pages = [];
const slugs = new Set();
for (const entry of manifest.packages) {
  if (!/^[a-z][a-z0-9-]*$/.test(entry.slug) || slugs.has(entry.slug)) throw new Error('Unapproved or duplicate public source package');
  slugs.add(entry.slug);
  const prefix = `packages/${entry.slug}`;
  const pkg = JSON.parse(await readSource(entry.package, `${prefix}/package.json`));
  const readme = await readSource(entry.readme, `${prefix}/README.md`);
  if (pkg.name !== `@windyroad/${entry.slug}` || !/^\d+\.\d+\.\d+(?:[-+][\w.-]+)?$/.test(pkg.version)) throw new Error('Invalid public package metadata');
  const description = publicText(entry.description ?? pkg.description, entry.package);
  const maturity = readme.match(/Maturity:\s*([a-z-]+)/i)?.[1];
  const maturityText = maturity ? `${maturity}, as stated in the package README.` : 'Not stated in the package README.';
  const bands = skillBands(readme);
  const rows = [];
  for (const source of entry.skills) {
    const skill = source.match(new RegExp(`^packages/${entry.slug}/skills/([a-z][a-z-]*)/SKILL\\.md$`))?.[1];
    if (!skill) throw new Error(`Unapproved public source: ${source}`);
    const raw = await readSource(source, `${prefix}/skills/${skill}/SKILL.md`);
    const frontmatter = raw.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)?.[1];
    if (!frontmatter) throw new Error(`Missing public skill metadata: ${source}`);
    const metadata = parse(frontmatter);
    const command = `wr-${entry.slug}:${skill}`;
    if (metadata.name !== command && metadata.name !== skill) throw new Error(`Unexpected skill name: ${source}`);
    const summary = publicText(manifest.summaries?.[source] ?? String(metadata.description).split(/(?<=[.!?])\s+/)[0], source);
    if (summary.length > 380) throw new Error(`Unapproved public source summary length: ${source}; supply a reviewed public summary`);
    const band = bands.get(command);
    const skillMaturity = band ? `${band}, as stated in the package README.` : 'Not stated for this skill in the package README.';
    rows.push(`- [${skill}](../../skills/${entry.slug}/${skill}/): **${band ?? 'Maturity not stated'}**. ${summary}`);
    const workflow = manifest.publicWorkflows?.[source];
    if (workflow && (!/^[a-z][a-z-]*$/.test(workflow) || !entry.skills.includes(`${prefix}/skills/${workflow}/SKILL.md`) || workflow === skill)) throw new Error(`Invalid public workflow: ${source}`);
    const usage = workflow
      ? `## Use the public workflow\n\nThis is an internal helper. [Use ${workflow}](../${workflow}/) for the public assessment workflow.`
      : `## Invoke in Claude Code\n\n\`\`\`text\n/${command}\n\`\`\`\n\nInstall [${pkg.name}](../../../plugins/${entry.slug}/), restart Claude Code and select the skill. For Codex, use the name exposed by your installed plugin's skill picker; see [runtime guidance](../../../runtimes/).`;
    const guide = entry.slug === 'itil' && skill === 'outcome-led-planning' ? '\n[Learn the outcome-led planning workflow](../../../outcome-led-planning/).\n' : '';
    pages.push({ relative: `skills/${entry.slug}/${skill}.md`, content: page(`${entry.slug}: ${skill}`, summary,
      `${summary}\n\n**Maturity:** ${skillMaturity}\n\n${usage}\n${guide}\n## Source and scope\n\nThis is a summary from the repository reference for **${pkg.name} ${pkg.version}**. It is not a guarantee that an older installed version has this skill.\n\n[Read the full skill instructions on GitHub](https://github.com/windyroad/agent-plugins/blob/main/${source}).`) });
  }
  pages.push({ relative: `plugins/${entry.slug}.md`, content: page(pkg.name, description,
    `${description}\n\n**Maturity:** ${maturityText}\n\n**Repository reference version:** ${pkg.version}. This is the version recorded in the source tree; verify your installed version before relying on a skill or behavior.\n\n## Install for Claude Code\n\n\`\`\`bash\nnpx ${pkg.name}\n\`\`\`\n\nRestart Claude Code after installation. [Choose your runtime and installation scope](../../runtimes/).\n\n## Skills\n\n${rows.length ? rows.join('\n') : 'This package installs selected plugins rather than exposing its own skills.'}\n\n## Package documentation\n\n[Read the package README on GitHub](https://github.com/windyroad/agent-plugins/blob/main/${entry.readme}) for configuration, dependencies and detailed behavior.\n\n[View ${pkg.name} on npm](https://www.npmjs.com/package/${pkg.name}).`) });
}

for (const folder of ['plugins', 'skills']) {
  const target = path.join(docs, folder);
  try {
    if ((await lstat(target)).isSymbolicLink()) throw new Error(`Symlink generated public directory: ${folder}`);
    if (await realpath(target) !== target) throw new Error(`Unapproved generated public directory: ${folder}`);
    await rm(target, { recursive: true });
  } catch (error) { if (error.code !== 'ENOENT') throw error; }
}
for (const { relative, content } of pages) {
  const target = path.join(docs, relative);
  await mkdir(path.dirname(target), { recursive: true });
  await writeFile(target, content);
}
console.log(`Generated ${pages.length} public reference pages from ${manifest.packages.length} selected packages.`);
