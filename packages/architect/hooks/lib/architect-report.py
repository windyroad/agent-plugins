#!/usr/bin/env python3
"""Architect-local report completeness. This does not decide action permission."""
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys

sys.dont_write_bytecode = True

FIELDS = ('cpu', 'memory', 'network', 'workload', 'aggregate', 'budget')
TRIGGERS = {'cache', 'quota', 'response', 'handler', 'new_endpoint'}
FENCE = re.compile(r' {0,3}(`{3,}|~{3,})([^\r\n]*)$')


def nonempty(value):
    return isinstance(value, str) and bool(value.strip())


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError('duplicate JSON key')
        result[key] = value
    return result


def decode(text):
    return json.loads(text, object_pairs_hook=unique_object,
                      parse_constant=lambda value: (_ for _ in ()).throw(ValueError('invalid JSON number')))


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True)


def digest(request):
    return hashlib.sha256(canonical(request).encode()).hexdigest()


def fenced(text, label):
    """Only one complete, top-level matching fence is attributable."""
    matches, opened, body = [], None, []
    for line in text.splitlines():
        marker = FENCE.fullmatch(line)
        if opened:
            if marker and marker[1][0] == opened[0] and len(marker[1]) >= opened[1] and not marker[2].strip():
                if opened[2] == label:
                    matches.append('\n'.join(body))
                opened, body = None, []
            else:
                body.append(line)
        elif marker:
            opened = (marker[1][0], len(marker[1]), marker[2].strip())
    if opened or len(matches) != 1:
        raise ValueError('missing or ambiguous ' + label)
    result = decode(matches[0])
    if not isinstance(result, dict):
        raise ValueError('expected JSON object')
    return result


def request_valid(request):
    if not isinstance(request, dict) or type(request.get('version')) is not int or request['version'] != 1:
        return False
    if not all(nonempty(request.get(key)) for key in ('artifact', 'policy')):
        return False
    perf = request.get('performance')
    if not isinstance(perf, dict) or perf.get('applicability') not in ('required', 'not_applicable', 'unknown') or not nonempty(perf.get('evidence')):
        return False
    facts = perf.get('triggers')
    if not isinstance(facts, list):
        return False
    if any(not isinstance(fact, dict) or fact.get('category') not in TRIGGERS or not nonempty(fact.get('evidence')) for fact in facts):
        return False
    if perf['applicability'] == 'required' and not facts:
        return False
    if perf['applicability'] == 'not_applicable' and facts:
        return False
    return True


def context(value):
    if not isinstance(value, dict) or not request_valid(value.get('request')):
        raise ValueError('unavailable request context')
    if value.get('request_sha256') != digest(value['request']):
        raise ValueError('request digest mismatch')
    return value


def from_prompt(prompt):
    if not isinstance(prompt, str):
        raise ValueError('request prompt unavailable')
    return context(fenced(prompt, 'architect-review-context'))


def evaluate(output, envelope=None, verdict=''):
    result = {'verdict': verdict, 'completeness': 'unverified', 'receipt_eligible': False,
              'diagnostic': 'report completeness unavailable'}
    try:
        expected = context(envelope)
        request = expected['request']
        report = fenced(output, 'architect-report')
        if type(report.get('version')) is not int or report['version'] != 1:
            raise ValueError('unsupported report version')
        if report.get('request_sha256') != expected['request_sha256'] or any(report.get(key) != request[key] for key in ('artifact', 'policy')):
            raise ValueError('report request binding mismatch')
        heading_value = 'ISSUES FOUND' if verdict == 'FAIL' else verdict
        if not heading_value or report.get('verdict') != heading_value:
            raise ValueError('report and authoritative verdict disagree')
        perf = report.get('performance')
        if not isinstance(perf, dict) or perf.get('applicability') not in ('required', 'not_applicable', 'unknown', 'disputed') or not nonempty(perf.get('evidence')):
            raise ValueError('invalid applicability assessment')
        caller, reviewer = request['performance']['applicability'], perf['applicability']
        if caller == 'unknown':
            result['diagnostic'] = 'caller applicability remains unknown'
            return result
        if caller != reviewer:
            result.update(completeness='disputed', diagnostic='applicability disagreement remains unresolved')
            return result
        if caller == 'required':
            assessments = perf.get('assessments')
            if not isinstance(assessments, dict):
                result.update(completeness='incomplete', diagnostic='required assessments omitted')
                return result
            for field in FIELDS:
                entry = assessments.get(field)
                if not isinstance(entry, dict) or entry.get('state') not in ('supported', 'unavailable', 'disputed') or not nonempty(entry.get('assessment')):
                    result.update(completeness='incomplete', diagnostic='missing or invalid assessment: ' + field)
                    return result
                if entry['state'] in ('supported', 'disputed') and not all(nonempty(entry.get(key)) for key in ('source', 'uncertainty')):
                    result.update(completeness='incomplete', diagnostic='missing attribution: ' + field)
                    return result
            if any(assessments[field]['state'] == 'disputed' for field in FIELDS):
                result.update(completeness='disputed', diagnostic='resource dispute remains unresolved')
                return result
        result.update(completeness='complete', receipt_eligible=verdict == 'PASS', diagnostic='report structurally complete; factual correctness unverified')
    except (ValueError, TypeError, KeyError, OverflowError) as error:
        result['diagnostic'] = str(error)
    return result


def heading(output):
    spec = importlib.util.spec_from_file_location('architect_verdict', Path(__file__).with_name('architect-verdict.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.parse(output)


def main():
    raw = sys.stdin.read()
    if sys.argv[1:] == ['--prepare']:
        request = decode(raw)
        if not request_valid(request):
            raise ValueError('invalid request facts')
        envelope = {'request': request, 'request_sha256': digest(request)}
        print('```architect-review-context\n' + canonical(envelope) + '\n```')
    elif sys.argv[1:] == ['--context']:
        try:
            print(canonical(from_prompt(raw)))
        except (ValueError, TypeError):
            print('null')
    elif sys.argv[1:] in (['--evaluate'], ['--hook']):
        data = decode(raw)
        if sys.argv[1:] == ['--hook']:
            tool = data.get('tool_input', {})
            response = data.get('tool_response', {})
            content = response.get('content', []) if isinstance(response, dict) else []
            texts = [item.get('text', '') for item in content if isinstance(item, dict) and item.get('type') == 'text' and isinstance(item.get('text'), str)]
            data = {'prompt': tool.get('prompt', tool.get('message', '')),
                    'output': '\n'.join(texts) if texts else data.get('tool_output', '')}
        output = data.get('output', '')
        if not isinstance(output, str):
            output = ''
        envelope = data.get('context')
        if 'prompt' in data:
            try:
                envelope = from_prompt(data['prompt'])
            except (ValueError, TypeError):
                envelope = None
        print(canonical(evaluate(output, envelope, heading(output))))
    else:
        raise ValueError('use --prepare, --context or --evaluate')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        if sys.argv[1:] in (['--evaluate'], ['--hook']):
            print(canonical({'verdict': '', 'completeness': 'unverified', 'receipt_eligible': False,
                             'diagnostic': 'report evaluator unavailable: ' + type(error).__name__}))
        else:
            print('architect-report: ' + str(error), file=sys.stderr)
            sys.exit(1)
