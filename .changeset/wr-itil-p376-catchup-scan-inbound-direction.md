---
"@windyroad/itil": patch
---

catchup-scan: enumerate the inbound direction alongside outbound

The `--catchup` worklist scanner (`packages/itil/scripts/catchup-scan.sh`,
dispatched by the `wr-itil-catchup-scan` PATH shim) previously walked only the
OUTBOUND surface — `.verifying.md` / `.closed.md` tickets carrying a
`## Reported Upstream` section — so the INBOUND catchup candidates (tickets
carrying `**Origin**: inbound-reported (#NN)`, which the P363 rework made
dispatchable) were a manual-discovery surface the maintainer had to hand-grep
(`grep -lE '^\*\*Origin\*\*:\s*inbound-reported'`) after every catchup run —
exactly the toil the catchup mode exists to eliminate.

The scanner now ALSO detects the inbound `**Origin**` field and emits
direction-tagged worklist lines:

    CATCHUP P<NNN> inbound-<ref> state=<state> transition=<…> direction=inbound

with `(inbound)`-tagged-log idempotency (an inbound verdict already recorded in
`## Upstream Lifecycle Updates` is skipped, and an outbound-tagged log entry for
the same target does NOT satisfy the inbound leg). A ticket carrying both
surfaces emits both an outbound and an inbound line (independent legs). Inbound
Origins with no actionable issue number (e.g. `relayed from other projects`)
emit no line, symmetric to the existing no-`## Reported Upstream` silent skip.
Cross-repo refs (`<repo>#NN`) are preserved. The existing outbound line shape
and the `SUMMARY` format are unchanged.

Behavioural bats coverage added in `catchup-scan.bats` (inbound CATCHUP for both
transitions, idempotency, both-surface, cross-repo, non-actionable skip, the
ADR-038 150-byte budget). Closes P376 Gap 1.
