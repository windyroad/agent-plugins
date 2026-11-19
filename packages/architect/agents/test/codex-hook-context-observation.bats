#!/usr/bin/env bats

@test "hook observation attributes only original developer context in the exact parent" {
  run python3 - "$BATS_TEST_DIRNAME/../eval/verify-codex-eval-profile.py" <<'PY'
import importlib.util,json,sys,tempfile
from pathlib import Path
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location('verifier',sys.argv[1]);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
with tempfile.TemporaryDirectory() as tmp:
 root=Path(tmp);(root/'sessions').mkdir();events=root/'events';events.write_text(json.dumps({'type':'thread.started','thread_id':'parent'})+'\n');out=root/'output';out.write_text('Architecture Review: PASS')
 meta=lambda id,source:{'type':'session_meta','payload':{'id':id,'source':source}}
 message=lambda role,text:{'type':'response_item','payload':{'type':'message','role':role,'content':[{'type':'input_text','text':text}]}}
 child=[meta('child',{'subagent':{'thread_spawn':{'parent_thread_id':'parent','agent_role':'wr-architect:agent'}}}),{'type':'turn_context','payload':{'model':'model','effort':'medium'}},{'type':'response_item','payload':{'type':'message','role':'assistant','phase':'final_answer','content':[{'type':'output_text','text':out.read_text()}]}},message('developer',m.EXPECTED_NOTICE)]
 (root/'sessions/child.jsonl').write_text(''.join(json.dumps(x)+'\n' for x in child))
 def verify(records):
  (root/'sessions/parent.jsonl').write_text(''.join(json.dumps(x)+'\n' for x in [meta('parent','exec')]+records))
  return m.verify(root,events,out,'model','medium','wr-architect:agent',0)
 result=verify([message('developer','Hook context:\n'+m.EXPECTED_NOTICE)])
 assert result['verified'] is True and result['parent_hook_context']['status']=='observed'
 record=result['parent_hook_context']['records'][0]
 assert record['session_id']=='parent' and record['record_line']==2 and len(record['message_sha256'])==64
 assert m.EXPECTED_NOTICE not in json.dumps(result)
 for role in ['user','assistant','system']:
  result=verify([message(role,m.EXPECTED_NOTICE)])
  assert result['verified'] is True and result['parent_hook_context']['status']=='unverified',role
 for content in [None,{},['opaque'],[{'type':'input_text','text':None}]]:
  malformed=message('developer','unused');malformed['payload']['content']=content
  result=verify([malformed])
  assert result['verified'] is True and result['parent_hook_context']['status']=='unverified'
 # Child developer text and an unrelated parent's developer text cannot supply proof.
 (root/'sessions/other.jsonl').write_text(json.dumps(meta('other','exec'))+'\n'+json.dumps(message('developer',m.EXPECTED_NOTICE))+'\n')
 result=verify([{'type':'response_item','payload':{'type':'function_call_output','output':m.EXPECTED_NOTICE}}])
 assert result['verified'] is True and result['parent_hook_context']['records']==[]
PY
  [ "$status" -eq 0 ] || { printf '%s\n' "$output"; return 1; }
}
