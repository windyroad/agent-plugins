---
"@windyroad/itil": patch
"@windyroad/architect": patch
---

Document the `git mv` + Edit + `git add` staging-ordering trap (P057) in `manage-problem` Step 7 and `create-adr` Step 6. `git mv` alone stages only the rename — subsequent `Edit`-tool modifications must be re-staged explicitly (`git add <new>`) before commit. Without the re-stage, transition commits capture the rename but drop the `Status:` / `## Fix Released` content edits, which then leak into an unrelated later commit and corrupt the audit trail (observed 2026-04-19 in P054's `.verifying.md` transition).

Changes:
- `manage-problem` Step 7: new warning block applying to all three transition arrows (Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed), plus an explicit `git add <new>` line in each code block.
- `manage-problem` Step 11: commit convention now recommends `git add -u` as a safety-net for tracked modifications.
- `create-adr` Step 6: supersession rename now instructs authors to `git add` the file again after the frontmatter + "Superseded by" edits.
- Two new bats doc-lint tests guard the contract in both SKILL.md files.
