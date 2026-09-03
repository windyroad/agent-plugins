---
"@windyroad/risk-scorer": minor
---

The merge guard now stands in front of the release pull request only. Merging the changesets release PR is still routed to your release-watch script, because that merge flips the publish boundary and the watcher is what follows the pipeline afterwards. An ordinary feature or worktree branch PR merges normally.

The guard reads the pull request's head branch to tell the two apart, including for `gh pr merge` with no argument. If it cannot read the branch — no `gh`, no auth, no network — it denies, exactly as before.
