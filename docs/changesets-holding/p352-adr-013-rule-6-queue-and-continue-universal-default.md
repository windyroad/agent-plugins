---
"@windyroad/itil": patch
"@windyroad/architect": patch
"@windyroad/retrospective": patch
---

P352: ADR-013 Rule 6 amended (2026-06-06) — queue-and-continue is the universal AFK default when a skill needs to ask but AskUserQuestion is unavailable. HALT/SKIP/AUTO-DEFAULT become deviations requiring inline-cited carve-out justification. Documented carve-outs preserved: capture-problem derive-then-ratify HALT (ADR-074); create-adr Step 5 substance-confirm HALT (ADR-074); create-adr Step 1 + manage-problem Step 4b multi-decision/multi-concern AUTO-DEFAULT (ADR-044 cat 4); review-problems Step 4.5a malformed-JSON SKIP (user-shipped artefact protection). SKILL.md sweep added carve-out audit annotations at capture-problem / create-adr / manage-problem / review-problems / scaffold-intake / run-retro. 19 new structural bats green asserting amendment prose + per-SKILL audit annotations. Shared-helper extraction (packages/itil/lib/outstanding-questions.sh) deferred to follow-on per the ratified design.
