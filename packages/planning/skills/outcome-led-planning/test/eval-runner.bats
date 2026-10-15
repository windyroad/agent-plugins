#!/usr/bin/env bats

setup() {
  SKILL="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  PACKAGE="$(cd "$SKILL/../.." && pwd)"
  TMP="$(mktemp -d)"
  mkdir -p "$TMP/bin"
  export EVAL_ARGV="$TMP/argv.jsonl"
  export EVAL_STDIN="$TMP/stdin.jsonl"
  cat > "$TMP/bin/claude" <<'NODE'
#!/usr/bin/env node
const fs = require('node:fs');
fs.appendFileSync(process.env.EVAL_STDIN, JSON.stringify(fs.readFileSync(0, 'utf8')) + '\n');
fs.appendFileSync(process.env.EVAL_ARGV, JSON.stringify(process.argv.slice(2)) + '\n');
process.stdout.write('{"pass":true,"score":1,"reason":"fake subprocess boundary"}\n');
NODE
  chmod +x "$TMP/bin/claude"
  export PATH="$TMP/bin:$PATH"
  node "$PACKAGE/../../scripts/sync-codex-plugin-surfaces.mjs" planning --build >/dev/null
}

teardown() {
  node "$PACKAGE/../../scripts/sync-codex-plugin-surfaces.mjs" planning --clean >/dev/null
  rm -rf "$TMP"
}

@test "subject receives only its scenario on both skill surfaces" {
  for surface in source codex; do
    run bash "$SKILL/eval/run-skill-eval.sh" "$surface" 'SUBJECT_SCENARIO' '{"assertions":"DO_NOT_FORWARD"}'
    [ "$status" -eq 0 ]
  done
  run node - "$EVAL_ARGV" <<'NODE'
const assert = require('node:assert/strict');
const lines = require('node:fs').readFileSync(process.argv[2], 'utf8').trim().split('\n').map(JSON.parse);
assert.equal(lines.length, 2);
for (const args of lines) {
  assert.equal(args.at(-1), 'SUBJECT_SCENARIO');
  assert.equal(args.some(arg => arg.includes('DO_NOT_FORWARD')), false);
  assert.equal(args[args.indexOf('--tools') + 1], '');
  assert.ok(args.includes('--strict-mcp-config'));
}
NODE
  [ "$status" -eq 0 ]
}

@test "interview sends each user reply separately and resumes the same session" {
  run bash "$SKILL/eval/run-skill-eval.sh" source '{"turns":["FIRST_USER_TURN","SECOND_USER_TURN"]}' '{"assertions":"DO_NOT_FORWARD"}'
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq length)" -eq 2 ]
  run node - "$EVAL_ARGV" "$EVAL_STDIN" <<'NODE'
const assert = require('node:assert/strict');
const stdin = require('node:fs').readFileSync(process.argv[3], 'utf8').trim().split('\n').map(JSON.parse);
assert.deepEqual(stdin, ['', '']);
const [first, second] = require('node:fs').readFileSync(process.argv[2], 'utf8').trim().split('\n').map(JSON.parse);
assert.equal(first.at(-1), 'FIRST_USER_TURN');
assert.equal(second.at(-1), 'SECOND_USER_TURN');
assert.equal(first.some(arg => arg.includes('SECOND_USER_TURN')), false);
assert.ok(first.includes('--session-id'));
assert.ok(second.includes('--resume'));
assert.ok(first[first.indexOf('--session-id') + 1]);
assert.ok(second[second.indexOf('--resume') + 1]);
assert.equal(first[first.indexOf('--session-id') + 1], second[second.indexOf('--resume') + 1]);
assert.equal(second.includes('--append-system-prompt'), false);
assert.equal([...first, ...second].some(arg => arg.includes('DO_NOT_FORWARD')), false);
NODE
  [ "$status" -eq 0 ]
}

@test "grader forwards only the grading prompt to its existing implementation" {
  run bash "$SKILL/eval/grade-llm-rubric.sh" 'GRADING_PROMPT' '{"context":"DO_NOT_FORWARD"}'
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r .pass)" = true ]
  run node - "$EVAL_ARGV" <<'NODE'
const assert = require('node:assert/strict');
const [args] = require('node:fs').readFileSync(process.argv[2], 'utf8').trim().split('\n').map(JSON.parse);
assert.equal(args.at(-1), 'GRADING_PROMPT');
assert.equal(args.some(arg => arg.includes('DO_NOT_FORWARD')), false);
NODE
  [ "$status" -eq 0 ]
}
