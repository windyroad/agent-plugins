---
"@windyroad/itil": patch
---

Close provenance-proven issues on your own tracker

When a problem ticket closed on evidence the agent had gathered itself, we stopped short of closing the originating GitHub issue — on both the issue we filed on someone else's repository and the report someone filed on ours. The reasoning was that the close belonged to the reporter.

That was right for one of those and wrong for the other. A report filed on your own repository is your tracker. It should say what you believe, and the reporter can reopen after reading the lifecycle comment. Before any issue operation, the inbound path now requires one exact issue-channel match in the committed discovery cache. Missing, ambiguous, discussion, advisory, repository-mismatched, or wrong-ticket provenance fails closed without reading or mutating an issue.

The proven inbound issue now closes whether the local close came from confirmation or cited evidence. An issue filed elsewhere stays open on local evidence alone because its maintainers hold their own triage; their confirmation can authorize closure. Pull requests remain comment-only.
