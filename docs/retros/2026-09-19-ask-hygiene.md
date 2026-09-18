# Ask Hygiene — 2026-09-19 (P509 iteration)

Retro surface: `/wr-retrospective:run-retro` Step 2d, invoked from the P509 AFK iteration.

No `AskUserQuestion` calls were made this session. The run was unattended under an explicit
never-ask constraint, so the count is a floor rather than a signal about judgement — the
iteration constraints removed the surface rather than the agent declining to use it.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | (none) | — | Iteration constraint `iter-509.md` line 3: "NEVER call AskUserQuestion. The user is absent." |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Decisions routed away from an ask

Two decisions that would otherwise have been direction-setting asks were instead resolved and
queued, per the constraint's instruction to route them to `outstanding_questions`:

- The recorded decision was born `human-oversight: unconfirmed` rather than confirmed. No
  substance-confirm event happened, so a confirmed marker would have been hollow (ADR-110 / P348).
- One embedded design choice inside that decision — whether a row that asks for the pre-RFC
  marker and does not qualify is demoted to an ordinary row or refused outright at capture — was
  resolved by the agent on corpus-consistency grounds (ADR-107 weighed a render-time hard stop
  and rejected it as premature) and queued for the ratification drain rather than asked.

Both are `direction` shaped, not `lazy`: the framework does not resolve either, and both are
about to be built on. Under an interactive run they would have fired an ADR-074
substance-confirm ask and counted as category-1 direction.
