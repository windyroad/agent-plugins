---
"@windyroad/itil": patch
---

Fix a false "unreleased" signal from `wr-itil-derive-release-vehicle` for graduated holding changesets. When a changeset is reinstated to `.changeset/` to await changelog attribution after its code has already shipped with a sibling release (the ADR-061 graduation flow, where held code ships regardless per P359), the helper previously exited 3 ("changeset still present in working tree — unreleased") because it equated presence in `.changeset/` with code not yet released. Under graduation those two conditions diverge, so Known Error to Verifying routing received a wrong signal and AFK iterations had to override it by hand. The helper now tests whether the commit that originally added the changeset is an ancestor of the latest `chore: version packages` commit; if so it emits a `de-facto-released (attribution pending)` citation and exits 0. A changeset added after the last release keeps its add-commit ahead of that bump, so it correctly stays exit 3.
