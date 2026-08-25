---
"@windyroad/itil": minor
"@windyroad/retrospective": patch
---

Close verification-pending problems on evidence, instead of waiting for the maintainer

A problem ticket whose fix has shipped sits in Verification Pending until someone confirms the fix works. Until now "someone" meant you, personally, on every ticket — four skills reserved that transition for the maintainer's return. So an agent could run your test suite, watch the fix pass, and still decline to close the ticket. The queue had no exit path that did not route through you, and it only ever grew.

Evidence-backed closure is now the agent's call. When it can point at something it actually observed that meets a ticket's own close criterion — a test run and its outcome, a commit whose diff covers the fix, a skill or hook invocation that behaved as the fix contracts — it closes the ticket and records what it saw. The unattended `/wr-itil:work-problems` run drains the verification queue the same way, in a pass of its own, so verification still never competes with development work for a priority slot.

The half worth keeping is kept. Absence of evidence is not evidence: a fix nobody exercised stays open however old it is, and neither "the code is on disk" nor "a release shipped it" is an observation. Contested evidence and partial fixes still come to you. So does anything carrying a do-not-close marker — that is now a mechanical check (`wr-itil-is-close-blocked`) rather than a line of prose the next agent has to notice, and it outranks any evidence.

If a ticket came from someone else's bug report, closing it locally no longer closes their issue. We tell reporters we will wait for their confirmation; our own test passing is not that, so the upstream comment posts and the issue stays theirs to close.

Every close reports how to undo it, and `/wr-itil:transition-problem` now accepts the two backward moves that make it true: `<NNN> known-error` reopens a closed ticket, and the same command flips a verifying ticket back when a fix proves incomplete.
