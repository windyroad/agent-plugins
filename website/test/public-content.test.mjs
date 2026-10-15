import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, writeFile, symlink, rm, readdir, rename } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';

const root = new URL('../../', import.meta.url);
const runner = new URL('../scripts/generate-docs.mjs', import.meta.url);

async function fixture() {
  const dir = await mkdtemp(path.join(tmpdir(), 'windyroad-public-docs-'));
  await mkdir(path.join(dir, 'packages/example/skills/hello'), { recursive: true });
  await mkdir(path.join(dir, 'website/src/content/docs'), { recursive: true });
  await mkdir(path.join(dir, 'docs/audits'), { recursive: true });
  await writeFile(path.join(dir, 'docs/audits/private.md'), 'PRIVATE_DOCS_SENTINEL');
  await writeFile(path.join(dir, 'packages/example/package.json'), JSON.stringify({ name: '@windyroad/example', version: '1.0.0', description: 'Select a guardrail.' }));
  await writeFile(path.join(dir, 'packages/example/README.md'), '*Maturity: Experimental.*\nPRIVATE_README_BODY_SENTINEL');
  await writeFile(path.join(dir, 'packages/example/skills/hello/SKILL.md'), '---\nname: wr-example:hello\ndescription: Say hello. Internal implementation details follow.\n---\nPRIVATE_SKILL_BODY_SENTINEL');
  await writeFile(path.join(dir, 'website/src/content/docs/index.md'), '---\ntitle: Hello\n---\nPublic guide.');
  const manifest = { pages: ['index.md'], packages: [{ slug: 'example', package: 'packages/example/package.json', readme: 'packages/example/README.md', skills: ['packages/example/skills/hello/SKILL.md'] }] };
  return { dir, manifest, run: () => spawnSync(process.execPath, [runner.pathname, dir], { encoding: 'utf8' }), save: () => writeFile(path.join(dir, 'website/public-sources.json'), JSON.stringify(manifest)) };
}

test('selected metadata produces readable routes without copying private bodies or repository docs', async () => {
  const f = await fixture();
  try {
    await f.save();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    const plugin = await readFile(path.join(f.dir, 'website/src/content/docs/plugins/example.md'), 'utf8');
    const skill = await readFile(path.join(f.dir, 'website/src/content/docs/skills/example/hello.md'), 'utf8');
    assert.match(plugin, /Experimental/);
    assert.match(plugin, /1\.0\.0/);
    assert.match(skill, /wr-example:hello/);
    assert.match(skill, /Say hello\./);
    assert.match(skill, /Not stated for this skill in the package README/);
    assert.doesNotMatch(plugin + skill, /PRIVATE_|Internal implementation/);
  } finally { await rm(f.dir, { recursive: true }); }
});

test('skill maturity uses complete commands in grouped table rows and rejects conflicting bands', async () => {
  const f = await fixture();
  try {
    const table = '| Skill | Purpose | Maturity |\n| --- | --- | --- |\n| `/wr-example:other` / `/wr-example:hello` | PRIVATE_README_BODY_SENTINEL | Alpha |\n';
    await writeFile(path.join(f.dir, 'packages/example/README.md'), table);
    await f.save();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    const skill = await readFile(path.join(f.dir, 'website/src/content/docs/skills/example/hello.md'), 'utf8');
    const plugin = await readFile(path.join(f.dir, 'website/src/content/docs/plugins/example.md'), 'utf8');
    assert.match(skill, /Maturity:\*\* Alpha/);
    assert.match(plugin, /\[hello\].*\*\*Alpha\*\*/);
    assert.doesNotMatch(skill + plugin, /PRIVATE_/);
    await writeFile(path.join(f.dir, 'packages/example/README.md'), table + '| `/wr-example:hello` | Summary | Beta |\n');
    const conflicting = f.run();
    assert.notEqual(conflicting.status, 0);
    assert.match(conflicting.stderr, /Conflicting public skill maturity/);
  } finally { await rm(f.dir, { recursive: true }); }
});

test('internal helpers point to selected public workflows instead of advertising their own invocation', async () => {
  const f = await fixture();
  try {
    const publicSkill = 'packages/example/skills/review/SKILL.md';
    await mkdir(path.dirname(path.join(f.dir, publicSkill)), { recursive: true });
    await writeFile(path.join(f.dir, publicSkill), '---\nname: wr-example:review\ndescription: Review the change.\n---\nPrivate body.');
    f.manifest.packages[0].skills.push(publicSkill);
    f.manifest.publicWorkflows = { 'packages/example/skills/hello/SKILL.md': 'review' };
    await f.save();
    assert.equal(f.run().status, 0);
    const helper = await readFile(path.join(f.dir, 'website/src/content/docs/skills/example/hello.md'), 'utf8');
    assert.match(helper, /\[Use review\]\(\.\.\/review\/\)/);
    assert.doesNotMatch(helper, /Invoke in Claude Code|\/wr-example:hello/);
    f.manifest.publicWorkflows['packages/example/skills/hello/SKILL.md'] = 'not-selected';
    await f.save();
    const invalid = f.run();
    assert.notEqual(invalid.status, 0);
    assert.match(invalid.stderr, /Invalid public workflow/);
  } finally { await rm(f.dir, { recursive: true }); }
});

test('unapproved source paths, extra authored pages and symlink inputs fail closed', async () => {
  for (const variant of ['source', 'page', 'symlink']) {
    const f = await fixture();
    try {
      if (variant === 'source') f.manifest.packages[0].readme = 'docs/audits/private.md';
      if (variant === 'page') await writeFile(path.join(f.dir, 'website/src/content/docs/unapproved.md'), 'PRIVATE_DOCS_SENTINEL');
      if (variant === 'symlink') {
        await rm(path.join(f.dir, 'packages/example/README.md'));
        await symlink(path.join(f.dir, 'docs/audits/private.md'), path.join(f.dir, 'packages/example/README.md'));
      }
      await f.save();
      const result = f.run();
      assert.notEqual(result.status, 0, variant);
      assert.match(result.stderr, /public source|unapproved|symlink/i, variant);
    } finally { await rm(f.dir, { recursive: true }); }
  }
});

test('package names containing digits retain their actual public skill name', async () => {
  const f = await fixture();
  try {
    await rename(path.join(f.dir, 'packages/example'), path.join(f.dir, 'packages/c4'));
    await writeFile(path.join(f.dir, 'packages/c4/package.json'), JSON.stringify({ name: '@windyroad/c4', version: '1.0.0', description: 'Create architecture diagrams.' }));
    await writeFile(path.join(f.dir, 'packages/c4/skills/hello/SKILL.md'), '---\nname: wr-c4:hello\ndescription: Create a diagram.\n---\nPrivate body.');
    f.manifest.packages = [{ slug: 'c4', package: 'packages/c4/package.json', readme: 'packages/c4/README.md', skills: ['packages/c4/skills/hello/SKILL.md'] }];
    await f.save();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.match(await readFile(path.join(f.dir, 'website/src/content/docs/skills/c4/hello.md'), 'utf8'), /wr-c4:hello/);
  } finally { await rm(f.dir, { recursive: true }); }
});

async function* files(dir) {
  for (const item of await readdir(dir, { withFileTypes: true })) {
    const target = path.join(dir, item.name);
    assert.equal(item.isSymbolicLink(), false, target);
    if (item.isDirectory()) yield* files(target);
    else yield target;
  }
}

test('the actual built artifact and search assets contain only public routes and no forbidden sentinels', async () => {
  assert.match(await readFile(new URL('./fixtures/private-content.md', import.meta.url), 'utf8'), /quarantinedpublicationcanary/);
  let indexed = false;
  for await (const file of files(new URL('../dist/', import.meta.url).pathname)) {
    const relative = path.relative(new URL('../dist/', import.meta.url).pathname, file);
    assert.doesNotMatch(relative, /(?:^|\/)(?:docs|audits|plans|problems|decisions|\.env)(?:\/|$)/);
    const bytes = await readFile(file);
    const text = bytes.toString('utf8');
    assert.doesNotMatch(text, /PRIVATE_(?:DOCS|README_BODY|SKILL_BODY)_SENTINEL|quarantinedpublicationcanary/);
    if (file.endsWith('.html')) {
      assert.doesNotMatch(text, /(?:docs\/(?:audits|plans|problems)|\/Users\/tomhoward|\b(?:ADR|STORY|RFC)-\d{3}\b)/);
    }
    if (relative.startsWith('pagefind/')) indexed = true;
  }
  assert.equal(indexed, true, 'the exact artifact must include its search index');
  const source = JSON.parse(await readFile(new URL('../public-sources.json', import.meta.url), 'utf8'));
  assert.ok(source.packages.some((p) => p.slug === 'itil'));
});
