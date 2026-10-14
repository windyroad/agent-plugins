#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Keep exec-provider metadata out of the grader invocation as well.
exec bash "$HERE/../../capture-rfc/eval/grade-llm-rubric.sh" "${1:?expected grading prompt}"
