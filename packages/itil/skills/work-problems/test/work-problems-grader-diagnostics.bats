#!/usr/bin/env bats

setup() {
  GRADER="$(cd "$BATS_TEST_DIRNAME/../eval" && pwd)/grade-llm-rubric.sh"
  FIXTURE="$(mktemp -d)"
  cat > "$FIXTURE/claude" <<'PY'
#!/usr/bin/env python3
import os,sys
if os.environ.get('FIXTURE_REQUIRE_EOF') == '1' and sys.stdin.read():
    print('unexpected grader stdin',file=sys.stderr)
    sys.exit(91)
sys.stdout.write(os.environ['FIXTURE_STDOUT'])
sys.stderr.write(os.environ.get('FIXTURE_STDERR',''))
sys.exit(int(os.environ.get('FIXTURE_STATUS','0')))
PY
  chmod +x "$FIXTURE/claude"
}

teardown() {
  rm -rf "$FIXTURE"
}

@test "successful grader retains balanced JSON extraction" {
  run env PATH="$FIXTURE:$PATH" WR_EVAL_RUNTIME=claude \
    FIXTURE_STDOUT='Here is the grade: {"pass":true,"score":1,"reason":"fixture accepted"}' \
    bash "$GRADER" 'fixture rubric'
  [ "$status" -eq 0 ]
  [ "$output" = '{"pass":true,"score":1,"reason":"fixture accepted"}' ]
}

@test "failed grader preserves exact status and both diagnostic streams without emitting a grade" {
  python3 - "$GRADER" "$FIXTURE" <<'PY'
import os,pathlib,subprocess,sys
grader,fixture=sys.argv[1:]
for payload,status in [('{"pass":true,"score":1,"reason":"failed process"}',17),('fixture provider unavailable',23)]:
    env={**os.environ,'PATH':fixture+os.pathsep+os.environ['PATH'],'WR_EVAL_RUNTIME':'claude','FIXTURE_STDOUT':payload,'FIXTURE_STDERR':'fixture stderr diagnostic\n','FIXTURE_STATUS':str(status)}
    r=subprocess.run(['bash',grader,'fixture rubric'],cwd=fixture,env=env,text=True,capture_output=True,timeout=10)
    assert r.returncode==status,(r.returncode,r.stdout,r.stderr)
    assert r.stdout=='',r.stdout
    assert payload in r.stderr,r.stderr
    assert 'fixture stderr diagnostic' in r.stderr,r.stderr
PY
}

@test "argv-driven grader closes unused inherited stdin" {
  python3 - "$GRADER" "$FIXTURE" <<'PY'
import os,subprocess,sys
grader,fixture=sys.argv[1:]
payload='{"pass":false,"score":0,"reason":"fixture rejected"}'
env={**os.environ,'PATH':fixture+os.pathsep+os.environ['PATH'],'WR_EVAL_RUNTIME':'claude','FIXTURE_STDOUT':payload,'FIXTURE_REQUIRE_EOF':'1'}
r=subprocess.run(['bash',grader,'fixture rubric'],cwd=fixture,env=env,text=True,input='unrelated inherited input\n',capture_output=True,timeout=10)
assert r.returncode==0,(r.stdout,r.stderr)
assert r.stdout.strip()==payload,r.stdout
PY
}
