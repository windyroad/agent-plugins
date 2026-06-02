---
"@windyroad/itil": patch
---

work-problems Step 5: iter-prompt template pre-resolves persona + JTBD flags when dispatching `/wr-itil:capture-problem` (R007 paired-capability close)

Closes R007 (paired-capability gap on the I12 derive-then-ratify contract introduced in the prior changeset). The `/wr-itil:work-problems` Step 5 iter-prompt's P342 mechanical-stage carve-out authorises retro-surfaced recurring class-of-behaviour observations to auto-ticket via `/wr-itil:capture-problem`, but pre-amendment the iter-prompt did NOT instruct iter subprocesses to pre-resolve persona + JTBD via flags. Under the new I12 contract, every undetectable-from-context capture in an AFK iter would halt-with-stderr-directive — and the iter subprocess's stderr is unobservable to the AFK user, so the halt becomes a silent loop-stall, violating JTBD-006's audit-trail guarantee.

Caller-side wiring only (no new SKILL contract); patch bump.

**Changes**:

- `packages/itil/skills/work-problems/SKILL.md` Step 5 iter-prompt P342 classification taxonomy: "Recurring class-of-behaviour observation" bullet extended with the `Dispatch shape under the I12 derive-then-ratify contract` block. The block codifies the four-step derive-then-dispatch contract iter subprocesses MUST follow when auto-ticketing:
  1. **Persona derivation from iter context** — derive from ticket Origin + RFC trace + story trace; default `developer` on ambiguity (the dominant persona in this monorepo's JTBD corpus). Validate against the persona enum `{developer | tech-lead | plugin-developer | plugin-user}` BEFORE dispatch; on invalid-derivation, fall through to `outstanding_questions`.
  2. **JTBD derivation from iter context** — read iter-prompt content; cite `JTBD-006` for AFK-loop-continuity / iter-dispatch contexts, `JTBD-001` for governance / ADR contexts, `JTBD-101` for plugin-discoverability / suite-extension contexts. Multi-JTBD entries allowed (comma-separated, no spaces).
  3. **Dispatch shape** — `/wr-itil:capture-problem --no-prompt --persona=<derived> --jtbd=<derived-list> "<description>"`. The `--no-prompt` AFK-mode marker suppresses capture-problem's I12 ratification AskUserQuestion fallback inside the iter subprocess; combined with the pre-resolved flags, the derive-success silent-proceed path fires per ADR-044 category 4.
  4. **Genuinely-ambiguous derivation** — do NOT invoke capture-problem (would halt-with-stderr-directive into the iter subprocess's unobservable stderr); instead, queue the observation as an `outstanding_questions` entry with `category: "direction"` for orchestrator main-turn Step 2.5 surfacing.
- The Ambiguous-classification default-to-auto-ticket bullet now reuses the same persona+JTBD derivation contract, with a fall-through to `outstanding_questions` on derive-failure (closes the same halt-vector that the Recurring bullet closes).
- `packages/itil/skills/work-problems/test/work-problems-p342-r007-derive-then-pass-flags.bats`: new positive-control fixture (17 assertions) asserts the iter-prompt template carries the new dispatch contract: `--no-prompt` / `--persona=` / `--jtbd=` flag presence; I12 derive-then-ratify and R007 paired-capability gap citations; persona derivation rule + `developer` default + enum pre-dispatch validation; JTBD derivation rule + JTBD-006/JTBD-001/JTBD-101 mapping citations; `outstanding_questions` fall-through; unobservable-stderr failure-mode framing; preservation of the P342 mechanical-stage carve-out; Ambiguous bullet reuse of the derivation contract.

**Authority cited**:

- ADR-060 Amendment 2026-06-02 — I12 derive-then-ratify contract (the prior changeset's substance).
- ADR-044 — Decision-Delegation Contract: category 4 silent-framework on derive-success; category 1 direction-setting on `outstanding_questions` route.
- ADR-014 — single-commit grain (SKILL + bats + changeset land in one commit).
- JTBD-006 — Progress the Backlog While I'm Away: audit-trail outcome — halt-with-stderr-directive in an iter subprocess is invisible to the AFK user, so the dispatch contract preserves the loop's transparency.

**Architect verdict AMEND 2026-06-02** (one must-fix item closed: persona enum pre-dispatch validation; on invalid-derivation, route to `outstanding_questions` instead of dispatching with a bad value that would halt capture-problem).

**JTBD verdict PASS 2026-06-02** (JTBD-006 audit-trail preservation confirmed; JTBD-301 unaffected — dispatch is maintainer-side iter context, not reporter-side intake; the no-pre-classification firewall stays intact).

**Composes with**:

- The prior changeset (`adr-060-amendment-i12-derive-then-ratify.md`) — closes the "Out of scope this iter" follow-up explicitly named in that changeset's queued-work list ("`/wr-itil:work-problems` capture-on-correction sub-flow caller-side update").
- ADR-013 Rule 5 — policy-authorised silent proceed remains the P342 carve-out's framing; this amendment carries the dispatch contract that lets Rule 5 fire under the new derive-then-ratify regime.
- P342 mechanical-stage carve-out — the additive amendment preserves the original carve-out's authority and adds the dispatch shape required to actually execute it under the new I12 contract.
