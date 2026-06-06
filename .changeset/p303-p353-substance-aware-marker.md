---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/voice-tone": patch
"@windyroad/style-guide": patch
"@windyroad/risk-scorer": patch
---

Substance-aware drift detection + atomic verdict-write for the governance gate libs. Closes P303 (architect-gate multi-decision-file deadlock — drift-relock facet) and P353 (hash-marker brittleness umbrella class root cause).

The shared `gate-helpers.sh` lib (byte-identical across architect / jtbd / voice-tone / style-guide / risk-scorer) gains two helpers per the user-ratified contract (ADR-009 amendment 2026-06-06):

- `_substance_hash_path` — normalises CRLF / trailing whitespace / trailing newlines before hashing. Trivial post-PASS edits (whitespace, line-ending) no longer invalidate the marker. Conservative boundary preserved: single-numeral edits and frontmatter-key changes are still treated as substantive (re-review fires) — fail toward MORE governance when in doubt.
- `_atomic_mark_with_hash` — writes the marker + hash file as an atomic mktemp + rename pair. Either both files land or neither does. Closes the "marker doesn't land after PASS" failure mode P353 measured as ~12 subagent invocations + 3 `BYPASS_RISK_GATE=1` uses per 3-filing session.

`review-gate.sh` (jtbd / voice-tone / style-guide) and `architect-gate.sh` route their drift check through `_substance_hash_path`; `store_review_hash` + `architect-mark-reviewed.sh` + `architect-refresh-hash.sh` route the verdict-write through `_atomic_mark_with_hash`. ADR-028 carries the cross-amendment for the external-comms gate. 25 new behavioural bats green across architect / jtbd / voice-tone / style-guide; 259/259 existing hook bats remain green.
