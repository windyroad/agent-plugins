"""Subprocess fixtures for the production CI quota boundary; no model calls."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(sys.argv[1])
CASE = sys.argv[2]

CLAUDE = '''#!/usr/bin/env python3
import json,os,pathlib,sys,time
w=pathlib.Path(os.environ['FIXTURE'])
a=sys.argv[1:]
with (w/'calls').open('a') as f: f.write(json.dumps(a)+'\\n')
if a and a[-1]=='Reply exactly: available': print('available');sys.exit(0)
mode=os.environ.get('MODE','available')
if a==['forward','a b','$(literal)']:
 assert os.environ['FORWARD_ENV']=='preserved'
 assert sys.stdin.buffer.read()==b'input bytes\\x00end'
 sys.stdout.buffer.write(b'out\\x00bytes');sys.stderr.buffer.write(b'err\\x00bytes');sys.exit(23)
if a==['ordinary-concurrent']:
 (w/'inflight').touch();time.sleep(.2);print('Authentication failed',file=sys.stderr);sys.exit(19)
if mode=='available': print('valid response');sys.exit(0)
if mode=='ordinary': print('Transport failed',file=sys.stderr);sys.exit(17)
if mode=='success-quota': print("You've hit your session limit");sys.exit(0)
print("You've hit your session limit · resets 8:50am (UTC)",file=sys.stderr)
if mode=='mixed-line': print('Authentication failed',file=sys.stderr)
if mode=='mixed-same': print('Authentication failed',end='',file=sys.stdout)
sys.exit(17)
'''
COMMAND = '''#!/usr/bin/env python3
import json,os,pathlib,subprocess,sys
w=pathlib.Path(os.environ['FIXTURE']); a=sys.argv[1:]
with (w/'commands').open('a') as f: f.write(json.dumps([pathlib.Path(sys.argv[0]).name,*a])+'\\n')
p=pathlib.Path(a[a.index('--output')+1]) if '--output' in a else pathlib.Path('docs/audits/agent-evals-workspace/agents.json')
p.parent.mkdir(parents=True,exist_ok=True)
mode=os.environ.get('MODE','available')
if os.environ.get('FAIL_AT') and len((w/'commands').read_text().splitlines()) != int(os.environ['FAIL_AT']): mode='available'
os.environ['MODE']=mode
other=subprocess.Popen(['claude','ordinary-concurrent'],stdout=subprocess.PIPE,stderr=subprocess.PIPE) if mode=='concurrent' else None
if other:
 while not (w/'inflight').exists():
  import time;time.sleep(.01)
provider='packages/shared/agents/eval/run-claude-eval.sh' if mode!='unknown' else 'unknown.sh'
r=subprocess.run(['bash',provider],capture_output=True,text=True)
rows=[{'success':r.returncode==0,'failureReason':2 if r.returncode else 0,'error':r.stderr+r.stdout if r.returncode else None,'response':{'output':r.stdout}}]
if mode=='latched':
 second=subprocess.run(['bash',provider],capture_output=True,text=True)
 assert second.returncode!=0 and 'claude-quota-provider-proof:' in second.stderr
 rows.append({'success':False,'failureReason':2,'error':second.stderr})
if other:
 out,err=other.communicate();rows.append({'success':False,'failureReason':2,'error':err.decode()})
if mode=='assertion': rows.append({'success':False,'failureReason':1,'gradingResult':{'pass':False,'reason':'real semantic failure'}})
errors=sum(x['failureReason']==2 for x in rows);failures=sum(x['failureReason']==1 for x in rows)
d={'results':{'results':rows,'stats':{'successes':len(rows)-errors-failures,'failures':failures,'errors':errors}}}
if mode!='missing':
 p.write_text('{malformed' if mode=='malformed' else json.dumps(d))
 if mode=='stale':os.utime(p,(1,1))
sys.exit(17 if r.returncode or failures else 0)
'''


def campaign(mode, flags=None):
    with tempfile.TemporaryDirectory() as tmp:
        w = Path(tmp)
        (w / 'bin').mkdir()
        for name, text in [('claude', CLAUDE), ('npm', COMMAND), ('npx', COMMAND)]:
            p = w / 'bin' / name
            p.write_text(text)
            p.chmod(0o755)
        provider = w/'packages/shared/agents/eval/run-claude-eval.sh'
        provider.parent.mkdir(parents=True)
        provider.write_text('''#!/bin/bash
if [ "$MODE" = harness-before ]; then echo 'Harness parsing failed: malformed grading envelope' >&2; fi
claude subject
status=$?
if [ "$MODE" = harness-after ]; then echo 'Harness parsing failed: malformed grading envelope' >&2; fi
exit "$status"
''')
        (w/'unknown.sh').write_text(provider.read_text())
        # Projection generation remains a real selected command, isolated here.
        node = w / 'bin/node'
        node.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$FIXTURE/builds"\n')
        node.chmod(0o755)
        env = {**os.environ, 'PATH': str(w / 'bin') + os.pathsep + os.environ['PATH'],
               'FIXTURE': tmp, 'MODE': mode, 'GITHUB_OUTPUT': str(w / 'output'),
               'AGENT_EVAL_RUN_SKILLS': 'true', 'AGENT_EVAL_RUN_REMEDIATION': 'true',
               'AGENT_EVAL_RUN_PLANNING': 'true', **(flags or {})}
        r = subprocess.run([str(ROOT / 'scripts/run-agent-evals-ci.sh')], cwd=w,
                           env=env, capture_output=True, text=True, timeout=30)
        commands = [json.loads(x) for x in (w / 'commands').read_text().splitlines()] if (w / 'commands').exists() else []
        calls = [json.loads(x) for x in (w / 'calls').read_text().splitlines()]
        files = {p.name: p.read_text() for p in (w / 'docs/audits/agent-evals-workspace').glob('*.json')}
        output = (w / 'output').read_text()
        builds = (w / 'builds').read_text() if (w / 'builds').exists() else ''
        return r, commands, calls, files, output, builds

if CASE == 'late':
    for mode in ['quota', 'latched']:
        r, cmds, calls, files, out, _ = campaign(mode)
        assert r.returncode == 0 and '::warning::' in r.stdout, (r, cmds, files)
        assert len(cmds) == 1 and len(calls) == 2, (cmds, calls)
        assert 'quota-exhausted=true' in out
        assert json.loads(files['agents.json'])['results']['stats']['errors'] >= 1
    for position in range(1,9):
        r, cmds, calls, files, out, _ = campaign('quota', {'FAIL_AT':str(position)})
        assert r.returncode == 0 and len(cmds)==position and len(files)==position, (position,r,cmds)
        assert len(calls)==position+1 and 'quota-exhausted=true' in out
        r, cmds, calls, files, _, _ = campaign('ordinary', {'FAIL_AT':str(position)})
        assert r.returncode == 17 and len(cmds)==position and len(files)==position, (position,r,cmds)
elif CASE == 'classification':
    for mode in ['mixed-line', 'mixed-same']:
        r, cmds, _, _, _, _ = campaign(mode)
        assert r.returncode == 17 and '::warning::' not in r.stdout, (mode, r)
        assert len(cmds) == 1
    r, cmds, _, _, out, _ = campaign('success-quota')
    assert r.returncode == 0 and len(cmds) == 8 and 'quota-exhausted=true' not in out, r
elif CASE == 'mixed':
    for mode in ['concurrent', 'assertion', 'harness-before', 'harness-after', 'unknown']:
        r, cmds, _, files, _, _ = campaign(mode)
        assert r.returncode == 17 and '::warning::' not in r.stdout, (mode, r)
        assert len(cmds) == 1 and files
elif CASE == 'results':
    for mode in ['missing', 'malformed', 'stale']:
        r, cmds, _, _, _, _ = campaign(mode)
        assert r.returncode == 17 and '::warning::' not in r.stdout, (mode, r)
        assert len(cmds) == 1
elif CASE == 'campaigns':
    r, cmds, _, files, out, builds = campaign('available')
    assert r.returncode == 0 and len(cmds) == 8, (r, cmds)
    assert len(files) == 8 and 'quota-exhausted=true' not in out
    assert cmds[0] == ['npm', 'run', 'eval:agents']
    assert [c[c.index('--output')+1].split('/')[-1] for c in cmds[1:]] == ['work-problems-appetite.json','update-upstream.json','voice-remediation.json','risk-remediation.json','grader-boundary.json','incident-eligibility.json','planning-claude.json']
    assert cmds[2][cmds[2].index('--filter-pattern')+1] == 'AFK below-appetite|AFK external-comms FAIL|Gate composition is mandatory'
    assert cmds[3][cmds[3].index('--filter-pattern')+1] == 'Routine failed release|Material unresolved'
    assert cmds[6][cmds[6].index('--filter-pattern')+1] == 'Incident eligibility'
    assert cmds[7][cmds[7].index('--max-concurrency')+1] == '2'
    assert builds.strip() == 'scripts/sync-codex-plugin-surfaces.mjs planning --build'
    for flag, count in [('AGENT_EVAL_RUN_AGENTS',7),('AGENT_EVAL_RUN_SKILLS',4),('AGENT_EVAL_RUN_REMEDIATION',6),('AGENT_EVAL_RUN_PLANNING',7)]:
        r, cmds, _, _, _, _ = campaign('available',{flag:'false'})
        assert r.returncode == 0 and len(cmds) == count, (flag, r, cmds)
    # A separate job has no exhausted latch from its predecessor.
    assert campaign('quota')[0].returncode == 0
    assert len(campaign('available')[1]) == 8
elif CASE == 'promptfoo':
    import shlex
    import shutil
    for mode in ['quota','harness-before','harness-after','unknown']:
      with tempfile.TemporaryDirectory() as tmp:
        w=Path(tmp); (w/'bin').mkdir(); state=w/'state';state.mkdir();(state/'proofs').mkdir()
        (state/'nonce').write_text('actual-promptfoo-fixture')
        real=w/'real';real.write_text(CLAUDE);real.chmod(0o755)
        for binary in ['claude','bash']:
            shim=w/'bin'/binary;shim.write_text('#!/bin/sh\nexec python3 '+shlex.quote(str(ROOT/'scripts/agent-eval-quota.py'))+' '+binary+' "$@"\n');shim.chmod(0o755)
        (w/'node_modules').symlink_to(ROOT/'node_modules',target_is_directory=True)
        provider=w/'packages/shared/agents/eval/run-claude-eval.sh';provider.parent.mkdir(parents=True)
        provider.write_text('if [ "$MODE" = harness-before ]; then echo "Harness parsing failed" >&2; fi\nclaude subject\nstatus=$?\nif [ "$MODE" = harness-after ]; then echo "Harness parsing failed" >&2; fi\nexit "$status"\n')
        name='unknown.sh' if mode=='unknown' else 'run-claude-eval.sh'
        if mode=='unknown':(provider.parent/name).write_text(provider.read_text())
        config=provider.parent/'config.yaml'
        config.write_text(json.dumps({'prompts':['hypothetical fixture'],'providers':['exec:bash ./'+name],'tests':[{'assert':[{'type':'contains','value':'expected'}]}]}))
        result='docs/audits/agent-evals-workspace/actual.json'
        env={**os.environ,'PATH':str(w/'bin')+os.pathsep+os.environ['PATH'],'FIXTURE':tmp,'MODE':mode,
             'AGENT_EVAL_QUOTA_STATE':str(state),'AGENT_EVAL_CLAUDE_REAL':str(real),
             'AGENT_EVAL_BASH_REAL':shutil.which('bash'),'AGENT_EVAL_ROOT':tmp,
             'PROMPTFOO_CONFIG_DIR':str(w/'promptfoo'),'PROMPTFOO_DISABLE_TELEMETRY':'1'}
        r=subprocess.run(['python3',str(ROOT/'scripts/agent-eval-quota.py'),'run','npx','--no-install','promptfoo','eval','-c',str(config),'--no-cache','--no-table','--output',result],cwd=w,env=env,capture_output=True,text=True,timeout=90)
        assert (r.returncode==0)==(mode=='quota') and (state/'unavailable').exists()==(mode=='quota'),(mode,r.stdout,r.stderr)
        d=json.loads((w/result).read_text())['results']
        assert d['stats']['errors']==1 and d['stats']['successes']==0 and d['stats']['failures']==0
        assert d['results'][0]['failureReason']==2 and 'actual-promptfoo-fixture' in d['results'][0]['error']
        assert ('claude-quota-provider-proof:' in d['results'][0]['error'])==(mode=='quota')
elif CASE == 'forwarding':
    with tempfile.TemporaryDirectory() as tmp:
        w=Path(tmp); real=w/'real';real.write_text(CLAUDE);real.chmod(0o755)
        state=w/'state';state.mkdir();(state/'nonce').write_text('forwarding-fixture')
        env={**os.environ,'FIXTURE':tmp,'FORWARD_ENV':'preserved', 'AGENT_EVAL_CLAUDE_REAL':str(real),'AGENT_EVAL_QUOTA_STATE':str(state)}
        r=subprocess.run(['python3',str(ROOT/'scripts/agent-eval-quota.py'),'claude','forward','a b','$(literal)'],env=env,input=b'input bytes\x00end',capture_output=True)
        assert (r.returncode,r.stdout,r.stderr)==(23,b'out\x00bytes',b'err\x00bytes'),r
        assert not (state/'exhausted').exists()
        import shutil
        env.update(AGENT_EVAL_BASH_REAL=shutil.which('bash'),AGENT_EVAL_ROOT=tmp)
        for known in [False,True]:
            script=w/('packages/shared/agents/eval/run-claude-eval.sh' if known else 'unrelated.sh')
            script.parent.mkdir(parents=True,exist_ok=True)
            script.write_text('exec '+str(real)+' forward "$@"\n')
            r=subprocess.run(['python3',str(ROOT/'scripts/agent-eval-quota.py'),'bash',str(script),'a b','$(literal)'],env=env,input=b'input bytes\x00end',capture_output=True)
            assert (r.returncode,r.stdout,r.stderr)==(23,b'out\x00bytes',b'err\x00bytes'),r
        # A failed output transport cannot mint evidence of a pure provider error.
        (state/'ordinary-failure').unlink(missing_ok=True)
        child=subprocess.Popen(['python3',str(ROOT/'scripts/agent-eval-quota.py'),'claude','forward','a b','$(literal)'],env=env,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        child.stdout.close();child.stdin.write(b'input bytes\x00end');child.stdin.close()
        diagnostic=child.stderr.read();status=child.wait(timeout=10)
        assert status!=0 and (state/'ordinary-failure').exists(),(status,diagnostic)
        env['AGENT_EVAL_CLAUDE_REAL']=str(w/'missing-executable')
        r=subprocess.run(['python3',str(ROOT/'scripts/agent-eval-quota.py'),'claude','subject'],env=env,capture_output=True)
        assert r.returncode!=0 and not (state/'exhausted').exists()
else:
    raise AssertionError(CASE)
