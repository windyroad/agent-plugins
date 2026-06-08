---
"@windyroad/itil": minor
---

`/wr-itil:review-problems` now recognises when a downstream report is filed against a version older than one in which the bug was already fixed. Instead of opening a duplicate local problem ticket, the review tool posts an upgrade-pushback comment naming the concrete version the fix shipped in and the closed local ticket that carries the verdict trail, then leaves the report for the reporter to follow up after upgrading.

Example comment body posted on the upstream issue:

> Thanks for the report. This was fixed in `@windyroad/itil@0.20.0` — please upgrade to that version or later. We're tracking the closed local ticket as `P140` if you'd like the verdict trail. If you still see this after upgrading, please file a new report describing what you're seeing on the newer version.

How it works. When an inbound report arrives in the discovery pipeline, the new classifier parses the report's `## Versions` section (the consolidated five-field schema that ships with `/wr-itil:report-upstream` — local plugin, upstream package, Claude CLI, Node, OS), pulls the reporter's local plugin version, then walks the closed problem tickets in `docs/problems/closed/` looking for a semantic match. On a hit, it tries to extract the fix-version from the matched ticket's `## Fix Released` section — looking first for an explicit `@windyroad/<pkg>@X.Y.Z` token, then a `vX.Y.Z` adjacent to "released" / "shipped" / "fixed in", then a commit SHA resolved to its first publishing changeset. If the reporter's version is strictly behind that fix-version, the upgrade-pushback comment fires; no local ticket is opened, because no fresh investigation is needed.

When the version cannot be parsed, or when the fix-version cannot be extracted, the report falls through to the existing pipeline and a local ticket is opened as before — the maintainer rediscovers the duplication during the next ranking refresh. No reports are silently dropped.

Scope. This release ships the **already-fixed-in-newer** branch only. The companion behaviour — detecting that a bug has recurred in a newer release (regression-handling, appending recurrence entries to the matched closed ticket) — is deliberately deferred to a separate iteration. Recurrence candidates encountered during this Phase 1 are flagged on the discovery cache so the next iteration can backfill them.

Persona fit. The comment body names a precise upgrade target (not "the latest") so the reporter has a concrete version to pin to, discloses the matched closed-ticket ID so the verdict trail is reachable from the upstream issue, and preserves a "file a new report" escape hatch so the reporter retains agency if the bug recurs on the newer version. This mirrors the existing duplicate-verdict shape on local-ticket matches, so reporters see consistent acknowledgement language across both branches.

Coverage. 9 new behavioural anchors in `packages/itil/skills/review-problems/test/inbound-discovery-contract.bats` (116/116 review-problems bats green; no regression). New paired evaluator case in `packages/itil/skills/review-problems/eval/promptfooconfig.yaml` asserting the upgrade-pushback comment body in both deterministic and rubric-graded forms — concrete version-anchor naming, matched-ticket disclosure, escape-hatch preservation, and the existing anti-leakage rule (reporter-facing bodies must not carry maintainer-internal framework vocabulary).

Traces: extends the inbound discovery + assessment pipeline contract (ADR-062 step 1, the carve-out already named in that ADR); consumes the consolidated Versions schema (ADR-033 amendment 2026-05-03); rides the external-comms gates (ADR-028 amended); preserves the mechanical-stage carve-out (ADR-044 category 4 — the classifier and verdict comment fire silently; user attention surfaces only at the external-comms gate). Ticket P129 transitions to Known Error; Phase 2 (recurrence) remains carved out.
