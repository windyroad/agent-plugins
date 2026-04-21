---
"@windyroad/itil": minor
---

P071 split slices 6b + 6c + 6d: new `/wr-itil:restore-incident`, `/wr-itil:close-incident`, and `/wr-itil:link-incident` skills

`/wr-itil:manage-incident <I> restored`, `/wr-itil:manage-incident <I> close`, and `/wr-itil:manage-incident <I> link P<M>` are deprecated; the three remaining incident-lifecycle user intents now have their own skills so the `/` autocomplete surfaces each one directly (JTBD-001 + JTBD-101 + JTBD-201). These are slices 6b + 6c + 6d of the P071 phased-landing plan, bundled in one commit because each mirrors slice 6a (mitigate-incident, commit 248edad) verbatim except for the transition each owns. Bundling amortises cache-warmup + full bats re-run cost across three identical-pattern splits; per-slice separability is preserved via one contract-bats file per skill.

- `packages/itil/skills/restore-incident/SKILL.md` — NEW split skill (slice 6b).
  `allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill`
  — diverges from close-incident + link-incident because restore invokes
  `/wr-itil:manage-problem` via the Skill tool for the problem-handoff
  (ADR-011 Decision Outcome point 4) and uses AskUserQuestion for the
  "create problem / no problem required" branch. Owns the
  `.mitigating.md → .restored.md` rename, the Status field update, the
  "Service restored" Timeline entry, and the `## Linked Problem` or
  `## No Problem` section write. Pre-flight enforces at least one
  recorded mitigation attempt + a captured verification signal per
  ADR-011. Re-invocation on an already-`.restored.md` file is
  idempotent (Case B) — does not re-edit the Status field.
- `packages/itil/skills/restore-incident/test/restore-incident-contract.bats`
  — NEW 12 contract assertions (ADR-037 pattern; @problem P071 + @jtbd
  JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability).
- `packages/itil/skills/close-incident/SKILL.md` — NEW split skill (slice 6c).
  `allowed-tools: Read, Write, Edit, Bash, Glob, Grep` — no
  AskUserQuestion (the linked-problem gate is a hard check with a message,
  not a decisional prompt), no Skill tool (no cross-skill invocation).
  Owns the `.restored.md → .closed.md` rename, the Status field update,
  and the "Incident closed" Timeline entry. Gate accepts linked problems
  in `.known-error.md`, `.verifying.md` (ADR-022 extension), or
  `.closed.md` state; `.open.md` blocks close with a pointer to
  `/wr-itil:transition-problem`. `## No Problem` section bypasses the
  gate. Already-closed invocations short-circuit idempotently.
- `packages/itil/skills/close-incident/test/close-incident-contract.bats`
  — NEW 13 contract assertions (ADR-037 pattern; @problem P071 +
  @jtbd JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability;
  includes the ADR-022 `.verifying.md` gate-allowance regression guard).
- `packages/itil/skills/link-incident/SKILL.md` — NEW split skill (slice 6d).
  `allowed-tools: Read, Write, Edit, Bash, Glob, Grep` — two data
  parameters (incident ID + problem ID) and no decisional prompts.
  Owns the `## Linked Problem` section write / update, including the
  retroactive-link-from-No-Problem conversion (Case C) which also
  appends a `Retroactive link to P<MMM>` Timeline entry so the audit
  trail records the revision.
- `packages/itil/skills/link-incident/test/link-incident-contract.bats`
  — NEW 11 contract assertions (ADR-037 pattern; @problem P071 +
  @jtbd JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability).
- `packages/itil/skills/manage-incident/SKILL.md` — Step 1 parser now
  recognises three additional shapes (`<I###> restored`, `<I###> close`,
  `<I###> link P<MMM>`) and delegates via the Skill tool; emits the
  canonical deprecation systemMessage verbatim for each. Steps 8
  (restore), 9 (close), and 11 (link) reduced to thin-router notes
  pointing at the new skills. `deprecated-arguments: true` already
  pinned from slice 5.
- `packages/itil/skills/manage-incident/test/manage-incident-restore-forwarder.bats`
  — NEW 4 forwarder contract assertions.
- `packages/itil/skills/manage-incident/test/manage-incident-close-forwarder.bats`
  — NEW 4 forwarder contract assertions.
- `packages/itil/skills/manage-incident/test/manage-incident-link-forwarder.bats`
  — NEW 4 forwarder contract assertions.

Deprecation window: until `@windyroad/itil`'s next major version per
ADR-010 amendment.

This completes the `/wr-itil:manage-incident` subcommand split. All five
word-verb subcommands (`list`, `mitigate`, `restored`, `close`, `link`)
are now first-class named skills. `manage-incident` retains two
responsibilities: (1) declare a new incident (no arguments) and (2)
update an existing incident body (`<I###> <details>` — data parameter
only, not a verb subcommand). All five forwarders will be removed
together in `@windyroad/itil`'s next major version.

P071 phased-landing plan status: slices 1 (list-problems), 2
(review-problems), 3 (work-problem singular), 5 (list-incidents), 6a
(mitigate-incident), 6b (restore-incident), 6c (close-incident), and 6d
(link-incident) shipped. Slice 4 (`transition-problem`) shipped in a
prior release. All planned slices are now complete; P071 is eligible
for transition to `.verifying.md` pending user sign-off per ADR-022.
