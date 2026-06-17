---
"@windyroad/retrospective": minor
---

run-retro Step 2b: ADR-073 auto-create-RFC reassessment advisory

The fix-time RFC-trace gate auto-creates skeleton RFCs when a fix is proposed on a Known Error that has no RFC. Until now the only record of those auto-create events was an ephemeral line in the work-problems iteration summary, so the question ADR-073 asks you to revisit — are auto-created RFCs systematically under-scoped? — had no durable signal behind it.

A new advisory detector (`check-autocreate-rfc-scope.sh`, run via the `wr-retrospective-check-autocreate-rfc-scope` PATH shim) reads the auto-created skeleton RFCs left on disk and surfaces the ones whose traced problem's fix has already shipped while the RFC's scope was never filled in. run-retro Step 2b reports them in the retro summary's Pipeline Instability section. The detector is advisory only — it always exits 0 and never blocks a commit. A one-off finding is the normal living-RFC pattern; a recurring population across retros is the ADR-073 reassessment trigger. (P314, RFC-005 B9)
