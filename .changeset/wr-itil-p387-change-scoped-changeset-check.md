---
"@windyroad/itil": patch
---

P387: tighten the changeset-discipline hook's Check 2b from plugin-scoped to change-scoped so plugin-source commits stop shipping undocumented under an unrelated sibling changeset.

`itil-changeset-discipline.sh` Check 2b (in `lib/changeset-detect.sh`) passed a `packages/<plugin>/` source commit whenever ANY in-scope changeset targeted that plugin — even one authored for a different change. A change could therefore ship to npm with no CHANGELOG record of its own, riding a sibling changeset's coattails (witnessed: a Phase 2 octal-eval fix shipped undocumented under an unrelated in-flight changeset, only caught when the missing record was authored retroactively).

Check 2b now compares the committing change's work-item ID(s) — `P<NNN>` / `RFC-<NNN>` / `STORY-<NNN>`, extracted from the `git commit` command string the hook already parses — against each in-scope covering changeset's IDs (its filename and body). It denies only on positive evidence of an unrelated sibling: the commit cites a work-item ID, every covering changeset cites work-item ID(s), and none overlap. Any ambiguity allows — a ticket-less commit, a prose-only changeset, or an overlapping ID. This preserves the ADR-014 batch-grain (multi-commit slices share the slice's ticket, so one changeset still covers the whole slice) and never over-fires on prose-only or adopter changesets that carry no ticket reference. Empty/zero-arg invocation falls back to the prior plugin-scoped behaviour. No deny-message change; per-invocation, no marker (ADR-009). Four behavioural bats added (unrelated-sibling denies; same-ticket allows; ticket-less commit allows; prose-only changeset allows). Refs: P387.
