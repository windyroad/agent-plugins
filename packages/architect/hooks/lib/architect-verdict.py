#!/usr/bin/env python3
"""Read an unambiguous, unquoted Architect report heading; never infer a verdict."""
import re
import sys

VALUES = r'(PASS|ISSUES FOUND|NEEDS DIRECTION)'
CANON_BOLD = re.compile(r' {0,3}\*\*Architecture Review: ' + VALUES + r'\*\*[ \t]*$')
CANON_PLAIN = re.compile(r' {0,3}Architecture Review: ' + VALUES + r'[ \t]*$')
CANON_H2 = re.compile(r' {0,3}##[ \t]+Architecture Review: ' + VALUES + r'[ \t]*$')
ALIAS_BOLD = re.compile(r' {0,3}\*\*Architecture verdict: ' + VALUES +
                        r'(, with advisories)?\.?\*\*(?:[ \t]+.*)?$')
RESERVED_START = re.compile(r' {0,3}(?:(?:\*\*|##[ \t]+)Architecture (?:Review|verdict):|Architecture Review:)')
RESERVED_TOKEN = re.compile(r'(?:(?:\*\*|##[ \t]+)Architecture (?:Review|verdict):|Architecture Review:)')
FENCE = re.compile(r' {0,3}(`{3,}|~{3,})(.*)$')
QUOTE_OR_INDENT = re.compile(r'(?: {0,3}>| {4}|[ ]*\t)')


def heading(line):
    for pattern in (CANON_BOLD, CANON_H2, CANON_PLAIN):
        match = pattern.fullmatch(line)
        if match:
            return match.group(1)
    match = ALIAS_BOLD.fullmatch(line)
    if match and (not match.group(2) or match.group(1) == 'PASS'):
        return match.group(1)
    return None


def without_inline_code(line):
    # Only matched, same-length backtick runs quote content. Leave an unmatched
    # run literal so it cannot hide a second reserved heading from rejection.
    ranges, opened = [], None
    for match in re.finditer(r'`+', line):
        backslashes = len(line[:match.start()]) - len(line[:match.start()].rstrip('\\'))
        if backslashes % 2:
            continue
        if opened is None:
            opened = match
        elif len(match.group()) == len(opened.group()):
            ranges.append((opened.start(), match.end()))
            opened = None
    for start, end in reversed(ranges):
        line = line[:start] + ' ' * (end - start) + line[end:]
    return line


def parse(text):
    lines = [line.rstrip('\r') for line in text.split('\n')]
    first = next((line for line in lines if line.strip()), '')
    current = heading(first)
    if current is None:
        return ''
    verdicts, fence = [], None
    for line in lines:
        marker = FENCE.fullmatch(line)
        if fence is not None:
            if (marker and marker.group(1)[0] == fence[0] and
                    len(marker.group(1)) >= fence[1] and not marker.group(2).strip()):
                fence = None
            continue
        if QUOTE_OR_INDENT.match(line):
            continue
        if marker:
            fence = (marker.group(1)[0], len(marker.group(1)))
            continue
        if not RESERVED_START.match(line):
            continue
        visible = without_inline_code(line)
        if len(RESERVED_TOKEN.findall(visible)) != 1:
            return ''
        verdict = heading(visible)
        if verdict is None:
            return ''
        verdicts.append(verdict)
    if fence is not None or verdicts != [current]:
        return ''
    return 'FAIL' if current == 'ISSUES FOUND' else current


if __name__ == '__main__':
    sys.stdout.write(parse(sys.stdin.read()))
