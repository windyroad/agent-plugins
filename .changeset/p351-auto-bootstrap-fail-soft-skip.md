---
"@windyroad/itil": patch
---

P351 fold-fix — `/wr-itil:review-problems` Step 4.5a auto-bootstraps on missing
`.upstream-channels.json` instead of silently skipping the inbound-discovery
pass. Interactive mode prompts for channel-type + per-channel coordinates
(single batched `AskUserQuestion` ≤4 questions per ADR-013 Rule 1), previews
the planned JSON before writing (don't surprise the adopter with a silent
config write), writes the config, resumes the original pass. AFK mode queues
a `direction` outstanding_question per `/wr-itil:work-problems` Step 5 schema
(ADR-044 category 1) so loop-end Step 2.5 surfaces it as batched
`AskUserQuestion`; the iter continues other passes for THIS run.
Decline-permanently surface writes an empty-channels stub so adopters who
never want inbound-discovery keep zero ceremony tax per ADR-062 §
Downstream-adopter non-obligation. Malformed-JSON branch preserved as genuine
fail-soft (the adopter shipped a config; auto-rewriting would destroy their
work).

Ships a structural lint at `wr-itil-check-fail-soft-skip-discipline` (Phase 1
advisory; promoted to load-bearing via `WR_FAIL_SOFT_SKIP_WARN_ONLY=0` once
sibling SKILL.md surfaces have been migrated) that flags any other
`fail-soft skip` / `silently skip` / `skipping.*config` /
`skipping.*not configured` / `not configured.*skip` prose across
`packages/*/skills/*/SKILL.md`. Wired into CI as a `continue-on-error`
advisory step.

Trace: RFC-017 (thin retro-fit per ADR-071 unconditional RFC-first; no
independent architectural decisions, architect-resolved on prior review).

Closes P351 once this changeset releases.
