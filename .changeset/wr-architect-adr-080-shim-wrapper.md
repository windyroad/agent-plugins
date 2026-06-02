---
"@windyroad/architect": minor
---

ADR-080: `bin/wr-architect-*` shims now resolve to the highest-version cached sibling at every invocation (was: dispatch to own scripts/). Closes P343 mid-session staleness — `/install-updates` mid-session no longer requires Claude Code restart for shim resolution to pick up the new version. Source-monorepo execution is preserved via a source-repo guard that falls through to `$(dirname "$0")/../scripts/<name>.sh`. The `wr-architect-<kebab-script-name>` naming grammar is unchanged.
