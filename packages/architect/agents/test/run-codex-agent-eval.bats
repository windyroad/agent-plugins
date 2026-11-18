#!/usr/bin/env bats

setup() {
  DRIVER="${BATS_TEST_DIRNAME}/../eval/run-codex-agent-eval.sh"
  TMP="$(mktemp -d)"
  mkdir -p "$TMP/bin"
  export PATH="$TMP/bin:$PATH"
  export WR_CODEX_EVAL_CODEX_HOME="$TMP/codex-home"
  export CAPTURE_CODEX_ARGS="$TMP/args"
  export WR_CODEX_EVAL_PROFILE_MANIFEST="$TMP/profile.json"
  cat > "$TMP/bin/npm" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == pack ]]; then
  while [[ "$1" != --pack-destination ]]; do shift; done
  touch "$2/fixture.tgz"
else
  mkdir -p "$CODEX_HOME/agents"
  touch "$CODEX_HOME/agents/wr-architect-agent.toml" "$CODEX_HOME/agents/wr-architect-cog-a11y.toml"
fi
MOCK
  cat > "$TMP/bin/codex" <<'MOCK'
#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
args=sys.argv[1:]
Path(os.environ['CAPTURE_CODEX_ARGS']).write_bytes(('\0'.join(args)+'\0').encode())
model=args[args.index('--model')+1]
effort=next(value.split('=',1)[1].strip('"') for value in args if value.startswith('model_reasoning_effort='))
role='wr-architect-cog-a11y' if 'named wr-architect-cog-a11y' in args[-1] else 'wr-architect:agent'
verdict='Architecture Review: PASS\n'
Path(args[args.index('--output-last-message')+1]).write_text(verdict)
print(json.dumps({'type':'thread.started','thread_id':'current-parent'}))
root=Path(os.environ['CODEX_HOME'])/'sessions'; root.mkdir(parents=True,exist_ok=True)
parent=[{'type':'session_meta','payload':{'id':'current-parent','source':'exec'}},
        {'type':'turn_context','payload':{'model':model,'effort':effort}}]
(root/'parent.jsonl').write_text(''.join(json.dumps(r)+'\n' for r in parent))
if os.environ.get('FAKE_OMIT_CHILD')!='1':
 rows=[{'type':'session_meta','payload':{'id':'reviewer-child','source':{'subagent':{'thread_spawn':{
   'parent_thread_id':os.environ.get('FAKE_CHILD_PARENT','current-parent'),'agent_role':role}}}}},
   {'type':'turn_context','payload':{'model':model,'effort':effort}},
   {'type':'response_item','payload':{'type':'message','role':'assistant','phase':'final_answer',
    'content':[{'type':'output_text','text':verdict}]}},
   {'type':'turn_context','payload':{'model':os.environ.get('FAKE_CHILD_MODEL',model),
     'effort':os.environ.get('FAKE_CHILD_EFFORT',effort)}},
   {'type':'response_item','payload':{'type':'message','role':'assistant','phase':'final_answer',
    'content':[{'type':'output_text','text':os.environ.get('FAKE_CHILD_TEXT',verdict)}]}}]
 if os.environ.get('FAKE_MALFORMED_SOURCE')=='1':
  rows[0]['payload']['source']={'subagent':'review'}
 (root/'child.jsonl').write_text(''.join(json.dumps(r)+'\n' for r in rows))
MOCK
  chmod +x "$TMP/bin/npm" "$TMP/bin/codex"
}

teardown() {
  rm -rf "$TMP"
}

@test "Codex review receives the scenario without provider metadata" {
  run bash "$DRIVER" 'original scenario' 'SECRET GRADER METADATA'
  [ "$status" -eq 0 ]
  python3 - "$CAPTURE_CODEX_ARGS" <<'PY'
from pathlib import Path
import sys
args=Path(sys.argv[1]).read_bytes().decode().split('\0')[:-1]
assert args[0]=='exec'
assert args[-1].endswith('\n\noriginal scenario')
assert 'SECRET GRADER METADATA' not in '\n'.join(args)
assert 'named wr-architect:agent' in args[-1]
assert not Path(args[args.index('--cd')+1]).exists()
PY
}

@test "Codex review keeps cognitive dispatch and strips its selector prefix" {
  run bash "$DRIVER" '[COG_A11Y]cognitive scenario' 'SECRET GRADER METADATA'
  [ "$status" -eq 0 ]
  python3 - "$CAPTURE_CODEX_ARGS" <<'PY'
from pathlib import Path
import sys
prompt=Path(sys.argv[1]).read_bytes().decode().split('\0')[-2]
assert 'named wr-architect-cog-a11y' in prompt
assert prompt.endswith('\n\ncognitive scenario')
assert '[COG_A11Y]' not in prompt and 'SECRET GRADER METADATA' not in prompt
PY
}

@test "Codex review rejects an empty scenario even if metadata follows" {
  run bash "$DRIVER" '' 'SECRET GRADER METADATA'
  [ "$status" -eq 2 ]
  [[ "$output" == *'prompt argument is required'* ]]
  [ ! -e "$CAPTURE_CODEX_ARGS" ]
}

@test "Codex evaluation forwards the declared profile and reports actual child evidence" {
  run bash "$DRIVER" 'original scenario'
  [ "$status" -eq 0 ]
  python3 - "$CAPTURE_CODEX_ARGS" "$WR_CODEX_EVAL_PROFILE_MANIFEST" <<'PY'
from pathlib import Path
import json,sys
args=Path(sys.argv[1]).read_bytes().decode().split('\0')[:-1]
assert args[args.index('--model')+1]=='gpt-6.1-sol'
assert 'model_reasoning_effort="medium"' in args and '--ephemeral' not in args
manifest=json.loads(Path(sys.argv[2]).read_text())
assert manifest['verified'] is True
assert manifest['children'][0]['profile']=={'model':'gpt-6.1-sol','effort':'medium'}
assert manifest['children'][0]['returned_verdict_matches'] is True
PY
}

@test "a matching parent and historical turn cannot conceal a different child model" {
  export FAKE_CHILD_MODEL=other-model
  run bash "$DRIVER" 'original scenario'
  [ "$status" -eq 3 ]
  [[ "$output" == *'reviewer-child profile differs'* ]]
}

@test "Codex evaluation rejects an actual child reasoning mismatch" {
  export FAKE_CHILD_EFFORT=none
  run bash "$DRIVER" 'original scenario'
  [ "$status" -eq 3 ]
}

@test "parent metadata alone cannot verify the reviewer target" {
  export FAKE_OMIT_CHILD=1
  run bash "$DRIVER" 'original scenario'
  [ "$status" -eq 3 ]
  [[ "$output" == *'no reviewer-child final matches'* ]]
}

@test "Codex evaluation binds the returned verdict to the actual child" {
  export FAKE_CHILD_TEXT='A different child response'
  run bash "$DRIVER" 'original scenario'
  [ "$status" -eq 3 ]
}

@test "an old parent cannot supply profile proof for the current request" {
  export FAKE_CHILD_PARENT=earlier-parent
  run bash "$DRIVER" 'original scenario'
  [ "$status" -eq 3 ]
}

@test "unrecognized subagent metadata still emits an honest manifest" {
  export FAKE_MALFORMED_SOURCE=1
  run bash "$DRIVER" 'original scenario'
  [ "$status" -eq 3 ]
  python3 - "$WR_CODEX_EVAL_PROFILE_MANIFEST" <<'PY'
from pathlib import Path
import json,sys
manifest=json.loads(Path(sys.argv[1]).read_text())
assert manifest['verified'] is False and manifest['error']
PY
}
