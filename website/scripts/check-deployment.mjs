import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function checkDeployment(event, { repository, workflowSha, currentMain }) {
  const run = event?.workflow_run;
  if (!repository || event?.repository?.full_name !== repository || run?.head_repository?.full_name !== repository) throw new Error('repository identity');
  if (run.name !== 'CI' || run.path !== '.github/workflows/ci.yml' || run.status !== 'completed' || run.conclusion !== 'success') throw new Error('successful CI identity');
  if (run.event !== 'push' || run.head_branch !== 'main') throw new Error('main push event');
  if (!/^[a-f0-9]{40}$/.test(run.head_sha) || run.head_sha !== workflowSha || run.head_sha !== currentMain) throw new Error('current source SHA');
  return run.head_sha;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const event = JSON.parse(await readFile(process.env.GITHUB_EVENT_PATH, 'utf8'));
    const sha = checkDeployment(event, { repository: process.env.GITHUB_REPOSITORY, workflowSha: process.env.GITHUB_SHA, currentMain: process.env.CURRENT_MAIN_SHA });
    console.log(`Deployment source verified: ${sha}`);
  } catch (error) {
    console.error(`Deployment source rejected: ${error.message}`);
    process.exitCode = 1;
  }
}
