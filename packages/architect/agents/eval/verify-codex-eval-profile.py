#!/usr/bin/env python3
"""Verify the returned verdict against its actual isolated reviewer child."""
import hashlib
import json
from pathlib import Path
import sys


def verify(home, events, output, model, effort, role, cli_status):
    result = {
        "requested": {"model": model, "effort": effort, "role": role},
        "cli_status": int(cli_status), "verified": False, "children": [],
    }
    try:
        starts = {
            event["thread_id"] for line in Path(events).read_text().splitlines()
            if (event := json.loads(line)).get("type") == "thread.started"
        }
        if len(starts) != 1:
            raise ValueError("missing or ambiguous parent thread identity")
        parent = next(iter(starts))
        result["parent_thread_id"] = parent
        returned = Path(output).read_text().strip()
        if not returned:
            raise ValueError("missing returned verdict")
        result["returned_sha256"] = hashlib.sha256(returned.encode()).hexdigest()

        for directory in ("sessions", "archived_sessions"):
            for path in (Path(home) / directory).rglob("*.jsonl"):
                with path.open() as stream:
                    first = json.loads(next(stream))
                    meta = first.get("payload", {})
                    source = meta.get("source", {})
                    if first.get("type") != "session_meta" or not isinstance(source, dict):
                        continue
                    subagent = source.get("subagent")
                    if not isinstance(subagent, dict):
                        continue
                    spawn = subagent.get("thread_spawn")
                    if not isinstance(spawn, dict):
                        continue
                    if spawn.get("parent_thread_id") != parent or spawn.get("agent_role") != role:
                        continue
                    profile = None
                    final = None
                    final_profile = None
                    for line in stream:
                        record = json.loads(line)
                        payload = record.get("payload", {})
                        if record.get("type") == "turn_context":
                            profile = {"model": payload.get("model"), "effort": payload.get("effort")}
                        elif (record.get("type") == "response_item"
                              and payload.get("type") == "message"
                              and payload.get("role") == "assistant"
                              and (payload.get("phase") == "final_answer" or payload.get("channel") == "final")):
                            # Forked history may contain earlier matching messages.
                            # Only the last final and its preceding context count.
                            final = "".join(
                                item.get("text", "") for item in payload.get("content", [])
                                if item.get("type") in ("output_text", "text")
                            ).strip()
                            final_profile = profile
                    result["children"].append({
                        "thread_id": meta.get("id"), "source": source,
                        "profile": final_profile, "returned_verdict_matches": final == returned,
                        "final_sha256": hashlib.sha256(final.encode()).hexdigest() if final is not None else None,
                    })
        matches = [child for child in result["children"] if child["returned_verdict_matches"]]
        if not matches:
            raise ValueError("no reviewer-child final matches the returned verdict")
        expected = {"model": model, "effort": effort}
        if any(child["profile"] != expected for child in matches):
            raise ValueError("reviewer-child profile differs from the declared target")
        if result["cli_status"] != 0:
            raise ValueError("Codex execution failed")
        result["verified"] = True
    except (OSError, ValueError, KeyError, StopIteration, TypeError) as error:
        result["error"] = str(error)
    return result


if __name__ == "__main__":
    manifest = verify(*sys.argv[1:])
    print(json.dumps(manifest))
    raise SystemExit(0 if manifest["verified"] else 3)
