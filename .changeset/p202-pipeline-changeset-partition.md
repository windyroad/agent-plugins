---
"@windyroad/risk-scorer": patch
---

P202: pipeline-state.sh and pipeline.md agent contract now partition `.changeset/*.md` files by introducing-commit provenance.

- `pipeline-state.sh --unreleased` emits two distinct counts: `Pending changesets (commits unpushed): N` and `Queued changesets (commits already on origin): N`. Detection is per-file `git log <DEFAULT_BRANCH>..HEAD -- <file>`: non-empty OR untracked ⇒ Pending; empty AND tracked ⇒ Queued.
- `pipeline.md` Layer-1 scoring contract is amended with a new `### Layer 1 changeset partition (P202)` subsection: Queued changesets contribute zero release-risk at this commit's surface, and `RISK_REMEDIATIONS:` lines (such as `move-to-holding`) MUST NOT target queued-on-origin changesets.

Eliminates false-HIGH Layer-1 release-risk and the phantom `move-to-holding` remediation when changesets sit on origin awaiting only the release-PR merge to npm.
