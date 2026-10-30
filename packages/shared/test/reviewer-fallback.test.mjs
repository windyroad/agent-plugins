import { test } from 'node:test';
import assert from 'node:assert/strict';
import { reviewerDispatch, reviewerInstructionsMatch } from '../hooks/lib/codex-completion-input.mjs';

const role = 'wr-risk-scorer:pipeline';
const instructions = 'Full installed reviewer instructions.\nPreserve the output contract.\n';
const load = candidate => candidate === role ? instructions : null;
const message = `WR_REVIEWER_FALLBACK: ${role}\n<reviewer-instructions>\n${instructions}</reviewer-instructions>\n\nReview this exact checkout.`;
const input = { tool_input: { fork_turns: 'none', message } };

test('an independent general reviewer carries exact installed instructions and the original request', () => {
  const dispatch = reviewerDispatch(input, load);
  assert.equal(dispatch.role, role);
  assert.equal(dispatch.prompt, 'Review this exact checkout.');
  assert.equal(dispatch.reviewerTransport, 'general');
  assert.ok(reviewerInstructionsMatch(dispatch, load));
  assert.ok(!reviewerInstructionsMatch(dispatch, () => instructions + 'changed'));
  assert.ok(!reviewerInstructionsMatch(dispatch, () => null));
});

test('role labels, edited instructions, inherited context, and unrelated named roles cannot qualify', () => {
  for (const tool_input of [
    { fork_turns: 'all', message },
    { message },
    { fork_turns: 'none', message: `WR_REVIEWER_FALLBACK: ${role}\nReview this.` },
    { fork_turns: 'none', message: message.replace('Full installed', 'Altered') },
    { fork_turns: 'none', agent_type: 'worker', message },
    { fork_turns: 'none', message: message.replace(role, 'wr-risk-scorer:unknown') },
  ]) assert.equal(reviewerDispatch({ tool_input }, load), null);
});

test('named reviewers remain preferred and do not depend on fallback prompt formatting', () => {
  const named = reviewerDispatch({ tool_input: { agent_type: role, message: 'Original request' } }, load);
  assert.equal(named.role, role);
  assert.equal(named.prompt, 'Original request');
  assert.equal(named.reviewerTransport, undefined);
  assert.ok(reviewerInstructionsMatch(named, load));
});
