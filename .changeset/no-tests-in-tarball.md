---
"@windyroad/itil": patch
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/retrospective": patch
"@windyroad/tdd": patch
"@windyroad/voice-tone": patch
"@windyroad/style-guide": patch
"@windyroad/connect": patch
"@windyroad/cruise": patch
---

Published packages no longer carry their own tests.

Every plugin was shipping its bats suites inside the tarball — 171 files in `@windyroad/itil` alone, 257 across the suite. They were never part of the plugin. They exist to verify it, and they went out with it because `files` listed `scripts/` and `skills/` wholesale, with a single carve-out for evals that was never generalised.

The weight is the smaller half. `@windyroad/itil` drops from 885 kB to 525 kB and the others fall in proportion. What matters more is that thirteen of those tests read the repository they were written in: they lint its stories and story maps, grep its problem tickets, open three of its decision records by filename, and read its own upstream-channel configuration. An adopter running them is told about artefacts they have never had.

Nothing invoked a test at runtime, so nothing that worked before stops working. Templates, libraries, hooks, skills, agents and the `$PATH` shims all still ship — the packaged-tarball render test still packs, extracts and renders from outside the repository.

A new check asserts this against `npm pack --dry-run` rather than against the `files` array, because the array is the input and the tarball is the outcome. It found two packages missed on the first pass, which is the argument for testing the outcome.

Separating a test that verifies a plugin from one that verifies a project's use of it is the larger question, and it is tracked rather than settled here.
