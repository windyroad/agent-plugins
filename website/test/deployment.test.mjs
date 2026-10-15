import assert from 'node:assert/strict';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const script = fileURLToPath(new URL('../scripts/check-deployment.mjs', import.meta.url));
const sha = 'a'.repeat(40);
const repository = 'example/docs';
const event = () => ({
  repository: { full_name: repository },
  workflow_run: { name: 'CI', path: '.github/workflows/ci.yml', status: 'completed', conclusion: 'success', event: 'push', head_branch: 'main', head_sha: sha, head_repository: { full_name: repository } },
});

async function run(payload, env = {}) {
  const dir = await mkdtemp(path.join(tmpdir(), 'windyroad-deployment-'));
  try {
    const file = path.join(dir, 'event.json');
    await writeFile(file, JSON.stringify(payload));
    return spawnSync(process.execPath, [script], { encoding: 'utf8', env: { ...process.env, GITHUB_EVENT_PATH: file, GITHUB_REPOSITORY: repository, GITHUB_SHA: sha, CURRENT_MAIN_SHA: sha, ...env } });
  } finally { await rm(dir, { recursive: true }); }
}

test('the actual deployment guard accepts only a successful exact-current main CI source', async () => {
  const result = await run(event());
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, new RegExp(sha));
});

const rejected = [
  ['failed CI', (e) => { e.workflow_run.conclusion = 'failure'; }],
  ['unfinished CI', (e) => { e.workflow_run.status = 'in_progress'; }],
  ['another workflow', (e) => { e.workflow_run.name = 'Release'; }],
  ['another workflow file', (e) => { e.workflow_run.path = '.github/workflows/other.yml'; }],
  ['PR event', (e) => { e.workflow_run.event = 'pull_request'; }],
  ['other branch', (e) => { e.workflow_run.head_branch = 'feature'; }],
  ['foreign source repository', (e) => { e.workflow_run.head_repository.full_name = 'foreign/fork'; }],
  ['foreign event repository', (e) => { e.repository.full_name = 'foreign/fork'; }],
  ['malformed source SHA', (e) => { e.workflow_run.head_sha = 'main'; }],
  ['missing run', (e) => { delete e.workflow_run; }],
];
for (const [label, mutate] of rejected) {
  test(`the deployment guard rejects ${label}`, async () => {
    const payload = event();
    mutate(payload);
    const result = await run(payload);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Deployment source rejected/);
  });
}
for (const key of ['GITHUB_SHA', 'CURRENT_MAIN_SHA', 'GITHUB_REPOSITORY']) {
  test(`the deployment guard rejects stale or missing ${key}`, async () => {
    for (const value of ['', 'b'.repeat(40)]) {
      const result = await run(event(), { [key]: value });
      assert.notEqual(result.status, 0);
      assert.match(result.stderr, /Deployment source rejected/);
    }
  });
}
