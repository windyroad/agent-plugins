import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { chmodSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const script = fileURLToPath(new URL('../scripts/github-project-checkpoint.mjs', import.meta.url));
const repository = 'fixture-owner/checkpoint-test';
const projectUrl = 'https://github.com/users/fixture-owner/projects/1';
const request = {
  outcome: 1,
  increment: { issue: 2, itemId: 'item2', agent: 'coordinator/session' },
  task: { issue: 4, itemId: 'item4', agent: 'contributor/session' },
  statusFieldId: 'status', agentFieldId: 'agent', statusOptionId: 'active',
  nextAction: 'Continue bounded work.'
};
const originalBody = 'Task owner: contributor/session\nRevision: test-r1\nNext action: start.\nAcceptance: preserve this criterion.\n\n## Completed history\nEarlier verified evidence.\n';
const checkpointStart = '<!-- outcome-led-planning:project-checkpoint:start -->';

// Sanitized test data follows the actual p30-real-item-response.json and P29 issue snapshots.
function initialState(fault) {
  const issue = number => ({
    number, url: `https://github.com/${repository}/issues/${number}`,
    body: number === 4 ? originalBody : `Owner: ${number === 1 ? 'outcome-owner' : 'coordinator/session'}\nRevision: test-r1\n`,
    state: 'OPEN', assignees: [{ id: 'user1', login: 'fixture-owner', name: 'Fixture', databaseId: 1 }],
    labels: [{ id: `label${number}`, name: `kind:${number === 1 ? 'outcome' : number === 2 ? 'increment' : 'task'}`, description: 'Test data', color: '0E8A16' }],
    comments: []
  });
  const item = (number, parent) => ({
    id: `item${number}`, project: { id: 'project1', url: projectUrl },
    content: { id: `issue${number}`, number, url: issue(number).url, parent: { id: `issue${parent}`, number: parent, url: issue(parent).url } },
    fieldValues: { nodes: [
      { __typename: 'ProjectV2ItemFieldUserValue' },
      { __typename: 'ProjectV2ItemFieldRepositoryValue' },
      { __typename: 'ProjectV2ItemFieldLabelValue' },
      { __typename: 'ProjectV2ItemFieldTextValue', text: `Test issue ${number}`, field: { id: 'title', name: 'Title' } },
      { __typename: 'ProjectV2ItemFieldSingleSelectValue', optionId: 'todo', name: 'Todo', field: { id: 'status', name: 'Status' } },
      ...(number === 2 ? [{ __typename: 'ProjectV2ItemFieldSingleSelectValue', optionId: 'now', name: 'Now', field: { id: 'horizon', name: 'Horizon' } }] : [])
    ], pageInfo: { hasNextPage: false } }
  });
  return {
    fault, fieldWrites: 0, issues: Object.fromEntries([1, 2, 4].map(number => [number, issue(number)])),
    project: { id: 'project1', url: projectUrl, closed: false },
    fields: [
      { id: 'status', name: 'Status', type: 'ProjectV2SingleSelectField', options: [{ id: 'todo', name: 'Todo' }, { id: 'active', name: 'In Progress' }, { id: 'done', name: 'Done' }] },
      { id: 'agent', name: 'Agent', type: 'ProjectV2Field' }
    ], nodes: [item(2, 1), item(4, 2)], events: []
  };
}

// One subprocess fixture models persisted provider state, including ambiguous command results.
const ghFixture = `#!/usr/bin/env node
const fs = require('node:fs');
const state = JSON.parse(fs.readFileSync(process.env.CHECKPOINT_STATE, 'utf8'));
const args = process.argv.slice(2);
const value = flag => args[args.indexOf(flag) + 1];
const save = () => fs.writeFileSync(process.env.CHECKPOINT_STATE, JSON.stringify(state));
const finish = (output, failure) => {
  save();
  if (failure) { process.stderr.write(failure); process.exit(1); }
  process.stdout.write(JSON.stringify(output));
};
const event = { args };
state.events.push(event);
if (args[0] === 'api' && args[1] === 'user') finish({ login: 'fixture-owner' });
else if (args[0] === 'api' && args[1] === 'graphql') {
  const input = JSON.parse(fs.readFileSync(0, 'utf8'));
  if (!input.query.includes('ProjectV2Item') || JSON.stringify(input.variables.ids) !== JSON.stringify(['item2', 'item4'])) finish({}, 'Unexpected GraphQL request');
  if (state.fieldWrites && state.fault === 'field-timeout-unreadable') finish({}, 'Project field readback unavailable');
  event.fields = structuredClone(state.nodes);
  finish({ data: { nodes: state.nodes, agentField: { dataType: 'TEXT' } } });
} else if (args[0] === 'project' && args[1] === 'view') finish(state.project);
else if (args[0] === 'project' && args[1] === 'field-list') finish({ fields: state.fields });
else if (args[0] === 'issue' && args[1] === 'view') {
  if (value('--repo') !== '${repository}') finish({}, 'Unexpected repository');
  const issue = state.issues[args[2]];
  if (args[2] === '4' && state.fieldWrites && state.fault === 'changed-body') issue.body = '${originalBody.replaceAll('\n', '\\n')}' + '\\nConcurrent human update.\\n';
  event.body = issue.body;
  finish(value('--json') === 'body' ? { body: issue.body } : issue);
} else if (args[0] === 'project' && args[1] === 'item-edit') {
  const id = value('--id');
  const fieldId = value('--field-id');
  if (!['item2', 'item4'].includes(id) || !['status', 'agent'].includes(fieldId) || value('--project-id') !== 'project1') finish({}, 'Unexpected mutation target');
  state.fieldWrites++;
  const fault = state.fieldWrites === 4 && state.fault;
  if (!['field-denied', 'field-timeout-unsaved', 'field-success-unsaved'].includes(fault)) {
    const node = state.nodes.find(node => node.id === id);
    const values = node.fieldValues.nodes;
    const saved = fieldId === 'agent'
      ? { __typename: 'ProjectV2ItemFieldTextValue', text: value('--text'), field: { id: 'agent', name: 'Agent' } }
      : { __typename: 'ProjectV2ItemFieldSingleSelectValue', optionId: value('--single-select-option-id'), name: 'In Progress', field: { id: 'status', name: 'Status' } };
    const existing = values.findIndex(entry => entry.field?.id === fieldId);
    if (existing === -1) values.push(saved); else values[existing] = saved;
  }
  finish({}, ['field-denied', 'field-timeout-unsaved', 'field-timeout-saved', 'field-timeout-unreadable'].includes(fault) ? fault === 'field-denied' ? 'permission denied' : 'request timed out' : '');
} else if (args[0] === 'issue' && args[1] === 'edit') {
  if (args[2] !== '4' || value('--repo') !== '${repository}' || value('--body-file') !== '-') finish({}, 'Unexpected issue edit');
  event.body = fs.readFileSync(0, 'utf8');
  event.fields = structuredClone(state.nodes);
  if (!['body-timeout-unsaved', 'body-success-unsaved'].includes(state.fault)) state.issues[4].body = event.body;
  finish({}, state.fault.startsWith('body-timeout') ? 'request timed out' : '');
} else finish({}, 'Unsupported gh command: ' + args.join(' '));
`;

function fixture(t, fault = '') {
  const directory = mkdtempSync(join(tmpdir(), 'planning-checkpoint-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  mkdirSync(join(directory, 'bin'));
  mkdirSync(join(directory, '.agents'));
  const statePath = join(directory, 'state.json');
  const requestPath = join(directory, 'request.json');
  const inspectionPath = join(directory, 'inspection.json');
  const configPath = join(directory, '.agents/planning.json');
  const write = (path, value) => writeFileSync(path, JSON.stringify(value));
  write(statePath, initialState(fault));
  write(requestPath, request);
  write(configPath, { version: 1, backend: 'github', github: { repository, projectUrl } });
  writeFileSync(join(directory, 'bin/gh'), ghFixture);
  chmodSync(join(directory, 'bin/gh'), 0o755);
  const state = () => JSON.parse(readFileSync(statePath, 'utf8'));
  const run = (...args) => {
    const result = spawnSync(process.execPath, [script, ...args], {
      cwd: directory, encoding: 'utf8',
      env: { ...process.env, CHECKPOINT_STATE: statePath, PATH: `${join(directory, 'bin')}:${process.env.PATH}` }
    });
    assert.equal(result.error, undefined);
    assert.equal(result.stderr, '');
    return { ...result, output: JSON.parse(result.stdout) };
  };
  const inspect = run('inspect', requestPath);
  assert.equal(inspect.status, 0, inspect.stdout);
  assert.equal(inspect.output.context.repository, repository);
  assert.equal(inspect.output.context.issues.increment.body, state().issues[2].body);
  write(inspectionPath, inspect.output);
  return {
    state,
    change: callback => { const current = state(); callback(current); write(statePath, current); },
    changeRequest: changes => write(requestPath, { ...request, ...changes }),
    apply: () => run('apply', requestPath, inspectionPath, configPath),
    inspected: inspect.output.context
  };
}

const writes = state => state.events.filter(event => event.args[1] === 'item-edit' || event.args[1] === 'edit');
const bodyWrites = state => state.events.filter(event => event.args[0] === 'issue' && event.args[1] === 'edit');
const field = (nodes, id, fieldId) => nodes.find(node => node.id === id).fieldValues.nodes.find(value => value.field?.id === fieldId);

function assertSuccessAtPublication(state) {
  const [publication] = bodyWrites(state);
  assert.ok(publication, 'published one generated checkpoint');
  assert.equal(bodyWrites(state).length, 1);
  assert.match(publication.body, /Result: synchronized/);
  for (const record of [request.increment, request.task]) {
    assert.equal(field(publication.fields, record.itemId, 'status').optionId, 'active');
    assert.equal(field(publication.fields, record.itemId, 'agent').text, record.agent);
    assert.ok(publication.body.includes(`Issue #${record.issue}: Status "In Progress"; Agent "${record.agent}".`));
  }
  const index = state.events.indexOf(publication);
  const preceding = state.events.slice(0, index);
  const lastMutation = preceding.findLastIndex(event => event.args[1] === 'item-edit');
  assert.ok(preceding.slice(lastMutation + 1).some(event => event.args[1] === 'graphql'), 'saved fields read after mutations and before success publication');
  assert.deepEqual(preceding.at(-1).args.slice(0, 3), ['issue', 'view', '4'], 'task body re-read immediately before publication');
  assert.equal(preceding.at(-1).args.at(-1), 'body');
  assert.equal(state.events.at(-1).args[1], 'view', 'body write is read back');
}

test('inspect is read-only; apply publishes only after actual saved Status and distinct Agent values match', t => {
  const f = fixture(t);
  const before = f.state();
  assert.equal(writes(before).length, 0);
  assert.deepEqual(Object.keys(f.inspected.issues), ['outcome', 'increment', 'task']);
  const result = f.apply();
  assert.equal(result.status, 0, result.stdout);
  assert.equal(result.output.status, 'synchronized');
  const saved = f.state();
  assertSuccessAtPublication(saved);
  assert.equal(saved.fieldWrites, 4);
  assert.equal(field(saved.nodes, 'item2', 'horizon').name, 'Now');
  assert.equal(field(saved.nodes, 'item4', 'horizon'), undefined);
  assert.deepEqual(saved.issues[1], before.issues[1]);
  assert.deepEqual(saved.issues[2], before.issues[2]);
  const expected = originalBody.replace('Next action: start.', `Next action: ${request.nextAction}`).trimEnd();
  assert.equal(saved.issues[4].body.split(checkpointStart)[0].trimEnd(), expected);
  assert.deepEqual({ ...saved.issues[4], body: originalBody }, before.issues[4]);
});

test('new discussion or changed brief since inspection prevents every write', t => {
  for (const change of [
    state => state.issues[2].comments.push({ id: 'comment1', body: 'Changed handoff', author: { login: 'peer' }, createdAt: '2026-01-01T00:00:00Z' }),
    state => { state.issues[4].body += '\nChanged scope.\n'; },
    state => { state.issues[1].assignees = [{ login: 'new-owner' }]; }
  ]) {
    const f = fixture(t);
    f.change(change);
    const result = f.apply();
    assert.notEqual(result.status, 0);
    assert.equal(result.output.status, 'changed-context');
    assert.equal(writes(f.state()).length, 0);
  }
});

test('Horizon, another text field, or a non In progress option cannot substitute for checkpoint field roles', t => {
  for (const changes of [
    { statusFieldId: 'horizon', statusOptionId: 'now' },
    { agentFieldId: 'notes' },
    { statusOptionId: 'todo' }
  ]) {
    const f = fixture(t);
    f.change(state => state.fields.push(
      { id: 'horizon', name: 'Horizon', type: 'ProjectV2SingleSelectField', options: [{ id: 'now', name: 'Now' }] },
      { id: 'notes', name: 'Notes', type: 'ProjectV2Field' }
    ));
    f.changeRequest(changes);
    const result = f.apply();
    assert.notEqual(result.status, 0);
    assert.equal(result.output.status, 'pending');
    assert.match(result.output.reason, /Status and Agent fields|In progress status option/);
    assert.equal(writes(f.state()).length, 0);
  }
});

test('changed task body after field verification is preserved without publishing', t => {
  const f = fixture(t, 'changed-body');
  const result = f.apply();
  assert.notEqual(result.status, 0);
  assert.equal(result.output.status, 'changed-context');
  assert.equal(f.state().fieldWrites, 4);
  assert.equal(bodyWrites(f.state()).length, 0);
  assert.match(f.state().issues[4].body, /Concurrent human update/);
});

test('partial denied or ambiguous unsaved field edits read saved state, do not retry, and publish pending truth', t => {
  for (const fault of ['field-denied', 'field-timeout-unsaved', 'field-success-unsaved']) {
    const f = fixture(t, fault);
    const result = f.apply();
    assert.notEqual(result.status, 0, fault);
    assert.equal(result.output.status, 'pending', fault);
    const state = f.state();
    assert.equal(state.fieldWrites, 4, 'no automatic mutation retry');
    assert.equal(field(state.nodes, 'item4', 'status').optionId, 'todo');
    const failedWrite = state.events.findLastIndex(event => event.args[1] === 'item-edit');
    assert.equal(state.events[failedWrite + 1].args[1], 'graphql', 'read saved state immediately after failure/last mutation');
    assert.equal(bodyWrites(state).length, 1);
    assert.match(state.issues[4].body, /Result: pending/);
    assert.doesNotMatch(state.issues[4].body, /Result: synchronized/);
    assert.match(state.issues[4].body, /Next action: Resolve the pending Project checkpoint:/);
    assert.match(result.output.reason, fault === 'field-denied' ? /permission denied/ : fault === 'field-timeout-unsaved' ? /timed out/ : /do not match/);
  }
});

test('ambiguous saved field mutation is resolved by actual readback before publishing', t => {
  const f = fixture(t, 'field-timeout-saved');
  const result = f.apply();
  assert.equal(result.status, 0, result.stdout);
  assert.equal(result.output.status, 'synchronized');
  assert.equal(f.state().fieldWrites, 4, 'saved mutation must not be retried');
  assertSuccessAtPublication(f.state());
});

test('unavailable field readback preserves pending operation and labels prior fields as last observed', t => {
  const f = fixture(t, 'field-timeout-unreadable');
  const result = f.apply();
  assert.notEqual(result.status, 0);
  assert.equal(result.output.status, 'pending');
  assert.equal(f.state().fieldWrites, 4, 'no retry when saved field state is unavailable');
  const reason = /Issue #4, item item4, Status field status: Project field readback unavailable/;
  assert.match(result.output.reason, reason);
  assert.match(f.state().issues[4].body, reason);
  assert.match(f.state().issues[4].body, /Result: pending/);
  assert.doesNotMatch(f.state().issues[4].body, /Result: synchronized/);
  assert.equal(bodyWrites(f.state()).length, 1);
  assert.deepEqual(result.output.lastObservedFields, f.inspected.items);
  assert.equal(Object.hasOwn(result.output, 'verifiedFields'), false);
});

test('ambiguous saved issue write is resolved by actual saved body and never retried', t => {
  const f = fixture(t, 'body-timeout-saved');
  const result = f.apply();
  assert.equal(result.status, 0, result.stdout);
  assert.equal(result.output.status, 'synchronized');
  assertSuccessAtPublication(f.state());
  assert.equal(f.state().issues[4].body, bodyWrites(f.state())[0].body);
});

test('unsaved issue body with timeout or exit zero remains pending after readback', t => {
  for (const fault of ['body-timeout-unsaved', 'body-success-unsaved']) {
    const f = fixture(t, fault);
    const result = f.apply();
    assert.notEqual(result.status, 0);
    assert.equal(result.output.status, 'pending');
    assert.equal(f.state().issues[4].body, originalBody);
    assert.equal(bodyWrites(f.state()).length, 1, 'no automatic issue write retry');
    assert.equal(f.state().events.at(-1).args[1], 'view');
    assert.match(result.output.reason, fault === 'body-timeout-unsaved' ? /timed out/ : /does not match/);
  }
});
