#!/usr/bin/env python3
"""Bind a canonical eval verdict to exposed CLI model data and its input source."""
import hashlib
import json
from pathlib import Path
import sys


def verify(raw_bytes, model, effort, source_bytes):
    if not isinstance(model, str) or not model or not isinstance(effort, str) or not effort:
        raise ValueError('missing declared model or requested effort')
    record = json.loads(raw_bytes)
    if not isinstance(record, dict) or record.get('is_error') is not False:
        raise ValueError('missing successful CLI result')
    verdict = record.get('result')
    if not isinstance(verdict, str) or not verdict.strip():
        raise ValueError('missing returned verdict')
    usage = record.get('modelUsage')
    if not isinstance(usage, dict) or set(usage) != {model}:
        raise ValueError('actual model missing, mismatched or ambiguous')
    details = usage[model]
    if not isinstance(details, dict):
        raise ValueError('malformed model metadata')
    context = details.get('contextWindow')
    if context is not None and (type(context) is not int or context != 1000000):
        raise ValueError('exposed context does not match the declared native 1M profile')
    profile = {
        'requested_model': model,
        'observed_model': model,
        'requested_effort': effort,
        'independently_observed_effort': 'not established',
        'exposed_context_window': context if context is not None else 'not exposed',
        'raw_sha256': hashlib.sha256(raw_bytes).hexdigest(),
        'verdict_sha256': hashlib.sha256(verdict.encode()).hexdigest(),
        'source_sha256': hashlib.sha256(source_bytes).hexdigest(),
    }
    return verdict, profile


def main():
    raw_path, model, effort, source_path, profile_path = sys.argv[1:]
    verdict, profile = verify(Path(raw_path).read_bytes(), model, effort,
                              Path(source_path).read_bytes())
    Path(profile_path).write_text(json.dumps(profile) + '\n')
    sys.stdout.write(verdict)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, TypeError, OSError) as error:
        print('Canonical reviewer qualification unavailable: ' + str(error), file=sys.stderr)
        sys.exit(2)
