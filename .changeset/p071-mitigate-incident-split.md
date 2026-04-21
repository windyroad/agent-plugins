---
"@windyroad/itil": minor
---

P071 split slice 6a: new `/wr-itil:mitigate-incident` skill

`/wr-itil:manage-incident <I###> mitigate <action>` is deprecated; the
mitigate-incident user intent now has its own skill so the `/` autocomplete
surfaces it directly (JTBD-001 + JTBD-101 + JTBD-201). This is slice 6a of
the P071 phased-landing plan, mirroring slice 5 (list-incidents) closely
except that mitigate-incident takes the `<I###> <action>` data parameters
— permitted under ADR-010 amended (only word-verb-arguments must be split
out; data parameters like IDs and free-text action strings remain).

- `packages/itil/skills/mitigate-incident/SKILL.md` — NEW split skill.
  `allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion,
  Skill` — diverges from list-incidents's read-only set because mitigation
  renames `.investigating.md → .mitigating.md` on the first attempt and
  appends to the Mitigation attempts timeline. Preserves the ADR-011
  evidence-first gate (≥1 hypothesis with cited evidence) on the first
  mitigation transition, the reversible-mitigation preference
  (rollback → feature flag → restart → route traffic → scale → fix), and
  the Sev 4-5 lightweight path per ADR-011 Step 12 edge case.
- `packages/itil/skills/mitigate-incident/test/mitigate-incident-contract.bats`
  — NEW 13 contract assertions (ADR-037 pattern; @problem P071 + @jtbd
  JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability).
- `packages/itil/skills/manage-incident/SKILL.md` — Step 1 parser now
  recognises the `<I###> mitigate <action>` shape and delegates via the
  Skill tool; emits the canonical deprecation systemMessage verbatim.
  Step 7 reduced to a thin-router note pointing at the new skill (the
  rename + evidence-gate implementation lives in `/wr-itil:mitigate-incident`
  now). `deprecated-arguments: true` already pinned from slice 5.
- `packages/itil/skills/manage-incident/test/manage-incident-mitigate-forwarder.bats`
  — NEW 4 contract assertions for the mitigate forwarder.

Deprecation window: until `@windyroad/itil`'s next major version per
ADR-010 amendment.

Remaining phased-landing slices tracked on P071: `restore-incident`
(slice 6b), `close-incident` (slice 6c), `link-incident` (slice 6d) —
the remaining manage-incident splits.
