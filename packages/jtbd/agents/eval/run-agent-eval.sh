#!/usr/bin/env bash
# run-agent-eval.sh — promptfoo exec-provider driver for the jtbd review
# AGENT eval (RFC-012 S1 / P324). Loads agents/agent.md as the FULL system
# prompt (`--system-prompt`, not `--append-system-prompt`) — an agent eval
# tests the agent in isolation, so its prose IS the entire instruction set,
# unlike the SKILL evals which APPEND SKILL.md to preserve harness context
# (ADR-075 Amendment 2026-06-02). Feeds promptfoo's per-test prompt as the
# user message.
#
# Promptfoo invokes this as: bash run-agent-eval.sh "$PROMPT"
# (per `providers: - id: 'exec:bash ./run-agent-eval.sh'`).
#
# cwd at invocation is the config dir (promptfoo basePath). The jtbd agent
# reads live docs/jtbd/ and runs the `wr-jtbd-is-job-or-persona-unconfirmed`
# PATH shim, whose default root is `docs/jtbd` relative to cwd — so cd to the
# repo root first. ADR-049: this driver is dev-only (tarball-excluded), so the
# repo-relative root resolution only ever runs in the source monorepo.
#
# Subscription auth via the developer's logged-in claude session — no
# ANTHROPIC_API_KEY, no CLAUDE_CODE_OAUTH_TOKEN (CI/release-only per
# ADR-075 §6). Mirrors run-skill-eval.sh's auth posture.
#
# @adr ADR-075 (per-package agent eval; --system-prompt for agent surface)
# @adr ADR-052 (behavioural-tests-default)
# @adr ADR-049 (PATH shim resolution from repo-root cwd)
# @rfc RFC-012 S1
# @problem P324
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
AGENT_MD="${SCRIPT_DIR}/../agent.md"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd -P)"
VERDICT_FILE="/tmp/jtbd-verdict"
STREAM_FILE="$(mktemp "${TMPDIR:-/tmp}/jtbd-agent-eval.XXXXXX")"
MARKER_CREATED=0

cleanup() {
  rm -f "$STREAM_FILE"
  if [[ "$MARKER_CREATED" -eq 1 ]]; then
    rm -f "$VERDICT_FILE"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ ! -f "$AGENT_MD" ]]; then
  echo "run-agent-eval.sh: agent.md not found at $AGENT_MD" >&2
  exit 2
fi

if [[ -e "$VERDICT_FILE" ]]; then
  echo "run-agent-eval.sh: refusing to overwrite existing $VERDICT_FILE" >&2
  exit 2
fi

umask 077
if ! (set -o noclobber; : > "$VERDICT_FILE") 2>/dev/null; then
  echo "run-agent-eval.sh: could not create $VERDICT_FILE" >&2
  exit 2
fi
MARKER_CREATED=1

SANDBOX_SETTINGS="$(python3 - "$REPO_ROOT" <<'PY'
import json
import os
import sys

repo_root = os.path.realpath(sys.argv[1])
print(json.dumps({
    "sandbox": {
        "enabled": True,
        "failIfUnavailable": True,
        "autoAllowBashIfSandboxed": True,
        "allowUnsandboxedCommands": False,
        "filesystem": {
            "allowWrite": ["//tmp/jtbd-verdict"],
            "denyWrite": ["//" + repo_root.lstrip("/")],
        },
    },
}, separators=(",", ":")))
PY
)"

# Run from repo root so docs/jtbd/ and the shim's default root resolve.
cd "$REPO_ROOT"

set +e
claude -p \
  --output-format stream-json \
  --verbose \
  --setting-sources "" \
  --tools "Read,Glob,Grep,Bash" \
  --settings "$SANDBOX_SETTINGS" \
  --system-prompt "$(cat "$AGENT_MD")" \
  "$@" > "$STREAM_FILE"
CLAUDE_STATUS=$?
set -e

if [[ "$CLAUDE_STATUS" -ne 0 ]]; then
  exit "$CLAUDE_STATUS"
fi

# Emit every main-agent assistant text block, not only Claude's final summary.
# This keeps the required inline verdict visible when a later tool turn is terse.
python3 - "$STREAM_FILE" <<'PY'
import json
import sys

stream_path = sys.argv[1]
found_text = False

with open(stream_path, encoding="utf-8") as stream:
    for line_number, raw_line in enumerate(stream, 1):
        if not raw_line.strip():
            continue
        try:
            event = json.loads(raw_line)
        except json.JSONDecodeError as error:
            print(
                f"run-agent-eval.sh: malformed stream JSON on line {line_number}: {error}",
                file=sys.stderr,
            )
            raise SystemExit(2)

        if event.get("type") != "assistant" or event.get("parent_tool_use_id") is not None:
            continue

        content = event.get("message", {}).get("content")
        if not isinstance(content, list):
            print(
                f"run-agent-eval.sh: malformed assistant message on line {line_number}",
                file=sys.stderr,
            )
            raise SystemExit(2)

        for block in content:
            if not isinstance(block, dict) or block.get("type") != "text":
                continue
            text = block.get("text")
            if not isinstance(text, str):
                print(
                    f"run-agent-eval.sh: malformed assistant text on line {line_number}",
                    file=sys.stderr,
                )
                raise SystemExit(2)
            print(text)
            found_text = True

if not found_text:
    print("run-agent-eval.sh: stream contained no assistant text", file=sys.stderr)
    raise SystemExit(2)
PY

if [[ "$(wc -c < "$VERDICT_FILE" | tr -d ' ')" -ne 4 ]] || [[ "$(cat "$VERDICT_FILE")" != "PASS" ]]; then
  echo "run-agent-eval.sh: expected exact PASS marker in $VERDICT_FILE" >&2
  exit 2
fi
