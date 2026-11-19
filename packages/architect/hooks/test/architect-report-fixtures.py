"""Add an explicit non-runtime request/report to legacy verdict hook fixtures."""
import importlib.util
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location('report_fixtures', Path(__file__).with_name('architect-report-contract.py'))
fixtures = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixtures)
prompt, report, _, _ = fixtures.fixtures('nontriggered')
context = prompt[prompt.index('```architect-review-context'):]
suffix = '\n\n' + report[report.index('```architect-report'):]
value = json.load(sys.stdin)
options = value.get('tool_input', {})
if isinstance(options, dict):
    field = 'message' if 'message' in options else 'prompt'
    options[field] = str(options.get(field, 'Review the supplied fixture.')) + '\n' + context
response = value.get('tool_response', {})
if isinstance(response, dict):
    for item in response.get('content', []):
        if isinstance(item, dict) and item.get('type') == 'text' and isinstance(item.get('text'), str):
            item['text'] += suffix
    previous = response.get('previous_status', {})
    if isinstance(previous, dict) and isinstance(previous.get('completed'), str):
        previous['completed'] += suffix
if isinstance(value.get('last_assistant_message'), str): value['last_assistant_message'] += suffix
json.dump(value, sys.stdout)
