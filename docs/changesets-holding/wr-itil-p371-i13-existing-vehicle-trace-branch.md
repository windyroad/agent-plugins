---
"@windyroad/itil": patch
---

manage-problem I13 propose-fix RFC-trace gate: add the existing-vehicle-untraced branch (P371)

The I13 fix-time RFC-trace gate previously offered only two responses to the predicate: empty stdout → proceed; `no-rfc-trace: P<NNN>` → auto-create a skeleton RFC. It had no branch for the case where an existing RFC is already the ticket's fix vehicle but simply hasn't wired the problem's trace edge into its `problems:` array — so following the directive literally produced a redundant duplicate RFC that fragmented the fix.

`manage-problem` SKILL.md now splits the non-empty-stdout branch into (a) existing-vehicle-untraced → wire the trace edge into the cited fix vehicle's `problems:` array (then `wr-itil-update-problem-rfcs-section` + re-run the predicate), and (b) no-vehicle → auto-create (unchanged). Distinguishing fix-vehicle from merely-related is a judgement read of citation context, kept skill-side per ADR-060 I1 (the deterministic membership predicate is unchanged). `work-problems` SKILL.md constraint #3 carries the matching AFK carve-out clause. ADR-073 auto-create is hereby scoped to the no-vehicle case only.
