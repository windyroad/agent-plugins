"""Exercise report effects through Claude and both native event orders."""
import hashlib
import json
from pathlib import Path
import os
import subprocess
import sys
import tempfile
import uuid

PACKAGE = Path(__file__).resolve().parents[2]
HOOKS = PACKAGE / 'hooks'


def fixtures(case):
    request = {'version': 1, 'artifact': 'fixture callback revision 1', 'policy': 'fixture review policy 1',
               'performance': {'applicability': 'required', 'evidence': 'The applied handler adds a browser POST.',
                               'triggers': [{'category': 'handler', 'evidence': 'Added POST changes per-request I/O.'}]}}
    if case == 'nontriggered':
        request['performance'] = {'applicability': 'not_applicable', 'evidence': 'README spelling only; no runtime change.', 'triggers': []}
    if case == 'caller_unknown':
        request['performance'] = {'applicability': 'unknown', 'evidence': 'The handler diff is unavailable.', 'triggers': []}
    sha = hashlib.sha256(json.dumps(request, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode()).hexdigest()
    envelope = {'request': request, 'request_sha256': sha}
    report = {'version': 1, 'artifact': request['artifact'], 'policy': request['policy'], 'request_sha256': sha,
              'verdict': 'PASS', 'performance': {'applicability': request['performance']['applicability'], 'evidence': request['performance']['evidence'],
                'assessments': {k: {'state': 'unavailable', 'assessment': 'Not estimated: no supplied data.'} for k in ('cpu', 'memory', 'network', 'workload', 'aggregate', 'budget')}}}
    expected = 'complete'
    if case == 'nontriggered': del report['performance']['assessments']
    if case == 'supplied':
        report['performance']['assessments']['cpu'] = {'state': 'supported', 'assessment': '3 ms/request, supplied synthetic fixture; delta -1 ms/request.', 'source': 'fixture measurement record', 'uncertainty': 'Synthetic single-fixture measurement, no production claim.'}
    if case in ('omitted', 'fail_omitted'):
        del report['performance']['assessments']['memory']; expected = 'incomplete'
    if case == 'conflict':
        report['performance']['applicability'] = 'not_applicable'; report['performance']['evidence'] = 'One-time callback'; expected = 'disputed'
    if case == 'caller_unknown':
        report['performance']['applicability'] = 'not_applicable'; expected = 'unverified'
    if case == 'dispute':
        report['performance']['assessments']['cpu'] = {'state': 'disputed', 'assessment': 'The supplied timing describes another handler.', 'source': 'fixture measurement record', 'uncertainty': 'Handler identity remains unresolved.'}; expected = 'disputed'
    if case == 'mismatch':
        report['request_sha256'] = '0' * 64; expected = 'unverified'
    if case == 'verdict_mismatch':
        expected = 'unverified'
    verdict = 'NEEDS DIRECTION' if case == 'direction' else ('FAIL' if case.startswith('fail_') else 'PASS')
    report['verdict'] = 'ISSUES FOUND' if verdict == 'FAIL' else verdict
    if case == 'verdict_mismatch': report['verdict'] = 'ISSUES FOUND'
    body = json.dumps(report)
    if case in ('malformed', 'fail_malformed'):
        body = '{not JSON'; expected = 'unverified'
    output = ('**Architecture Review: '+('ISSUES FOUND' if verdict == 'FAIL' else verdict)+'**') + '\n\nReviewed fixture revision 1.\n\n```architect-report\n' + body + '\n```\n'
    if case == 'missing': output = '**Architecture Review: PASS**\n\nLegacy prose review.\n'; expected = 'unverified'
    prompt = 'Review fixture revision 1.\n```architect-review-context\n' + json.dumps(envelope) + '\n```\n'
    if case == 'context_missing': prompt = 'Review fixture revision 1.'; expected = 'unverified'
    if case == 'json_example':
        output += '\nExample using a nonreserved label:\n```json\n{"verdict":"ISSUES FOUND"}\n```\n'
    if case == 'quoted_report':
        output = '**Architecture Review: PASS**\n\n' + '\n'.join('> '+line for line in output[output.index('```architect-report'):].splitlines()); expected = 'unverified'
    if case == 'ambiguous_report':
        output += '\n' + output[output.index('```architect-report'):]; expected = 'unverified'
    if case == 'quoted_context':
        prompt = '\n'.join('> '+line for line in prompt.splitlines()); expected = 'unverified'
    if case == 'malformed_context':
        prompt = '```architect-review-context\n{not JSON\n```'; expected = 'unverified'
    if case == 'mismatched_context':
        changed = dict(envelope, request_sha256='0'*64)
        prompt = '```architect-review-context\n'+json.dumps(changed)+'\n```'; expected = 'unverified'
    return prompt, output, expected, verdict


def run(command, data, cwd, env):
    return subprocess.run(command, input=json.dumps(data), text=True, capture_output=True, cwd=cwd, env=env, timeout=20)


def check(case, mode, prior=False):
    prompt, output, expected, verdict = fixtures(case)
    with tempfile.TemporaryDirectory(prefix='wr-report-contract-') as temporary:
        root = Path(temporary); project = root/'project'; project.mkdir(); (project/'docs/decisions').mkdir(parents=True)
        subprocess.run(['git', 'init', '-q', str(project)], check=True)
        runtime = root/'runtime'; runtime.mkdir()
        env = dict(os.environ, TMPDIR=str(runtime), CLAUDE_PROJECT_DIR=str(project))
        session = 'report-' + uuid.uuid4().hex; target = 'child-' + uuid.uuid4().hex
        marker = Path('/tmp/architect-reviewed-' + session)
        base = {'session_id': session, 'cwd': str(project)}
        observed = []
        def dispatch(data):
            event = {'SubagentStart':'subagent-start','SubagentStop':'subagent-stop','PreToolUse':'pre-tool','UserPromptSubmit':'user-prompt'}.get(data.get('hook_event_name'), 'post-tool')
            result = run(['bash', str(HOOKS/'architect-dispatch.sh'), event], data, project, env)
            assert result.returncode == 0, result.stderr
            if result.stdout.strip():
                message = json.loads(result.stdout)
                assert message.get('hookSpecificOutput',{}).get('permissionDecision') != 'deny', message
                observed.append(message)
            return result
        prior_state = {}
        if prior:
            previous_prompt,previous_output,_,_ = fixtures('unknown')
            dispatch(dict(base,tool_name='Agent',tool_input={'subagent_type':'wr-architect:agent','prompt':previous_prompt},tool_response={'content':[{'type':'text','text':previous_output}]}))
            import time
            for index,path in enumerate((marker,Path(str(marker)+'.hash'),Path('/tmp/architect-plan-reviewed-'+session))):
                assert path.exists(), 'prior valid receipt was not produced'
                old = time.time_ns() - (120+index)*1_000_000_000
                os.utime(path,ns=(old,old))
                prior_state[path] = (path.read_bytes(),path.stat().st_mtime_ns)
            observed.clear()
        try:
            if mode == 'claude':
                data = dict(base, tool_name='Agent', tool_input={'subagent_type': 'wr-architect:agent', 'prompt': prompt}, tool_response={'content': [{'type':'text','text':output}]})
                result = dispatch(data)
            else:
                spawn = dict(base, tool_name='multi_agent_v1__spawn_agent', tool_input={'agent_type':'wr-architect:agent','message':prompt}, tool_response={'agent_id':target})
                start = dict(base, hook_event_name='SubagentStart', agent_type='wr-architect:agent', agent_id=target)
                if mode == 'native_start_first':
                    dispatch(start)
                    dispatch(dict(base,hook_event_name='SubagentStop',agent_type='wr-architect:agent',agent_id=target,last_assistant_message=output))
                dispatch(spawn)
                if mode == 'native_dispatch_first': dispatch(start)
                if mode == 'codex_close':
                    dispatch(dict(base,tool_name='multi_agent_v1__close_agent',tool_input={'target':target},tool_response={'previous_status':{'completed':output}}))
                else:
                    if mode != 'native_start_first':
                        dispatch(dict(base,hook_event_name='SubagentStop',agent_type='wr-architect:agent',agent_id=target,last_assistant_message=output))
                    dispatch(dict(base,hook_event_name='PreToolUse',tool_name='Edit',tool_input={'file_path':'src/example.js'}))
            if verdict == 'PASS' and expected != 'complete':
                assert any('Architect report completeness:' in x.get('systemMessage','') for x in observed), (case,mode,'specific advisory missing',observed)
            elif expected == 'complete':
                assert not any('Architect report completeness:' in x.get('systemMessage','') for x in observed), (case,mode,'complete report misreported',observed)
            if case == 'context_missing' and mode == 'native_dispatch_first':
                result = dispatch(dict(base,hook_event_name='UserPromptSubmit'))
                message = json.loads(result.stdout)
                assert message['hookSpecificOutput']['hookEventName'] == 'UserPromptSubmit'
                extra = message['hookSpecificOutput']['additionalContext']
                assert 'wr-architect:review-design' in extra and 'Architect report completeness:' in extra
                assert 'Architect report completeness:' in message['systemMessage']
            wanted = expected == 'complete' and verdict == 'PASS'
            if prior:
                for path,(content,stamp) in prior_state.items():
                    if wanted:
                        assert path.stat().st_mtime_ns > stamp, (case,'eligible receipt did not refresh',path)
                    else:
                        assert (path.read_bytes(),path.stat().st_mtime_ns) == (content,stamp), (case,'old approval changed',path)
            else:
                assert marker.exists() is wanted, (case,mode,'receipt',marker.exists(),wanted, {str(p.relative_to(runtime)): p.read_text(errors='replace') for p in runtime.rglob('*') if p.is_file()})
            evaluated = run(['python3',str(HOOKS/'lib/architect-report.py'),'--evaluate'], {'prompt':prompt,'output':output}, project, env)
            assert evaluated.returncode == 0, evaluated.stderr
            value = json.loads(evaluated.stdout)
            assert value['completeness'] == expected and value['verdict'] == verdict and value['receipt_eligible'] is wanted, (case,mode,value)
            if mode == 'claude':
                assertion = PACKAGE/'agents/eval/assert-verdict.cjs'
                javascript = 'const fs=require("fs");const x=JSON.parse(fs.readFileSync(0,"utf8"));process.stdout.write(JSON.stringify(require(process.argv[1])(x.output,x.context)));'
                grade = run(['node','-e',javascript,str(assertion)], {'output':output,'context':{'vars':{'prompt':prompt},'config':{'verdicts':[verdict],'require_report':True}}}, project, env)
                assert grade.returncode == 0, grade.stderr
                assert json.loads(grade.stdout)['pass'] is (expected == 'complete'), (case,grade.stdout)
            guarded = run(['bash',str(HOOKS/'architect-enforce-edit.sh')],dict(base,hook_event_name='PreToolUse',tool_name='Edit',tool_input={'file_path':'src/example.js'}),project,env)
            assert guarded.returncode == 0, (case,mode,'mechanical evidence must not deny action',guarded.stderr)
            if case == 'consumed' and mode.startswith('native_'):
                for path in (marker, Path(str(marker)+'.hash'), Path('/tmp/architect-plan-reviewed-'+session)):
                    path.unlink(missing_ok=True)
                done = list((runtime/'codex-review-transport').glob('receipt-*.json.done'))
                assert len(done) == 1
                original_time = done[0].stat().st_mtime_ns
                dispatch(spawn)
                dispatch(start)
                dispatch(dict(base,hook_event_name='SubagentStop',agent_type='wr-architect:agent',agent_id=target,last_assistant_message=output))
                dispatch(dict(base,hook_event_name='PreToolUse',tool_name='Edit',tool_input={'file_path':'src/example.js'}))
                assert not marker.exists(), 'consumed opaque identity reopened'
                assert done[0].stat().st_mtime_ns == original_time, 'consumed lifetime refreshed'

        finally:
            for suffix in ('','.hash'):
                Path(str(marker)+suffix).unlink(missing_ok=True)
            Path('/tmp/architect-plan-reviewed-'+session).unlink(missing_ok=True)
            Path('/tmp/architect-announced-'+session).unlink(missing_ok=True)


if __name__ == '__main__':
    arguments=sys.argv[1:]
    prior=bool(arguments and arguments[0]=='--prior')
    if prior: arguments=arguments[1:]
    for case in arguments:
        for mode in (('claude',) if prior else ('claude','codex_close','native_start_first','native_dispatch_first')):
            check(case,mode,prior)
    print('Contract behaviors passed:', ', '.join(arguments))
