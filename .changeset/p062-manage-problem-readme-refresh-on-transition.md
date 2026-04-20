---
"@windyroad/itil": patch
---

**manage-problem**: refresh `docs/problems/README.md` on every Step 7 status transition and stage it in the same commit (closes P062).

Before this change, status transitions (Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed, Parked) did NOT refresh the README.md cache — only the `review` operation did. The next session's fast-path freshness check correctly detected the lag and forced a full rescan (self-healing but wasteful), and human readers browsing README.md between sessions saw outdated WSJF rankings and an incomplete Verification Queue.

SKILL.md Step 7 now includes a dedicated "README.md refresh on every transition (P062)" block describing the mechanism (regenerate in-place with the new filename set and Status; stage in the same commit; update the "Last reviewed" parenthetical). Step 11 commit convention requires `docs/problems/README.md` in the transition commit's stage list — including folded-fix commits where the `.verifying.md` transition rides with a `fix(<scope>): ...` commit.

The refresh is a render, not a re-rank: existing WSJF values on ticket files are trusted; no full re-scoring pass fires. That remains Step 9's job.

Cache stays fresh by construction — the Step 9 fast-path freshness check should return empty on any invocation after a transition commit.
