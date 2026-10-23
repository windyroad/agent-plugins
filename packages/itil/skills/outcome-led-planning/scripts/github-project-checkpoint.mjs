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
function repositoryFor(config) {
  requireValue(config?.version === 1 && config.backend === 'github', 'This operation requires the saved GitHub backend.');
  const repository = config.github?.repository;
  requireValue(typeof repository === 'string' && /^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\/[\w.-]+$/.test(repository) && !['.', '..'].includes(repository.split('/')[1]), 'Invalid configured GitHub repository.');
  return repository;
}
function scope(request, config) {
  const repository = repositoryFor(config);
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
function briefField(body, pattern, cue) {
  // shortcut: observed literal brief fields only; extend when an actual brief needs another syntax.
  const lines = body.split(/\r?\n/).map((text, index) => ({ line: index + 1, text }));
  const matches = lines.flatMap(line => {
    const match = line.text.match(pattern);
    return match ? [{ ...line, value: match[1].trim() }] : [];
  });
  const literalEvidence = matches.map(({ line, text }) => ({ line, text }));
  if (matches.length > 1) return { state: 'multiple-candidates', evidence: literalEvidence };
  if (matches.length === 1) {
    const { value } = matches[0];
    return { state: !value ? 'empty' : /^(?:unresolved|unknown|tbd|unclaimed)(?:\b|$)/i.test(value) ? 'explicitly-unresolved' : 'candidate', value, evidence: literalEvidence };
  }
  const evidence = lines.filter(line => cue.test(line.text));
  return { state: evidence.length ? 'unsupported-format' : 'literal-field-missing', evidence };
}
function textReference(body, number, repository) {
  const escaped = repository.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const reference = new RegExp(`(?:(?<![\\w./#:-])#${number}\\b|https://github\\.com/${escaped}/issues/${number}(?![\\w/]))`, 'i');
  const evidence = body.split(/\r?\n/).flatMap((text, index) => reference.test(text) ? [{ line: index + 1, text }] : []);
  return { observed: evidence.length > 0, evidence };
}
function inspectHierarchy(request, config) {
  const repository = repositoryFor(config);
  const roles = { outcome: request?.outcome, increment: request?.increment?.issue, next: request?.next?.issue, task: request?.task?.issue };
  requireValue(Object.values(roles).every(n => Number.isSafeInteger(n) && n > 0) && new Set(Object.values(roles)).size === 4, 'Four distinct outcome, increment, next and task issue numbers are required.');
  const projectSelection = { state: 'not-recorded', source: 'configuration' };
  if (Object.hasOwn(config.github, 'projectUrl')) {
    try {
      const url = new URL(config.github.projectUrl);
      requireValue(url.protocol === 'https:' && url.hostname === 'github.com' && !url.username && !url.password && !url.search && !url.hash && /^\/(?:users|orgs)\/[\w.-]+\/projects\/[1-9]\d*(?:\/views\/[1-9]\d*)?\/?$/.test(url.pathname), 'Invalid recorded Project URL.');
      Object.assign(projectSelection, { state: 'recorded', url: `https://github.com${url.pathname.split('/views/')[0].replace(/\/$/, '')}` });
    } catch { projectSelection.state = 'invalid'; }
  }
  const records = {};
  const findings = projectSelection.state === 'recorded' ? [] : [{ issue: roles.outcome, field: 'projectSelection', state: projectSelection.state, nextAction: `Establish selection from applicable project requirements and explicit direction. If it remains unresolved, save that selection gap and conditional Project work on outcome #${roles.outcome} and read back its saved body before claiming reconciliation complete. Reuse an already saved gap without an unchanged write.` }];
  for (const [role, number] of Object.entries(roles)) {
    const record = issue(number, { repository });
    requireValue(record.number === number && record.url?.toLowerCase() === `https://github.com/${repository}/issues/${number}`.toLowerCase() && typeof record.body === 'string', 'Returned issue does not match its requested repository/number or brief.');
    const inspection = {
      owner: briefField(record.body, /^\s*(?:(?:Outcome|Increment|Task) )?Owner:\s*(.*)$/i, /\bowner\b/i),
      revision: briefField(record.body, /^\s*Revision:\s*(.*)$/i, /\brevision\b/i),
      acceptance: briefField(record.body, /^\s*(?:Tentative )?Acceptance(?: criteria| evidence)?:\s*(.*)$/i, /\bacceptance\b/i),
      parent: briefField(record.body, /^\s*Parent(?: outcome| increment)?:\s*(.*)$/i, /\bparent\b/i)
    };
    records[role] = { ...record, inspection };
    for (const field of ['owner', 'revision', 'acceptance']) {
      if (!['candidate', 'explicitly-unresolved'].includes(inspection[field].state)) findings.push({ issue: number, field, state: inspection[field].state });
    }
  }
  const textLinks = [[records.outcome, records.increment], [records.outcome, records.next], [records.increment, records.task]].map(([parent, child]) => {
    const parentMentionsChild = textReference(parent.body, child.number, repository);
    const field = child.inspection.parent;
    const referencesExpected = 'value' in field ? textReference(field.value, parent.number, repository).observed : null;
    if (!parentMentionsChild.observed) findings.push({ issue: parent.number, field: 'child-text-reference', state: 'not-established', child: child.number });
    if (referencesExpected !== true) findings.push({ issue: child.number, field: 'parent-text-reference', state: 'not-established', parent: parent.number });
    return { parent: parent.number, child: child.number, parentMentionsChild, childParent: { ...field, referencesExpected } };
  });
  return { repository, projectSelection, capabilities: { project: 'not-probed', nativeLinks: 'not-probed' }, records, textLinks, findings };
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
  console.log('Hierarchy: node github-project-checkpoint.mjs inspect-hierarchy REQUEST.json [CONFIG.json]\nInspect: node github-project-checkpoint.mjs inspect REQUEST.json [CONFIG.json]\nApply: node github-project-checkpoint.mjs apply REQUEST.json INSPECTION.json [CONFIG.json]');
} else {
  try {
    const [mode, requestPath, third, fourth] = process.argv.slice(2);
    requireValue(['inspect', 'apply', 'inspect-hierarchy'].includes(mode), 'Expected inspect-hierarchy, inspect or apply; use --help for usage.');
    const request = load(requestPath);
    const config = load((mode === 'apply' ? fourth : third) || '.agents/planning.json');
    const result = mode === 'inspect-hierarchy' ? inspectHierarchy(request, config) : mode === 'inspect' ? inspect(request, config) : apply(request, load(third), config);
    console.log(JSON.stringify(result));
    if (result.status && result.status !== 'synchronized') process.exitCode = 1;
  } catch (error) {
    console.log(JSON.stringify(process.argv[2] === 'inspect-hierarchy'
      ? { status: 'inspection-unavailable', reason: error.message, nextAction: 'Read the affected configuration or record before claiming a completed inspection.' }
      : { status: 'pending', reason: error.message, nextAction: 'Inspect the affected record and resolve this operation before claiming synchronization.' }));
    process.exitCode = 1;
  }
}
