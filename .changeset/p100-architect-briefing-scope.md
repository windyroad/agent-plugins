---
"@windyroad/architect": patch
---

P100 slice 1 — `architect-enforce-edit.sh` + `architect-detect.sh` extended to exempt `docs/briefing/*` from the architect edit gate, alongside the existing `docs/BRIEFING.md` exemption. Adopter projects that adopt the `docs/briefing/` tree layout (split-per-topic briefing introduced in P100 slice 1) no longer trip architect review on every retrospective append. Scope bats test added to assert the SCOPE prose advertisement.
