---
"@windyroad/retrospective": minor
---

ADR-080: `bin/wr-retrospective-*` shims now resolve to the highest-version cached sibling at every invocation (was: dispatch to own scripts/). Closes P343 mid-session staleness — `/install-updates` mid-session no longer requires Claude Code restart for shim resolution to pick up the new version. Source-monorepo execution is preserved via a source-repo guard that falls through to `$(dirname "$0")/../scripts/<name>.sh`. The `wr-retrospective-<kebab-script-name>` naming grammar is unchanged.

Also extends `packages/retrospective/scripts/check-tarball-shipped-shims.sh` perl-regex extractor to recognise both the legacy 3-line ADR-049 shim shape AND the post-ADR-080 wrapper shape, so the tarball-drift detector continues to flag missing `scripts/<name>.sh` targets regardless of which shape any given shim uses.
