#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { isDeepStrictEqual } from 'node:util';

const itemQuery = `query($ids:[ID!]!,$agentFieldId:ID!){nodes(ids:$ids){... on ProjectV2Item{
  id project{id url} content{... on Issue{number url parent{number url}}}
  fieldValues(first:100){nodes{... on ProjectV2ItemFieldSingleSelectValue{
    optionId name field{... on ProjectV2SingleSelectField{id}}
  } ... on ProjectV2ItemFieldTextValue{text field{... on ProjectV2Field{id}}}}
  pageInfo{hasNextPage}}
}} agentField:node(id:$agentFieldId){... on ProjectV2Field{dataType}}}`;
const start = '<!-- outcome-led-planning:project-checkpoint:start -->';
const end = '<!-- outcome-led-planning:project-checkpoint:end -->';
const load = path => JSON.parse(readFileSync(path, 'utf8'));
const requireValue = (ok, message) => { if (!ok) throw new Error(message); };

function call(args, input) {
  const result = spawnSync('gh', args, { input, encoding: 'utf8', timeout: 60000 });
  return { ...result, failure: result.error?.message || (result.status !== 0 ? result.stderr.trim() || `gh exited ${result.status}` : '') };
}
function json(args, input) {
  const result = call(args, input);
  if (result.failure) throw new Error(result.failure);
  const value = JSON.parse(result.stdout);
  if (value.errors?.length) throw new Error(value.errors.map(error => error.message).join('; '));
  return value;
}
function scope(request, config) {
  requireValue(config.version === 1 && config.backend === 'github', 'This operation requires the saved GitHub backend.');
  const repository = config.github?.repository;
  requireValue(typeof repository === 'string' && /^[\w.-]+\/[\w.-]+$/.test(repository), 'Invalid configured GitHub repository.');
  const url = new URL(config.github?.projectUrl);
  const match = url.pathname.match(/^\/(?:users|orgs)\/([\w.-]+)\/projects\/([1-9]\d*)(?:\/views\/[1-9]\d*)?\/?$/);
  requireValue(url.protocol === 'https:' && url.hostname === 'github.com' && match && !url.username && !url.password, 'A selected GitHub Project URL is required.');
  requireValue([request.outcome, request.increment?.issue, request.task?.issue].every(n => Number.isSafeInteger(n) && n > 0), 'Outcome, increment and task issue numbers are required.');
  requireValue(new Set([request.outcome, request.increment.issue, request.task.issue]).size === 3, 'The three issue roles must be distinct.');
  for (const value of [request.increment.itemId, request.task.itemId, request.statusFieldId, request.agentFieldId, request.statusOptionId]) {
    requireValue(typeof value === 'string' && value.length > 0 && !/[\r\n\0]/.test(value), 'Existing item, field and option IDs are required.');
  }
  requireValue(request.increment.itemId !== request.task.itemId && request.statusFieldId !== request.agentFieldId, 'Item and field roles must be distinct.');
  return { repository, owner: match[1], number: match[2], projectUrl: `https://github.com${url.pathname.split('/views/')[0].replace(/\/$/, '')}` };
}
function issue(number, bound) {
  return json(['issue', 'view', String(number), '--repo', bound.repository, '--json', 'number,url,body,state,assignees,labels,comments']);
}
function items(request, bound, projectId) {
  const response = json(['api', 'graphql', '--input', '-'], JSON.stringify({ query: itemQuery, variables: { ids: [request.increment.itemId, request.task.itemId], agentFieldId: request.agentFieldId } }));
  requireValue(response.data.agentField?.dataType === 'TEXT', 'The Agent field must be a text field.');
  return response.data.nodes.map((item, index) => {
    const record = index === 0 ? request.increment : request.task;
    const parent = index === 0 ? request.outcome : request.increment.issue;
    const expected = `https://github.com/${bound.repository}/issues/${record.issue}`;
    requireValue(item && item.id === record.itemId && item.project.id === projectId && item.project.url === bound.projectUrl, 'Project item does not belong to the selected Project.');
    requireValue(item.content?.url.toLowerCase() === expected.toLowerCase() && item.content.parent?.number === parent && item.content.parent.url.toLowerCase() === `https://github.com/${bound.repository}/issues/${parent}`.toLowerCase(), 'Current native issue parent or repository does not match the requested hierarchy.');
    requireValue(!item.fieldValues.pageInfo.hasNextPage, 'Project field response is incomplete; inspect the remaining fields before applying.');
    return { id: item.id, issue: record.issue, fields: Object.fromEntries(item.fieldValues.nodes.filter(value => value.field?.id).map(value => [value.field.id, 'text' in value ? { text: value.text } : { optionId: value.optionId, name: value.name }]).sort(([a], [b]) => a.localeCompare(b))) };
  });
}
function inspect(request, config) {
  const bound = scope(request, config);
  const actor = json(['api', 'user']).login;
  const project = json(['project', 'view', bound.number, '--owner', bound.owner, '--format', 'json']);
  requireValue(project.url === bound.projectUrl && !project.closed, 'Selected Project is unavailable or closed.');
  const allFields = json(['project', 'field-list', bound.number, '--owner', bound.owner, '--format', 'json']).fields;
  const status = allFields.find(field => field.id === request.statusFieldId);
  const agent = allFields.find(field => field.id === request.agentFieldId);
  const option = status?.options?.find(value => value.id === request.statusOptionId);
  requireValue(status?.name === 'Status' && status.type === 'ProjectV2SingleSelectField' && agent?.name === 'Agent' && agent.type === 'ProjectV2Field' && option, 'Requested fields must be the selected Project Status and Agent fields.');
  requireValue(option.name.replace(/[-_\s]/g, '').toLowerCase() === 'inprogress', 'A resume checkpoint requires the existing In progress status option.');
  const records = { outcome: issue(request.outcome, bound), increment: issue(request.increment.issue, bound), task: issue(request.task.issue, bound) };
  requireValue(Object.values(records).every(record => record.state === 'OPEN'), 'This resume operation requires open outcome, increment and task records.');
  return { context: { actor, repository: bound.repository, project: { id: project.id, url: project.url }, fields: { status: { id: status.id, option }, agent: { id: agent.id } }, issues: records, items: items(request, bound, project.id) } };
}
function bodyFor(body, request, status, observed, reason) {
  // shortcut: only the observed literal Next action line; extend when an adopter needs another brief format.
  requireValue(/^Next action:[^\r\n]*/m.test(body), 'Task brief needs its current literal Next action line; no body changes were made.');
  const first = body.indexOf(start);
  const last = body.indexOf(end);
  requireValue((first === -1 && last === -1) || (first >= 0 && last > first && body.indexOf(start, first + 1) === -1 && body.indexOf(end, last + 1) === -1), 'Existing checkpoint block is malformed; preserve the body and repair that block first.');
  let preserved = first < 0 ? body : body.slice(0, first) + body.slice(last + end.length);
  const next = status === 'synchronized' ? request.nextAction : `Resolve the pending Project checkpoint: ${reason}`;
  preserved = preserved.replace(/^Next action:[^\r\n]*/m, () => `Next action: ${next}`);
  const rows = status === 'synchronized' ? observed.map(item => `- Issue #${item.issue}: Status ${JSON.stringify(item.fields[request.statusFieldId].name)}; Agent ${JSON.stringify(item.fields[request.agentFieldId].text)}.`).join('\n') : `Pending: ${reason}`;
  return `${preserved.trimEnd()}\n\n${start}\n## Current Project checkpoint\n\nResult: ${status}\n${rows}\n${end}\n`;
}
function apply(request, inspection, config) {
  for (const value of [request.increment?.agent, request.task?.agent, request.nextAction]) requireValue(typeof value === 'string' && value.trim() && !/[\r\n\0]/.test(value), 'Verified agent/session values and one next action are required.');
  const current = inspect(request, config);
  if (!isDeepStrictEqual(current.context, inspection.context)) return { status: 'changed-context', record: request.task.issue, nextAction: 'Read the returned current context and resolve its changes before applying.', ...current };
  const bound = scope(request, config);
  const projectId = current.context.project.id;
  const originalBody = current.context.issues.task.body;
  bodyFor(originalBody, request, 'pending', [], 'validation');
  let observed = current.context.items;
  let failure = '';
  let operation = '';
  try {
    for (const record of [request.increment, request.task]) {
      for (const [field, flag, value] of [[request.agentFieldId, '--text', record.agent], [request.statusFieldId, '--single-select-option-id', request.statusOptionId]]) {
        operation = `Issue #${record.issue}, item ${record.itemId}, ${field === request.agentFieldId ? 'Agent' : 'Status'} field ${field}`;
        const result = call(['project', 'item-edit', '--id', record.itemId, '--field-id', field, '--project-id', projectId, flag, value, '--format', 'json']);
        if (result.failure) {
          observed = items(request, bound, projectId);
          const saved = observed.find(item => item.id === record.itemId).fields[field];
          if ((flag === '--text' ? saved?.text : saved?.optionId) !== value) throw new Error(result.failure);
        }
      }
    }
    operation = `Saved Status/Agent readback for issues #${request.increment.issue} and #${request.task.issue}`;
    observed = items(request, bound, projectId);
    for (const record of [request.increment, request.task]) {
      const saved = observed.find(item => item.id === record.itemId).fields;
      requireValue(saved[request.agentFieldId]?.text === record.agent && saved[request.statusFieldId]?.optionId === request.statusOptionId, `Saved Project fields for issue #${record.issue} do not match the requested state.`);
    }
  } catch (error) { failure = `${operation}: ${error.message}`; }
  const freshBody = json(['issue', 'view', String(request.task.issue), '--repo', bound.repository, '--json', 'body']).body;
  if (freshBody !== originalBody) return { status: 'changed-context', record: request.task.issue, lastObservedFields: observed, nextAction: 'Preserve the changed task body; inspect it before publishing any checkpoint result.' };
  const status = failure ? 'pending' : 'synchronized';
  const body = bodyFor(freshBody, request, status, observed, failure);
  const written = call(['issue', 'edit', String(request.task.issue), '--repo', bound.repository, '--body-file', '-'], body);
  const saved = json(['issue', 'view', String(request.task.issue), '--repo', bound.repository, '--json', 'body']).body;
  if (saved !== body) return { status: 'pending', record: request.task.issue, reason: written.failure || 'Saved issue body does not match the checkpoint update.', lastObservedFields: observed, nextAction: 'Read the saved issue body before deciding on another write.' };
  return { status, record: request.task.issue, lastObservedFields: observed, ...(failure ? { reason: failure, nextAction: 'Resolve the pending operation before claiming synchronization.' } : {}) };
}

if (process.argv[2] === '--help') {
  console.log('Inspect: node github-project-checkpoint.mjs inspect REQUEST.json [CONFIG.json]\nApply: node github-project-checkpoint.mjs apply REQUEST.json INSPECTION.json [CONFIG.json]');
} else {
  try {
    const [mode, requestPath, third, fourth] = process.argv.slice(2);
    requireValue(mode === 'inspect' || mode === 'apply', 'Expected inspect or apply; use --help for usage.');
    const request = load(requestPath);
    const config = load((mode === 'inspect' ? third : fourth) || '.agents/planning.json');
    const result = mode === 'inspect' ? inspect(request, config) : apply(request, load(third), config);
    console.log(JSON.stringify(result));
    if (result.status && result.status !== 'synchronized') process.exitCode = 1;
  } catch (error) {
    console.log(JSON.stringify({ status: 'pending', reason: error.message, nextAction: 'Inspect the affected record and resolve this operation before claiming synchronization.' }));
    process.exitCode = 1;
  }
}
