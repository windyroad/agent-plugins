#!/usr/bin/env bash
set -euo pipefail

PACKAGE="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
TMP="$(cd "$TMP" && pwd -P)"
trap 'node "$PACKAGE/scripts/sync-codex-skills.mjs" --restore-pack >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT

CODEX_BIN="${CODEX_BINARY:-$(command -v codex)}"
CODEX_BIN="$(cd "$(dirname "$CODEX_BIN")" && pwd)/$(basename "$CODEX_BIN")"
REAL_PATH="$PATH"
export CODEX_HOME="$TMP/codex-home"
export EXPECTED_CHECKOUT="$TMP/project"
export FAKE_NESTED_RECORD="$TMP/nested-record"
export FAKE_NESTED_COUNT="$TMP/nested-count"
export FAKE_CLAUDE_CALLED="$TMP/claude-called"
mkdir -p "$CODEX_HOME" "$EXPECTED_CHECKOUT/docs/problems/known-error" "$TMP/fake-bin" "$TMP/zdot"

git -C "$EXPECTED_CHECKOUT" init -q
git -C "$EXPECTED_CHECKOUT" config user.email test@example.com
git -C "$EXPECTED_CHECKOUT" config user.name Test
printf '%s\n' '# Problem 529: Installed Codex dispatch smoke' '**Status**: Known Error' > "$EXPECTED_CHECKOUT/docs/problems/known-error/529-installed-codex-dispatch-smoke.md"
git -C "$EXPECTED_CHECKOUT" add .
git -C "$EXPECTED_CHECKOUT" commit -qm 'test: add P529 fixture'

if [[ -f "$HOME/.codex/auth.json" ]]; then
  cp "$HOME/.codex/auth.json" "$CODEX_HOME/auth.json"
fi

npm pack "$PACKAGE" --pack-destination "$TMP" >/dev/null
TARBALL="$(find "$TMP" -maxdepth 1 -name '*.tgz' -print -quit)"
env CODEX_BINARY="$CODEX_BIN" npm exec --yes --package "$TARBALL" -- windyroad-itil --runtime codex --scope user >/dev/null

cat > "$TMP/fake-bin/codex" <<'FAKE_CODEX'
#!/usr/bin/env bash
set -euo pipefail

[[ "${1:-}" == exec ]]
shift
checkout=""
final=""
prompt=""
json=false
while (( $# )); do
  case "$1" in
    --cd|-C) checkout="$2"; shift 2 ;;
    --output-last-message|-o) final="$2"; shift 2 ;;
    --json) json=true; shift ;;
    --ephemeral|--dangerously-bypass-approvals-and-sandbox|--dangerously-bypass-hook-trust) shift ;;
    --*) shift ;;
    *) prompt="$1"; shift ;;
  esac
done

[[ "$checkout" == "$EXPECTED_CHECKOUT" ]]
[[ "$json" == true ]]
[[ -n "$final" ]]
[[ "$prompt" == *P529* ]]
[[ "$prompt" == *'/wr-itil:manage-problem 529'* ]]
[[ "$prompt" == *'/wr-retrospective:run-retro'* ]]
[[ "$prompt" == *governance* ]]
[[ "${WR_SUPPRESS_PENDING_QUESTIONS:-}" == 1 ]]
[[ "${WR_SUPPRESS_OVERSIGHT_NUDGE:-}" == 1 ]]
[[ "${WR_SUPPRESS_CORRECTION_DETECT:-}" == 1 ]]
find "$CODEX_HOME" -path '*/skills/work-problems/SKILL.md' -print -quit | grep -q .

printf 'called\n' >> "$FAKE_NESTED_COUNT"
printf 'ticket=P529\ncheckout=%s\n' "$checkout" > "$FAKE_NESTED_RECORD"
printf '%s\n' '{"type":"thread.started","thread_id":"fake-nested"}' '{"type":"turn.started"}' '{"type":"item.completed","item":{"type":"agent_message","text":"nested progress sentinel"}}'
cat > "$final" <<'SUMMARY'
ITERATION_SUMMARY
ticket_id: P529
ticket_title: Installed Codex dispatch smoke
action: worked
outcome: investigated
committed: false
reason: behavioural smoke only
outstanding_questions: []
remaining_backlog_count: 0
notes: NESTED_SENTINEL=codex-p529-smoke; retro=attempted
SUMMARY
FAKE_CODEX

cat > "$TMP/fake-bin/claude" <<'FAKE_CLAUDE'
#!/usr/bin/env bash
printf 'called\n' > "$FAKE_CLAUDE_CALLED"
exit 97
FAKE_CLAUDE
chmod +x "$TMP/fake-bin/codex" "$TMP/fake-bin/claude"
printf 'export PATH=%q\n' "$TMP/fake-bin:$REAL_PATH" > "$TMP/zdot/.zprofile"
export ZDOTDIR="$TMP/zdot"

node -e 'require("node:fs").writeFileSync(process.argv[1], JSON.stringify({type:"object",additionalProperties:false,required:["ticketId","exactCheckout","nestedSentinel","summaryConsumed","progressMetadataConsumed"],properties:{ticketId:{type:"string",const:"P529"},exactCheckout:{type:"string"},nestedSentinel:{type:"string",const:"codex-p529-smoke"},summaryConsumed:{type:"boolean",const:true},progressMetadataConsumed:{type:"boolean",const:true}}}))' "$TMP/schema.json"

PATH="$TMP/fake-bin:$REAL_PATH" "$CODEX_BIN" exec \
  --ephemeral \
  --ignore-user-config \
  --dangerously-bypass-approvals-and-sandbox \
  --dangerously-bypass-hook-trust \
  --cd "$EXPECTED_CHECKOUT" \
  --json \
  --output-schema "$TMP/schema.json" \
  --output-last-message "$TMP/result.json" \
  '$wr-itil:work-problems Behavioural smoke only. Preselect exactly P529. Skip the full preflight and loop. Execute the installed skill contract isolated Codex iteration exactly once in this checkout, with a self-contained prompt that explicitly invokes /wr-itil:manage-problem 529 and /wr-retrospective:run-retro. Consume the nested final-output ITERATION_SUMMARY and JSONL progress metadata, then return the required schema. Make no repository changes. Leave test-owned temporary files for the harness cleanup.' \
  > "$TMP/outer.jsonl"

[[ "$(wc -l < "$FAKE_NESTED_COUNT" | tr -d ' ')" == 1 ]]
grep -Fxq 'ticket=P529' "$FAKE_NESTED_RECORD"
grep -Fxq "checkout=$EXPECTED_CHECKOUT" "$FAKE_NESTED_RECORD"
[[ ! -e "$FAKE_CLAUDE_CALLED" ]]
jq -e --arg checkout "$EXPECTED_CHECKOUT" '.ticketId == "P529" and .exactCheckout == $checkout and .nestedSentinel == "codex-p529-smoke" and .summaryConsumed == true and .progressMetadataConsumed == true' "$TMP/result.json" >/dev/null
jq -e 'select(.type == "thread.started" or .type == "turn.started" or .type == "item.completed")' "$TMP/outer.jsonl" >/dev/null
printf 'Installed Codex ITIL dispatch smoke passed.\n'
