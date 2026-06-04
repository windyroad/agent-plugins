---
"@windyroad/voice-tone": patch
---

Agent prose: `wr-voice-tone:agent` and `wr-voice-tone:external-comms` now return PASS-with-advisory when `docs/VOICE-AND-TONE.md` is absent, rather than blanket FAIL on the missing-guide branch. Brings the agent prose into conformance with ADR-028's already-recorded per-evaluator advisory-only fallback (the canonical `external-comms-gate.sh` line 272 permits with advisory in this branch — the agent's verdict must agree). Sibling-consistent with the architect agent's existing graceful "If `docs/decisions/` itself does not exist, that is fine" pattern. The protective surface for projects that DO adopt voice-tone — `voice-tone-enforce-edit.sh` — remains BLOCKing on missing policy doc; only the reviewer agents' missing-guide path changes. Closes P200.
