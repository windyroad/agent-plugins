#!/usr/bin/env bats

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
  FIXTURE="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE"
}

@test "actual agent-suite command retains complete failed Promptfoo results and stays nonzero" {
  python3 - "$ROOT" "$FIXTURE" <<'PY'
import json,os,pathlib,subprocess,sys
root,fixture=map(pathlib.Path,sys.argv[1:]);script=json.loads((root/'package.json').read_text())['scripts']['eval:agents']
(fixture/'package.json').write_text(json.dumps({'name':'isolated-eval-fixture','private':True,'scripts':{'eval:agents':script}}))
(fixture/'node_modules').symlink_to(root/'node_modules',target_is_directory=True)
cfg=fixture/'packages/fixture/agents/eval';cfg.mkdir(parents=True)
complete='full response beyond console truncation '+('evidence '*150)+' FINAL_EVIDENCE'
(fixture/'provider.py').write_text('print('+repr(complete)+')\n')
(cfg/'promptfooconfig.yaml').write_text(json.dumps({'prompts':['scenario'],'providers':['exec:python3 '+str(fixture/'provider.py')],'tests':[{'assert':[{'type':'contains','value':'MISSING_EXPECTATION'}]}]}))
env={**os.environ,'PROMPTFOO_CONFIG_DIR':str(fixture/'promptfoo'),'PROMPTFOO_DISABLE_TELEMETRY':'1'}
r=subprocess.run(['npm','run','eval:agents'],cwd=fixture,env=env,text=True,capture_output=True,timeout=90)
assert r.returncode!=0,(r.stdout,r.stderr)
files=list((fixture/'docs/audits/agent-evals-workspace').glob('*.json'));assert len(files)==1,(files,r.stdout,r.stderr)
d=json.loads(files[0].read_text());results=d['results']['results'];assert len(results)==1
assert results[0]['response']['output'].rstrip('\n')==complete
assert results[0]['success'] is False
assert results[0]['gradingResult']['pass'] is False
assert results[0]['gradingResult']['reason']
PY
}
