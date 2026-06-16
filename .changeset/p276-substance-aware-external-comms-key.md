---
"@windyroad/risk-scorer": patch
"@windyroad/voice-tone": patch
---

P276 — substance-aware draft normalization in compute_external_comms_key (orchestrator salvage of iter 24)

`compute_external_comms_key` (in `packages/{shared,risk-scorer,voice-tone}/hooks/lib/external-comms-key.sh`) now applies substance-aware normalization to drafts before hashing: CRLF/CR → LF, per-line trailing-whitespace strip, whole-draft trailing-whitespace strip. This brings parity with the ADR-009 `_substance_normalize_then_hash` precedent.

**Key shape unchanged** — `sha256(normalize(draft) + '\n' + surface)` with NO trailing `\n` appended to the normalized draft, so existing session markers and all prior key computations are byte-stable.

**Conservative boundary preserved** — single-numeral edits and frontmatter-key changes stay substantive (key changes, review re-fires); leak-detection guarantee never weakened. Only interior CRLF / per-line trailing-whitespace reformatting (semantically PASS-class) now survives without redundant re-review.

ADR-028 carries the Amendment 2026-06-16 P276 follow-on entry. 7 new behavioural bats GREEN.
