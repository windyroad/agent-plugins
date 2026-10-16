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

@test "actual CI skill commands retain designated JSON and preserve failed process exits" {
  node --input-type=module - "$ROOT" "$FIXTURE" <<'JS'
import fs from 'node:fs';import YAML from 'yaml';
const [root,fixture]=process.argv.slice(2);
const workflow=YAML.parse(fs.readFileSync(root+'/.github/workflows/ci.yml','utf8'));
const runs=workflow.jobs['eval-agents'].steps.filter(s=>s.run?.includes('npx promptfoo eval')).map(s=>s.run);
fs.writeFileSync(fixture+'/runs.json',JSON.stringify(runs));
JS
  python3 - "$FIXTURE" <<'PY'
import json,os,pathlib,subprocess,sys
fixture=pathlib.Path(sys.argv[1]);bin_dir=fixture/'bin';bin_dir.mkdir()
stub=bin_dir/'npx';stub.write_text('''#!/usr/bin/env python3
import json,os,pathlib,sys
a=sys.argv[1:]
assert '--output' in a, 'missing structured result transport'
p=pathlib.Path(a[a.index('--output')+1]);assert str(p).startswith('docs/audits/agent-evals-workspace/') and p.suffix=='.json'
p.parent.mkdir(parents=True,exist_ok=True)
p.write_text(json.dumps({'response':{'output':'complete '+('evidence '*150)+' END'},'gradingResult':{'pass':False,'reason':'unchanged failure'}}))
counter=pathlib.Path('invocations');n=int(counter.read_text())+1 if counter.exists() else 1;counter.write_text(str(n))
sys.exit(17 if n==int(os.environ['FIXTURE_FAIL_AT']) else 0)
''');stub.chmod(0o755)
runs=json.loads((fixture/'runs.json').read_text());assert len(runs)==5
for i,command in enumerate(runs):
 count=command.count('npx promptfoo eval')
 for failure in range(count+1):
  workspace=fixture/(str(i)+'-'+str(failure));workspace.mkdir()
  env={**os.environ,'PATH':str(bin_dir)+os.pathsep+os.environ['PATH'],'FIXTURE_FAIL_AT':str(failure)}
  r=subprocess.run(['bash','-e','-c',command],cwd=workspace,env=env,text=True,capture_output=True)
  assert r.returncode==(17 if failure else 0),(r.stdout,r.stderr)
  files=list((workspace/'docs/audits/agent-evals-workspace').glob('*.json'));assert len(files)==(failure or count)
  for p in files:
   d=json.loads(p.read_text());assert d['response']['output'].endswith(' END') and len(d['response']['output'])>250
   assert d['gradingResult']=={'pass':False,'reason':'unchanged failure'}
PY
}
