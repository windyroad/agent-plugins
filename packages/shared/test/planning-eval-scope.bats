#!/usr/bin/env bats

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
  FIXTURE="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE"
}

@test "actual workflow scopes planning across PR and complete push ranges with fail-closed discovery" {
  node --input-type=module - "$ROOT" "$FIXTURE" <<'JS'
import fs from 'node:fs';import YAML from 'yaml';
const [root,fixture]=process.argv.slice(2);
const workflow=YAML.parse(fs.readFileSync(root+'/.github/workflows/ci.yml','utf8'));
const scope=workflow.jobs['eval-agents'].steps.find(s=>s.id==='scope');
fs.writeFileSync(fixture+'/scope.sh',scope.run);
if (scope.env.BEFORE_SHA !== '${{ github.event.before }}') throw Error('push base must come from event.before');
JS
  python3 - "$FIXTURE" <<'PY'
import json,os,pathlib,subprocess,sys
fixture=pathlib.Path(sys.argv[1]);bin_dir=fixture/'bin';bin_dir.mkdir()
git=bin_dir/'git';git.write_text('''#!/usr/bin/env python3
import json,os,sys
args=sys.argv[1:]
assert args==['diff','--name-only',os.environ['EXPECTED_BASE'],'head'], args
with open(os.environ['GIT_CALLS'],'a') as f: f.write(json.dumps(args)+'\\n')
if os.environ.get('DIFF_ERROR')=='1': sys.exit(128)
print(os.environ.get('CHANGED',''))
''');git.chmod(0o755)
base={**os.environ,'PATH':str(bin_dir)+os.pathsep+os.environ['PATH'],'BASE_SHA':'pr-base','BEFORE_SHA':'push-before','HEAD_SHA':'head'}
def evaluate(event,changed,expected,**extra):
 out=fixture/'output';out.write_text('');calls=fixture/'calls';calls.write_text('')
 env={**base,'EVENT_NAME':event,'CHANGED':changed,'EXPECTED_BASE':'pr-base' if event=='pull_request' else 'push-before','GITHUB_OUTPUT':str(out),'GIT_CALLS':str(calls),**extra}
 r=subprocess.run(['bash','-e',str(fixture/'scope.sh')],env=env,text=True,capture_output=True)
 assert r.returncode==0,(r.stdout,r.stderr)
 values=dict(line.split('=',1) for line in out.read_text().splitlines())
 for key,value in expected.items(): assert values.get(key,'false')==value,(event,changed,values,key,value)
 return calls.read_text()
for event in ['pull_request','push']:
 evaluate(event,'website/src/content/docs/outcome-led-planning.md',{'planning':'false','run':'false' if event=='pull_request' else 'true'})
 for path in ['packages/planning/skills/outcome-led-planning/SKILL.md','packages/planning/skills/outcome-led-planning/references/github-coordination.md','packages/planning/skills/outcome-led-planning/eval/run-skill-eval.sh','packages/planning/skills/outcome-led-planning/test/eval-runner.bats','packages/itil/skills/outcome-led-planning/SKILL.md','scripts/sync-planning-skill.mjs','scripts/sync-codex-plugin-surfaces.mjs','scripts/run-agent-evals-ci.sh','packages/shared/test/agent-eval-quota-gate.bats','packages/planning/scripts/test/planning-package.bats','packages/shared/test/planning-eval-scope.bats','.github/workflows/ci.yml','package-lock.json']:
  evaluate(event,path,{'planning':'true','run':'true'})
 for path in ['packages/planning/package.json','packages/planning/CHANGELOG.md','packages/planning/.claude-plugin/plugin.json','packages/planning/.codex-plugin/plugin.json','packages/planning/README.md']:
  evaluate(event,path,{'planning':'false','run':'false' if event=='pull_request' else 'true','agents':'false' if event=='pull_request' else 'true','skills':'false' if event=='pull_request' else 'true','remediation':'false' if event=='pull_request' else 'true'})
 evaluate(event,'docs/other.md',{'planning':'true','agents':'true','skills':'true','remediation':'true','run':'true'},DIFF_ERROR='1')
 evaluate(event,'docs/other.md',{'planning':'true','agents':'true','skills':'true','remediation':'true','run':'true'},**({'BASE_SHA':''} if event=='pull_request' else {'BEFORE_SHA':'0000000000000000000000000000000000000000'}))
# The earlier planning change in a multicommit push must be in before..head.
assert evaluate('push','packages/planning/skills/outcome-led-planning/SKILL.md\nREADME.md',{'planning':'true','agents':'true','skills':'true','remediation':'true'}).count('push-before')==1
evaluate('pull_request','packages/planning/skills/outcome-led-planning/SKILL.md',{'agents':'false','skills':'false','remediation':'false','planning':'true','run':'true'})
evaluate('pull_request','packages/architect/agents/architect.md',{'agents':'true','skills':'false','remediation':'false','planning':'false','run':'true'})
evaluate('pull_request','packages/itil/skills/manage-incident/SKILL.md',{'agents':'false','skills':'true','remediation':'false','planning':'false','run':'true'})
evaluate('pull_request','packages/voice-tone/skills/assess-external-comms/SKILL.md',{'agents':'false','skills':'false','remediation':'true','planning':'false','run':'true'})
PY
}
