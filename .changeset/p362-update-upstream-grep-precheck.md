---
"@windyroad/itil": patch
---

Skip the `/wr-itil:update-upstream` dispatch when a transitioning problem ticket carries no `## Reported Upstream` section. Previously both lifecycle-update trigger sites — `manage-problem` Step 7 and `transition-problem` Step 7b — dispatched the sibling skill on every status transition, loading its full SKILL.md into the calling agent's context just to reach a no-op exit. The common case is a ticket that was never reported upstream, so that context load was wasted on every transition-bearing iteration. Both sites now run a one-line `grep -q '^## Reported Upstream'` pre-check first and dispatch only when the section exists. Observable behaviour is unchanged: an upstream lifecycle comment still posts if and only if the ticket carries the section, and the sibling skill keeps its own no-op exit as a backstop for any path that reaches it directly.
