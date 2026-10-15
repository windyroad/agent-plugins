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

test('Pages configuration separates exact-source qualification from artifact-only deployment', async () => {
  const workflow = parse(await readFile(new URL('../../.github/workflows/website.yml', import.meta.url), 'utf8'));
  assert.deepEqual(workflow.on.workflow_run, { workflows: ['CI'], types: ['completed'], branches: ['main'] });
  assert.deepEqual(workflow.permissions, { contents: 'read' });
  assert.equal(workflow.concurrency['cancel-in-progress'], false);
  const build = workflow.jobs.build;
  assert.equal(build.permissions, undefined);
  for (const guard of ["conclusion == 'success'", "event == 'push'", "head_branch == 'main'", 'head_repository.full_name == github.repository', 'repository.full_name == github.repository', 'github.sha == github.event.workflow_run.head_sha']) assert.ok(build.if.includes(guard), guard);
  assert.equal(build.steps.find((s) => s.uses?.startsWith('actions/checkout@')).with.ref, '${{ github.event.workflow_run.head_sha }}');
  const guard = build.steps.findIndex((s) => s.run?.includes('node website/scripts/check-deployment.mjs'));
  const install = build.steps.findIndex((s) => s.run?.includes('npm ci'));
  const qualify = build.steps.findIndex((s) => s.run === 'npm run website:test');
  const upload = build.steps.findIndex((s) => s.uses?.startsWith('actions/upload-pages-artifact@'));
  assert.ok(guard >= 0 && guard < install && install < qualify && qualify < upload);
  assert.equal(build.steps[upload].with.path, 'website/dist');
  const deploy = workflow.jobs.deploy;
  assert.equal(deploy.needs, 'build');
  assert.deepEqual(deploy.permissions, { contents: 'read', pages: 'write', 'id-token': 'write' });
  assert.equal(deploy.environment.name, 'github-pages');
  assert.equal(deploy.steps.length, 2);
  assert.match(deploy.steps[0].run, /gh api.*git\/ref\/heads\/main/);
  assert.equal(deploy.steps[0].env.EXPECTED_SHA, '${{ github.event.workflow_run.head_sha }}');
  assert.equal(deploy.steps[1].uses, 'actions/deploy-pages@v4');
  assert.doesNotMatch(deploy.steps.map((s) => s.run ?? s.uses ?? '').join('\n'), /checkout|npm|cache/);
});
