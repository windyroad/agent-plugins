---
"@windyroad/risk-scorer": patch
---

Fix pipeline-state drift hash to be stable across `git push` (P054). Previously the `--hash-inputs` output of `packages/risk-scorer/hooks/lib/pipeline-state.sh` used `git diff origin/main --stat`, which shrinks to empty after a policy-authorised push advances `origin/main`, causing `npm run release:watch` to fire a spurious "Pipeline state drift" denial every time and forcing a rote mid-cycle delegation to `wr-risk-scorer:pipeline`. The hash now derives from a tree-based snapshot (via `git stash create`, falling back to `HEAD^{tree}` on a clean tree) of the conceptual "committed + index + working tree" content, which is invariant across both commit and push. Adds 8 regression tests in `pipeline-state-hash.bats`. Also documents the post-push stability contract in `scripts/release-watch.sh`.
