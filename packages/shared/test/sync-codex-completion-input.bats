#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
}

@test "Codex completion input decoder copies match the canonical helper" {
  run bash "$REPO_ROOT/scripts/sync-codex-completion-input.sh" --check
  [ "$status" -eq 0 ]
}

@test "canonical decoder unwraps input_text JSON and fails closed on malformed arrays" {
  run node --input-type=module -e '
    const { response } = await import(process.argv[1]);
    const wrapped = {tool_response:[{type:"input_text",text:"{\"task_name\":\"review\"}"}]};
    const malformed = {tool_response:[{type:"image",data:"ignored"}]};
    if (response(wrapped).task_name !== "review") process.exit(1);
    if (Object.keys(response(malformed)).length !== 0) process.exit(2);
  ' "$REPO_ROOT/packages/shared/hooks/lib/codex-completion-input.mjs"
  [ "$status" -eq 0 ]
}
