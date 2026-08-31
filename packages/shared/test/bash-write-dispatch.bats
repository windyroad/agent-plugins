#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  HELPER="$REPO_ROOT/packages/shared/hooks/lib/bash-write-dispatch.sh"
  WORK="$(mktemp -d)"
  WORK="$(cd "$WORK" && pwd -P)"
  TRACE="$WORK/trace"
  CHILD="$WORK/child.sh"
  cat > "$CHILD" <<'SH'
#!/bin/bash
jq -r '[.tool_name, .tool_input.file_path, (.tool_input.content // "")] | @tsv' >> "$TRACE"
SH
  chmod +x "$CHILD"
}

teardown() {
  rm -rf "$WORK"
}

dispatch() {
  printf '%s' "$1" | TRACE="$TRACE" bash "$HELPER" "${@:2}"
}

@test "read-only Bash commands do not invoke edit gates" {
  payload=$(jq -nc --arg dir "$WORK" '{tool_name:"Bash",tool_input:{workdir:$dir,command:"cat docs/a.md && grep -n needle docs/b.md && echo \">\" docs/c.md"}}')

  run dispatch "$payload" "$CHILD"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -e "$TRACE" ]
}

@test "write redirection becomes a Write event with its target and content" {
  payload=$(jq -nc --arg dir "$WORK" '{tool_name:"Bash",tool_input:{workdir:$dir,command:"echo \"human-oversight: confirmed\" > docs/decisions/001-test.md"}}')

  run dispatch "$payload" "$CHILD"

  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE")" = $'Write\t'"$WORK/docs/decisions/001-test.md"$'\thuman-oversight: confirmed\\n' ]
}

@test "printed tee operands, comments, and heredoc bodies are not writes" {
  for command in \
    "printf '%s\\n' tee src/read-only.ts" \
    $'# echo x > src/read-only.ts\ncat README.md' \
    $'cat <<\'EOF\'\n> src/read-only.ts\ntee src/also-read-only.ts\nEOF'; do
    payload=$(jq -nc --arg dir "$WORK" --arg command "$command" \
      '{tool_name:"Bash",tool_input:{workdir:$dir,command:$command}}')
    run dispatch "$payload" "$CHILD"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [ ! -e "$TRACE" ]
  done
}

@test "literal cd prefixes resolve targets in the destination directory" {
  mkdir -p "$WORK/sub dir"
  payload=$(jq -nc --arg dir "$WORK" \
    '{tool_name:"Bash",tool_input:{workdir:$dir,command:"cd \"sub dir\" && echo x > \"file name.md\""}}')
  run dispatch "$payload" "$CHILD"
  [ "$status" -eq 0 ]
  grep -Fq "$WORK/sub dir/file name.md" "$TRACE"
  [ "$(wc -l < "$TRACE" | tr -d ' ')" -eq 1 ]
}

@test "content is associated with its command rather than an unrelated heredoc or pipeline" {
  command=$'cat <<\'EOF\'\nhuman-oversight: confirmed\nEOF\necho safe > target.md'
  payload=$(jq -nc --arg dir "$WORK" --arg command "$command" \
    '{tool_name:"Bash",tool_input:{workdir:$dir,command:$command}}')
  run dispatch "$payload" "$CHILD"
  [ "$status" -eq 0 ]
  grep -Fq $'target.md\tsafe' "$TRACE"
  ! grep -Fq 'human-oversight: confirmed' "$TRACE"

  : > "$TRACE"
  payload=$(jq -nc --arg dir "$WORK" \
    '{tool_name:"Bash",tool_input:{workdir:$dir,command:"echo secret; printf safe | tee other.md"}}')
  run dispatch "$payload" "$CHILD"
  [ "$status" -eq 0 ]
  grep -Fq $'other.md\tsafe' "$TRACE"
  ! grep -Fq secret "$TRACE"
}

@test "unsupported shell control structures and dynamic targets do not produce guessed events" {
  for command in \
    'f() { echo x > never-written.md; }' \
    'if false; then echo x > never-written.md; fi' \
    'echo x > "$DESTINATION"' \
    'echo "$(printf \"> never-written.md\")"'; do
    payload=$(jq -nc --arg dir "$WORK" --arg command "$command" \
      '{tool_name:"Bash",tool_input:{workdir:$dir,command:$command}}')
    run dispatch "$payload" "$CHILD"
    [ "$status" -eq 0 ]
    [ ! -e "$TRACE" ]
  done
}

@test "quoted literal shell metacharacters retain their actual target names" {
  command='echo x > "\$literal.md"'
  payload=$(jq -nc --arg dir "$WORK" --arg command "$command" \
    '{tool_name:"Bash",tool_input:{workdir:$dir,command:$command}}')
  run dispatch "$payload" "$CHILD"
  [ "$status" -eq 0 ]
  grep -Fq "$WORK/"'$literal.md' "$TRACE"
  ! grep -Fq '\$literal.md' "$TRACE"
}

@test "only the final stdout redirection receives the command output" {
  payload=$(jq -nc --arg dir "$WORK" \
    '{tool_name:"Bash",tool_input:{workdir:$dir,command:"echo marker > empty.md > written.md"}}')
  run dispatch "$payload" "$CHILD"
  [ "$status" -eq 0 ]
  [ "$(sed -n '1p' "$TRACE")" = $'Write\t'"$WORK/empty.md"$'\t' ]
  grep -Fq $'written.md\tmarker' "$TRACE"
}

@test "inferred content matches native Bash for input descriptors and echo options" {
  run python3 - "$HELPER" "$WORK" <<'PY'
import json
from pathlib import Path
import subprocess
import sys

helper, work = sys.argv[1:]
child = Path(work) / "event.sh"
child.write_text("#!/bin/bash\ncat\n")
child.chmod(0o755)
commands = [
    "echo 'human-oversight: confirmed' | tee target.md < /dev/null",
    "cat 3<<'EOF' > target.md\nhuman-oversight: confirmed\nEOF",
    "cat <<'EOF' < /dev/null > target.md\nhuman-oversight: confirmed\nEOF",
    "cat < /dev/null <<'EOF' > target.md\nsafe\nEOF",
    "echo -n -e 'human-oversight:\\x20confirmed' > target.md",
    "echo -n -n marker > target.md",
]
for command in commands:
    subprocess.run(["/bin/bash", "-c", command], cwd=work,
                   stdin=subprocess.DEVNULL, capture_output=True, check=True)
    actual = (Path(work) / "target.md").read_text()
    payload = {"tool_name": "Bash", "tool_input": {"workdir": work, "command": command}}
    result = subprocess.run(["/bin/bash", helper, str(child)],
                            input=json.dumps(payload), text=True, capture_output=True, check=True)
    event, = map(json.loads, result.stdout.splitlines())
    inferred = event["tool_input"].get("content")
    assert inferred is None or inferred == actual, (command, inferred, actual)
    if "3<<" not in command and not command.startswith("echo"):
        assert inferred == actual, (command, inferred, actual)
PY
  [ "$status" -eq 0 ]
}

@test "child denial and execution failure survive dispatch" {
  deny="$WORK/deny.sh"
  printf '#!/bin/bash\necho "{\"decision\":\"deny\"}"\n' > "$deny"
  chmod +x "$deny"
  payload=$(jq -nc --arg dir "$WORK" \
    '{tool_name:"Bash",tool_input:{workdir:$dir,command:"echo x > target.md"}}')
  run dispatch "$payload" "$deny" "$CHILD"
  [ "$status" -eq 0 ]
  [[ "$output" == *deny* ]]
  [ ! -e "$TRACE" ]
  run dispatch "$payload" /usr/bin/false "$CHILD"
  [ "$status" -eq 1 ]
  [ ! -e "$TRACE" ]
}

@test "sync is repeatable and check rejects a divergent packaged copy" {
  fake="$WORK/repo"
  mkdir -p "$fake/scripts" "$fake/packages/shared/hooks/lib"
  cp "$REPO_ROOT/scripts/sync-bash-write-dispatch.sh" "$fake/scripts/"
  cp "$HELPER" "$fake/packages/shared/hooks/lib/"
  for plugin in architect jtbd style-guide voice-tone tdd; do
    mkdir -p "$fake/packages/$plugin/hooks"
  done
  run bash "$fake/scripts/sync-bash-write-dispatch.sh"
  [ "$status" -eq 0 ]
  run bash "$fake/scripts/sync-bash-write-dispatch.sh" --check
  [ "$status" -eq 0 ]
  run bash "$fake/scripts/sync-bash-write-dispatch.sh"
  [ "$status" -eq 0 ]
  for plugin in architect jtbd style-guide voice-tone tdd; do
    cmp "$HELPER" "$fake/packages/$plugin/hooks/bash-write-dispatch.sh"
  done
  printf '\n# divergence\n' >> "$fake/packages/jtbd/hooks/bash-write-dispatch.sh"
  run bash "$fake/scripts/sync-bash-write-dispatch.sh" --check
  [ "$status" -eq 1 ]
  [[ "$output" == *DIVERGED*jtbd* ]]
}

@test "heredoc marker writes require the existing session-scoped evidence" {
  project="$WORK/project"
  markers="$WORK/markers"
  mkdir -p "$project/docs/decisions" "$markers"
  adr="$project/docs/decisions/001-test.proposed.md"
  sid="bash-write-test-$$"
  command=$'cat > docs/decisions/001-test.proposed.md <<\'EOF\'\nhuman-oversight: confirmed\nEOF'
  payload=$(jq -nc --arg dir "$project" --arg command "$command" --arg sid "$sid" \
    '{tool_name:"Bash",session_id:$sid,tool_input:{workdir:$dir,command:$command}}')
  discipline="$REPO_ROOT/packages/architect/hooks/architect-oversight-marker-discipline.sh"

  run bash -c 'cd "$1" && printf "%s" "$2" | SESSION_MARKER_DIR="$3" bash "$4" "$5"' \
    _ "$project" "$payload" "$markers" "$HELPER" "$discipline"
  [ "$status" -eq 0 ]
  [[ "$output" == *'BLOCKED:'* ]]

  bash "$REPO_ROOT/packages/architect/scripts/mark-oversight-confirmed.sh" "$adr"
  post=$(jq -nc --arg p "$adr" --arg sid "$sid" \
    '{tool_name:"Bash",session_id:$sid,tool_input:{command:("wr-architect-mark-oversight-confirmed " + $p)},tool_response:{is_error:false}}')
  printf '%s' "$post" | SESSION_MARKER_DIR="$markers" bash "$REPO_ROOT/packages/architect/hooks/architect-slide-marker.sh"

  run bash -c 'cd "$1" && printf "%s" "$2" | SESSION_MARKER_DIR="$3" bash "$4" "$5"' \
    _ "$project" "$payload" "$markers" "$HELPER" "$discipline"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "tee sends every explicit output target through the child hook" {
  payload=$(jq -nc --arg dir "$WORK" '{tool_name:"Bash",tool_input:{workdir:$dir,command:"printf x | tee docs/a.md docs/b.md >/dev/null"}}')

  run dispatch "$payload" "$CHILD"

  [ "$status" -eq 0 ]
  [ "$(wc -l < "$TRACE" | tr -d " ")" -eq 2 ]
  grep -Fq $'Write\t'"$WORK/docs/a.md" "$TRACE"
  grep -Fq $'Write\t'"$WORK/docs/b.md" "$TRACE"
  ! grep -Fq '/dev/null' "$TRACE"
}

@test "post-write fan-out runs both TDD routes even when the first emits context" {
  post="$WORK/tdd-post-write.sh"
  review="$WORK/tdd-review-test.sh"
  printf '#!/bin/bash\necho tdd-post-write.sh >> "$TRACE"\necho context\n' > "$post"
  printf '#!/bin/bash\necho tdd-review-test.sh >> "$TRACE"\n' > "$review"
  chmod +x "$post" "$review"
  payload=$(jq -nc --arg dir "$WORK" '{tool_name:"Bash",tool_input:{workdir:$dir,command:"echo x > src/a.js"}}')

  run dispatch "$payload" --all "$post" "$review"

  [ "$status" -eq 0 ]
  [ "$output" = "context" ]
  [ "$(cat "$TRACE")" = $'tdd-post-write.sh\ntdd-review-test.sh' ]
}

@test "the four direct-hook plugins execute the registered pre and post write routes" {
  run python3 - "$REPO_ROOT" "$WORK" <<'PY'
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

root = Path(sys.argv[1])
expected = {
    "jtbd": {"PreToolUse": ["jtbd-enforce-edit.sh", "jtbd-oversight-marker-discipline.sh"]},
    "style-guide": {"PreToolUse": ["style-guide-enforce-edit.sh"]},
    "voice-tone": {"PreToolUse": ["voice-tone-enforce-edit.sh"]},
    "tdd": {"PreToolUse": ["tdd-enforce-edit.sh"],
            "PostToolUse": ["tdd-post-write.sh", "tdd-review-test.sh"]},
}
for package, phases in expected.items():
    fake = Path(sys.argv[2]) / ("plugin with spaces " + package)
    (fake / "hooks").mkdir(parents=True)
    helper = fake / "hooks/bash-write-dispatch.sh"
    shutil.copyfile(root / "packages/shared/hooks/lib/bash-write-dispatch.sh", helper)
    helper.chmod(0o755)
    trace = fake / "trace"
    for children in phases.values():
        for child in children:
            script = fake / "hooks" / child
            script.write_text("#!/bin/bash\n"
                              "jq -e '.tool_name == \"Write\" and "
                              "(.tool_input.file_path | endswith(\"/src/test.js\"))' >/dev/null || exit 7\n"
                              f"echo {child} >> \"$TRACE\"\n")
            script.chmod(0o755)
    hooks = json.loads((root / "packages" / package / "hooks" / "hooks.json").read_text())
    for phase, children in phases.items():
        trace.unlink(missing_ok=True)
        commands = [hook["command"] for entry in hooks["hooks"][phase]
                    if "Bash" in entry.get("matcher", "") for hook in entry["hooks"]
                    if "bash-write-dispatch.sh" in hook["command"]]
        assert commands, (package, phase)
        for command in commands:
            payload = {"tool_name": "Bash", "tool_input": {
                "workdir": str(fake), "command": "echo x > src/test.js"}}
            subprocess.run(["/bin/bash", "-c", command], input=json.dumps(payload),
                           text=True, check=True, env={**os.environ,
                           "CLAUDE_PLUGIN_ROOT": str(fake), "TRACE": str(trace)})
        assert trace.read_text().splitlines() == children, (package, phase)
PY

  [ "$status" -eq 0 ]
}

@test "architect dispatches classified Bash writes through pre and post write routes" {
  fake="$WORK/architect"
  mkdir -p "$fake/hooks"
  cp "$REPO_ROOT/packages/architect/hooks/architect-dispatch.sh" "$fake/hooks/"
  cp "$HELPER" "$fake/hooks/"
  chmod +x "$fake/hooks/bash-write-dispatch.sh"
  for child in \
    architect-readme-pairing-check.sh architect-enforce-edit.sh \
    architect-oversight-marker-discipline.sh architect-slide-marker.sh \
    architect-refresh-hash.sh architect-compendium-update-entry.sh; do
    printf '#!/bin/bash\necho "%s" >> "$TRACE"\n' "$child" > "$fake/hooks/$child"
    chmod +x "$fake/hooks/$child"
  done
  payload=$(jq -nc --arg dir "$WORK" '{tool_name:"Bash",tool_input:{workdir:$dir,command:"echo x > docs/decisions/001-test.md"}}')

  run bash -c 'printf "%s" "$1" | TRACE="$2" bash "$3" pre-tool' _ "$payload" "$TRACE" "$fake/hooks/architect-dispatch.sh"
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE")" = $'architect-readme-pairing-check.sh\narchitect-enforce-edit.sh\narchitect-oversight-marker-discipline.sh' ]

  : > "$TRACE"
  run bash -c 'printf "%s" "$1" | TRACE="$2" bash "$3" post-tool' _ "$payload" "$TRACE" "$fake/hooks/architect-dispatch.sh"
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE")" = $'architect-slide-marker.sh\narchitect-refresh-hash.sh\narchitect-compendium-update-entry.sh' ]
}
