#!/usr/bin/env python3
"""CI-local Claude forwarding and conservative late-quota result validation."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import threading
import uuid

QUOTA = re.compile(r"You've hit your (weekly|session) limit( · resets ([A-Za-z]{3} [0-9]{1,2}, )?[0-9]{1,2}(:[0-9]{2})?(am|pm) \(UTC\))?")


def pure_quota(data):
    lines = [line for line in data.replace('\r', '').splitlines() if line.strip()]
    return len(lines) == 1 and QUOTA.fullmatch(lines[0]) is not None


def forward(command):
    # Inherit stdin/environment and tee both streams as their original bytes.
    child = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    captured = [bytearray(), bytearray()]
    forwarding_errors = []

    def copy(source, target, collected):
        try:
            while True:
                chunk = source.read1(65536)
                if not chunk:
                    break
                collected.extend(chunk)
                target.write(chunk)
                target.flush()
        except (OSError, ValueError) as error:
            forwarding_errors.append(error)
            child.kill()

    threads = [threading.Thread(target=copy, args=(child.stdout, sys.stdout.buffer, captured[0])),
               threading.Thread(target=copy, args=(child.stderr, sys.stderr.buffer, captured[1]))]
    for thread in threads:
        thread.start()
    status = child.wait()
    for thread in threads:
        thread.join()
    if forwarding_errors:
        (Path(os.environ['AGENT_EVAL_QUOTA_STATE']) / 'ordinary-failure').touch()
        raise OSError('Evaluation stream forwarding failed') from forwarding_errors[0]
    return (status if status >= 0 else 128 - status), captured


def cli_tag(state):
    return '[claude-quota-unavailable:' + (state / 'nonce').read_text().strip() + ']'


def claude(args):
    state = Path(os.environ['AGENT_EVAL_QUOTA_STATE'])
    marker = state / 'exhausted'
    tag = cli_tag(state)
    if marker.exists():
        print(tag, file=sys.stderr)
        return 1
    status, captured = forward([os.environ['AGENT_EVAL_CLAUDE_REAL'], *args])
    diagnostic = b'\n'.join(captured).decode('utf-8', errors='replace')
    if status != 0 and pure_quota(diagnostic):
        marker.touch()
        print('\n' + tag, file=sys.stderr)
    elif status != 0:
        (state / 'ordinary-failure').touch()
    return status


def known_provider(args):
    if not args:
        return False
    root = Path(os.environ['AGENT_EVAL_ROOT']).resolve()
    directories = ['packages/' + package + '/agents/eval' for package in
                   ['architect', 'jtbd', 'risk-scorer', 'shared', 'style-guide', 'tdd', 'voice-tone']]
    directories += ['packages/' + package + '/skills/' + skill + '/eval' for package, skill in
                    [('itil', 'work-problems'), ('itil', 'update-upstream'), ('itil', 'manage-incident'),
                     ('voice-tone', 'assess-external-comms'), ('risk-scorer', 'assess-external-comms'),
                     ('planning', 'outcome-led-planning')]]
    allowed = {(root / directory / name).resolve() for directory in directories
               for name in ['run-agent-eval.sh', 'run-claude-eval.sh', 'run-skill-eval.sh', 'grade-llm-rubric.sh']}
    return Path(args[0]).resolve() in allowed


def bash(args):
    real = os.environ['AGENT_EVAL_BASH_REAL']
    if not known_provider(args):
        os.execv(real, [real, *args])
    state = Path(os.environ['AGENT_EVAL_QUOTA_STATE'])
    status, captured = forward([real, *args])
    if status != 0:
        lines = [line for line in b'\n'.join(captured).decode('utf-8', errors='replace')
                 .replace('\r', '').splitlines() if line.strip()]
        tag = cli_tag(state)
        # An inner CLI tag is not sufficient: the COMPLETE outer script must
        # contain no additional diagnostic. Unknown shapes fail closed.
        if ((state / 'exhausted').exists() and lines.count(tag) == 1
                and sum(QUOTA.fullmatch(line) is not None for line in lines) <= 1
                and all(line == tag or QUOTA.fullmatch(line) is not None for line in lines)):
            proof = uuid.uuid4().hex
            (state / 'proofs' / proof).touch()
            print('\n[claude-quota-provider-proof:' + proof + ']', file=sys.stderr)
        else:
            (state / 'ordinary-failure').touch()
    return status


def fingerprints(directory):
    return {path: (path.stat().st_mtime_ns, path.stat().st_size)
            for path in directory.glob('*.json')}


def quota_results(paths, state):
    errors = 0
    try:
        for path in paths:
            result = json.loads(path.read_text())['results']
            rows, stats = result['results'], result['stats']
            if not isinstance(rows, list) or not rows or stats['failures'] != 0:
                return False
            failed = [row for row in rows if row['success'] is False]
            if any(row['success'] is not True and row['success'] is not False for row in rows):
                return False
            if stats['errors'] != len(failed) or stats['successes'] != len(rows) - len(failed):
                return False
            for row in rows:
                if (row.get('gradingResult') or {}).get('pass') is False:
                    return False
            for row in failed:
                proofs = re.findall(r'\[claude-quota-provider-proof:([a-f0-9]{32})\]', row.get('error', ''))
                if (row.get('failureReason') != 2 or len(proofs) != 1
                        or not (state / 'proofs' / proofs[0]).is_file()):
                    return False
            errors += len(failed)
    except (OSError, ValueError, KeyError, TypeError, AttributeError):
        return False
    return errors > 0


def run(args):
    state = Path(os.environ['AGENT_EVAL_QUOTA_STATE'])
    directory = Path('docs/audits/agent-evals-workspace')
    before = fingerprints(directory)
    started = state / 'started'
    started.touch()
    status = subprocess.run(args).returncode
    if not (state / 'exhausted').exists():
        return status if status >= 0 else 128 - status
    after = fingerprints(directory)
    fresh = [path for path, stamp in after.items()
             if stamp != before.get(path) and stamp[0] >= started.stat().st_mtime_ns]
    # A single-config command must have produced its own designated fresh file.
    if '--output' in args:
        expected = Path(args[args.index('--output') + 1])
        if expected not in fresh:
            return status or 1
    if status != 0 and fresh and not (state / 'ordinary-failure').exists() and quota_results(fresh, state):
        (state / 'unavailable').touch()
        return 0
    return status or 1


if __name__ == '__main__':
    mode, *args = sys.argv[1:]
    if mode == 'claude':
        sys.exit(claude(args))
    if mode == 'bash':
        sys.exit(bash(args))
    if mode == 'run':
        sys.exit(run(args))
    if mode == 'pure':
        sys.exit(0 if pure_quota(sys.stdin.read()) else 1)
    if mode == 'nonce':
        print(uuid.uuid4().hex)
    else:
        raise SystemExit('Unknown quota helper mode')
