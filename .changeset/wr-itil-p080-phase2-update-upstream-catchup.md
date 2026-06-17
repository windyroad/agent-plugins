---
"@windyroad/itil": minor
---

Add a `--catchup` migration mode to `/wr-itil:update-upstream` (P080 Phase 2). The per-ticket lifecycle-update path only fires on transitions that happen after it ships, so any problem ticket reported upstream and transitioned beforehand never received its fix-released or closed comment — leaving upstream issues looking abandoned even though the work landed. `/wr-itil:update-upstream --catchup` walks the existing `.verifying.md` and `.closed.md` corpus, finds tickets carrying a `## Reported Upstream` section, and posts the lifecycle update each one should already carry.

The mode is idempotent: a ticket whose `## Upstream Lifecycle Updates` log already records the current target state is skipped, so re-running is safe. Each catchup comment passes the same external-comms risk and voice-tone gates as the per-ticket path, with the same above-appetite queue-and-continue behaviour — catchup does not bypass the gates. A read-only worklist scanner (`wr-itil-catchup-scan`) builds the list with no network calls, keeping the scan testable and safe to run unattended.
