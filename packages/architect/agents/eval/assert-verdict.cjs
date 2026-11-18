const { spawnSync } = require('node:child_process');
const { join } = require('node:path');

module.exports = (output, context) => {
  const expected = context?.config?.verdicts;
  if (typeof output !== 'string' || !Array.isArray(expected) || !expected.length ||
      expected.some((value) => !['PASS', 'FAIL', 'NEEDS DIRECTION'].includes(value))) {
    return { pass: false, score: 0, reason: 'Missing output or expected verdict contract' };
  }
  const result = spawnSync('bash', [
    '-c', 'source "$1"; architect_verdict', 'architect-verdict',
    join(__dirname, '../../hooks/lib/architect-verdict.sh'),
  ], { input: output, encoding: 'utf8', timeout: 10000 });
  if (result.error || result.status !== 0) {
    return { pass: false, score: 0, reason: 'The real verdict consumer did not complete' };
  }
  const actual = result.stdout.trim();
  const pass = expected.includes(actual);
  return { pass, score: pass ? 1 : 0,
    reason: pass ? `Consumer recognized ${actual}` : `Consumer returned ${actual || 'no verdict'}; expected ${expected.join(' or ')}` };
};
