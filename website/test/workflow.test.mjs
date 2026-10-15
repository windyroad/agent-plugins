import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import { parse } from 'yaml';

test('the website is private and outside the plugin publication directory', async () => {
  const root = JSON.parse(await readFile(new URL('../../package.json', import.meta.url), 'utf8'));
  const website = JSON.parse(await readFile(new URL('../package.json', import.meta.url), 'utf8'));
  assert.ok(root.workspaces.includes('website'));
  assert.equal(website.private, true);
  assert.equal(website.name, '@windyroad/website');
  const release = await readFile(new URL('../../.github/workflows/release.yml', import.meta.url), 'utf8');
  assert.doesNotMatch(release, /(?:cd\s+website|--workspace\s+@windyroad\/website)/);
});

test('website validation builds and checks the artifact with read-only CI permission', async () => {
  const ci = parse(await readFile(new URL('../../.github/workflows/ci.yml', import.meta.url), 'utf8'));
  assert.deepEqual(ci.permissions, { contents: 'read' });
  const job = ci.jobs.website;
  assert.ok(job, 'website validation is required in the existing CI workflow');
  assert.equal(job.permissions, undefined);
  const commands = job.steps.map((s) => s.run ?? '').join('\n');
  assert.match(commands, /npm ci/);
  assert.match(commands, /npm run website:build/);
  assert.match(commands, /npm run website:test/);
  assert.match(commands, /playwright install/);
  assert.doesNotMatch(commands, /npm publish|deploy-pages/);
  assert.ok(job.steps.some((s) => s.with?.['node-version'] === 24));
});
