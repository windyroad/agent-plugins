---
"@windyroad/itil": patch
---

P330 Option B: seed `**Release vehicle**: .changeset/<name>.md` paragraph in ticket Fix Strategy BEFORE the `git mv` to `.verifying.md`.

manage-problem SKILL.md Step 7 + transition-problem SKILL.md Step 6 (copy-not-move per ADR-010 amended / P093) now instruct authors to append the Release-vehicle reference to the `.known-error.md` ticket body before the K→V rename. Closes the `wr-itil-derive-release-vehicle` helper's exit-2 routing on standalone K→V iters (3 of 4 dogfoods in the 2026-05-30 AFK session hit exit-2; P316 / P281 / P302). Helper contract unchanged; legacy-ticket exit-2 routing remains as the documented recovery path. Two P057 staging-trap windows (seed + rename) consolidate into the existing single `git add` of the `.verifying.md` path — `git mv` rides the post-seed index entry across the rename.

Structural bats backstop at `packages/itil/skills/manage-problem/test/manage-problem-release-vehicle-seed.bats` carries the ADR-052 § Surface 2 `tdd-review: structural-permitted` marker citing P330 Investigation Task #3 as the deferred-retrofit anchor for the behavioural K→V-mock test.
