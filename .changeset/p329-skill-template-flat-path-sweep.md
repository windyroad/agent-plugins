---
"@windyroad/itil": patch
---

P329: sibling SKILL.md path templates updated to ADR-031 per-state-subdir layout. 5 SKILLs swept (manage-problem, review-problems, transition-problem, transition-problems, reconcile-readme) — `git mv` blocks + path templates + grep patterns now use `docs/problems/<state>/<NNN>-<title>.md` instead of pre-ADR-031 flat `docs/problems/<NNN>-<title>.<state>.md`. capture-rfc out of scope (RFCs use flat layout; ADR-031 covers docs/problems/ only).
