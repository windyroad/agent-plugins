---
"@windyroad/itil": minor
---

`/wr-itil:report-upstream` now emits a labelled `## Versions` section (replacing the freeform `## Environment` block) carrying a fixed five-field schema: Local plugin, Upstream package, Claude Code CLI, Node, OS. Missing fields render as `not detected` (normative MUST), so upstream maintainers can distinguish *field omitted because not applicable* from *detection failed*. Mirrored in this repo's `.github/ISSUE_TEMPLATE/problem-report.yml` and the `scaffold-intake` template (downstream-scaffolded intakes per ADR-036) so inbound and outbound shapes match.

Driver: P128 (`/wr-itil:report-upstream` report body lacks consolidated Versions section). Authority: ADR-033 amendment 2026-05-03; forward-pointer added to ADR-024's `## Amendments`. Composes-with: P129 (companion inbound version-aware classification — depends on this schema being stable).
