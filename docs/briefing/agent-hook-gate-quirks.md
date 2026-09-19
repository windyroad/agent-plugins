# Agent + Hook Gate Quirks

Cross-session learnings about shell/filesystem traps that make gate helpers fail silently, and about the outstanding-questions queue's missing drain. Sibling to `agent-interaction-patterns.md` (broader interaction-discipline surface). Split out 2026-05-03 per P145 MUST_SPLIT contract for Tier 3 budget compliance.

> The architect marker mechanics moved to [`architect-gate-marker-mechanics.md`](./architect-gate-marker-mechanics.md) on 2026-07-26 per the P099 Tier 3 budget rotation. It now records caller-bound completion, strict canonical bold/H2 verdict parsing, and fail-closed recovery without manufactured markers. Load it alongside this file when working an architect-gated edit.

> Older entries rotated to [`agent-hook-gate-quirks-archive.md`](./agent-hook-gate-quirks-archive.md) per the P099 Tier 3 budget: the 2026-04-25 → 2026-05-03 cohort on 2026-06-17 (duplicate-bypass warning, persona-vs-runtime-mode rule, runtime-SID instrumentation, architect-agent re-invoke pattern), then the 2026-06-17 cohort on 2026-07-26 (the macOS `find /tmp` symlink trap, the `grep` binary-classification trap on em-dashed markdown, and the outstanding-questions queue's missing drain). Load alongside this file for full historical context. Added 2026-09-19: the three-deep `docs/rfcs/` create-gate stack (rotated at signal-score -3) and the stale-`git status` reviewer entry (2026-08-21).

## What Will Surprise You

- **Style-guide and voice-tone reviewers are intentionally read-only; their canonical output heading is the verdict.** P469 confirmed the old PostToolUse hooks did not consume that output: they read stale global `/tmp/*-verdict` files and treated an absent file as PASS. The fixed hooks parse the first recognised heading from the completed `Agent` output and write markers only for exact PASS; never write a verdict file for the reviewer. Installed caches retain the old behaviour until the patched packages are released and refreshed. <!-- signal-score: -2 | last-classified: 2026-08-30 | first-written: 2026-07-26 -->

### The JTBD gate blocks appending a RATIFIED `@jtbd` line to a block that already cites an unratified job (2026-09-19)

The build-upon guard keys on the citation manifest of the edited file, not on what the edit adds. Appending `# @jtbd JTBD-202` / `# @jtbd JTBD-101` — both ratified, adding no new assertion — to a header block that already carried three unratified jobs was read as "re-authoring that citation manifest" and blocked as an [Unratified Dependency]. The reviewer had prescribed that exact migration on its own prior pass. The prescribed remedy is `/wr-jtbd:confirm-jobs-and-personas`, which needs `AskUserQuestion` and so has no AFK path (P470's root, second witness).

Budget for it: assume any edit to a file carrying `@jtbd` annotations is gated by the ratification state of EVERY job named in the block, and check that state before planning the edit — `wr-jtbd-is-job-or-persona-unconfirmed <ID>` exits 0 for unratified. If any is unratified and you are AFK, plan the slice so it does not touch that file at all, rather than discovering it after the spawn. A P290 iteration narrowed three times across four reviewer spawns learning this.

Watch for the case where the drain cannot be run in full either: a job can be held unratified deliberately because a merge-blocking eval fixture hard-codes it as its unratified subject, so ratifying it reds CI. Scope the drain to the jobs that are safe to confirm and record the excluded one.

<!-- signal-score: 2 | last-classified: 2026-09-19 | first-written: 2026-09-19 -->
