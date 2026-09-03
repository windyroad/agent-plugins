---
"@windyroad/itil": minor
---

When two tickets claim the same number, the backlog reconciler now says so. It used to key its picture of the filesystem by ID, silently drop one of the two files, and then report ordinary-looking disagreement about whichever one survived — so the report named a symptom and buried its cause.

A clash is now its own row, naming both files, and the reconciler never defers it as something an in-flight rename will fix. `--fix-clashes` repairs it: the earlier claimant keeps the number, the later one moves to a free ID, and its own references follow it. Where a reference genuinely cannot be resolved — both tickets held that number — the reconciler reports it rather than guessing.
